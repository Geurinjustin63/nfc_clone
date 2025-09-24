import 'package:flutter/foundation.dart';
import 'package:decimal/decimal.dart';
import '../../../core/models/nfc_card.dart';
import '../models/card_balance.dart';
import '../models/transaction.dart';
import '../services/balance_reader_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/secure_storage_service.dart';

class BalanceProvider extends ChangeNotifier {
  final BalanceReaderService _balanceReader = BalanceReaderService();
  final DatabaseService _databaseService = DatabaseService();
  final SecureStorageService _secureStorage = SecureStorageService();

  // State
  Map<String, CardBalance> _cardBalances = {};
  Map<String, List<Transaction>> _cardTransactions = {};
  List<Transaction> _recentTransactions = [];
  
  // Loading states
  bool _isLoadingBalances = false;
  bool _isRefreshing = false;
  Map<String, bool> _cardRefreshStates = {};
  String? _error;
  
  // Settings
  Currency _primaryCurrency = Currency.usd;
  bool _autoRefreshEnabled = true;
  Duration _autoRefreshInterval = const Duration(minutes: 30);
  bool _lowBalanceNotificationsEnabled = true;
  
  // Statistics
  DateTime? _lastUpdateTime;
  int _successfulReads = 0;
  int _failedReads = 0;

  // Getters
  Map<String, CardBalance> get cardBalances => Map.unmodifiable(_cardBalances);
  List<Transaction> get recentTransactions => List.unmodifiable(_recentTransactions);
  bool get isLoadingBalances => _isLoadingBalances;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  Currency get primaryCurrency => _primaryCurrency;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  int get successfulReads => _successfulReads;
  int get failedReads => _failedReads;
  double get readSuccessRate => (_successfulReads + _failedReads) == 0 ? 0.0 : _successfulReads / (_successfulReads + _failedReads);

  // Computed properties
  Decimal get totalBalance {
    Decimal total = Decimal.zero;
    for (final balance in _cardBalances.values) {
      if (balance.currency == _primaryCurrency) {
        total += balance.amount;
      } else {
        // Convert to primary currency (simplified - would use real exchange rates)
        total += _convertCurrency(balance.amount, balance.currency, _primaryCurrency);
      }
    }
    return total;
  }

  String get formattedTotalBalance {
    final symbol = CardBalance.getCurrencySymbol(_primaryCurrency);
    return '$symbol${totalBalance.toStringAsFixed(2)}';
  }

  Decimal get todaySpending {
    final today = DateTime.now();
    final todayTransactions = _recentTransactions.where((t) =>
        t.timestamp.year == today.year &&
        t.timestamp.month == today.month &&
        t.timestamp.day == today.day &&
        t.type == TransactionType.debit
    );
    
    return todayTransactions.fold<Decimal>(
      Decimal.zero,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  Decimal get weekSpending {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekTransactions = _recentTransactions.where((t) =>
        t.timestamp.isAfter(weekStart) &&
        t.type == TransactionType.debit
    );
    
    return weekTransactions.fold<Decimal>(
      Decimal.zero,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  Decimal get monthSpending {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = _recentTransactions.where((t) =>
        t.timestamp.isAfter(monthStart) &&
        t.type == TransactionType.debit
    );
    
    return monthTransactions.fold<Decimal>(
      Decimal.zero,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  List<NFCCard> get cardsWithBalance {
    // This would be provided by CardsProvider
    return [];
  }

  Future<void> initialize() async {
    await _loadSettings();
    await _loadCachedBalances();
    await _loadRecentTransactions();
    
    if (_autoRefreshEnabled) {
      _startAutoRefresh();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final currencyIndex = _secureStorage.getSetting<int>('primary_currency', defaultValue: 0);
      _primaryCurrency = Currency.values[currencyIndex ?? 0];
      
      _autoRefreshEnabled = _secureStorage.getSetting<bool>('auto_refresh_enabled', defaultValue: true) ?? true;
      
      final intervalMinutes = _secureStorage.getSetting<int>('auto_refresh_interval', defaultValue: 30);
      _autoRefreshInterval = Duration(minutes: intervalMinutes ?? 30);
      
      _lowBalanceNotificationsEnabled = _secureStorage.getSetting<bool>('low_balance_notifications', defaultValue: true) ?? true;
    } catch (e) {
      print('Error loading balance settings: $e');
    }
  }

  Future<void> _loadCachedBalances() async {
    try {
      _setLoadingBalances(true);
      
      // Load balances from database
      // This would require extending DatabaseService with balance operations
      // For now, using secure storage as a simplified cache
      
      final cachedBalances = await _secureStorage.getSecureJson('cached_balances');
      if (cachedBalances != null) {
        final balances = cachedBalances['balances'] as List<dynamic>?;
        if (balances != null) {
          for (final balanceData in balances) {
            final balance = CardBalance.fromMap(balanceData as Map<String, dynamic>);
            _cardBalances[balance.cardId] = balance;
          }
        }
        
        final lastUpdate = cachedBalances['last_update'] as String?;
        if (lastUpdate != null) {
          _lastUpdateTime = DateTime.parse(lastUpdate);
        }
      }
    } catch (e) {
      _setError('Failed to load cached balances: $e');
    } finally {
      _setLoadingBalances(false);
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final cachedTransactions = await _secureStorage.getSecureJson('recent_transactions');
      if (cachedTransactions != null) {
        final transactions = cachedTransactions['transactions'] as List<dynamic>?;
        if (transactions != null) {
          _recentTransactions = transactions
              .map((t) => Transaction.fromMap(t as Map<String, dynamic>))
              .toList();
          
          // Sort by timestamp (newest first)
          _recentTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      }
    } catch (e) {
      print('Error loading recent transactions: $e');
    }
  }

  Future<CardBalance?> readCardBalance(NFCCard card) async {
    try {
      _setCardRefreshing(card.id, true);
      
      final balance = await _balanceReader.readBalance(card);
      
      if (balance != null) {
        _cardBalances[card.id] = balance;
        _successfulReads++;
        await _cacheBalances();
        
        // Check for low balance and notify if needed
        if (balance.isLowBalance && _lowBalanceNotificationsEnabled) {
          await _showLowBalanceNotification(card, balance);
        }
      } else {
        _failedReads++;
      }
      
      _lastUpdateTime = DateTime.now();
      notifyListeners();
      return balance;
    } catch (e) {
      _failedReads++;
      _setError('Failed to read balance for ${card.name}: $e');
      return null;
    } finally {
      _setCardRefreshing(card.id, false);
    }
  }

  Future<List<Transaction>> readCardTransactions(NFCCard card) async {
    try {
      final transactions = await _balanceReader.readTransactionHistory(card);
      
      if (transactions.isNotEmpty) {
        _cardTransactions[card.id] = transactions;
        
        // Add to recent transactions
        _recentTransactions.addAll(transactions);
        _recentTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Keep only the most recent 100 transactions
        if (_recentTransactions.length > 100) {
          _recentTransactions = _recentTransactions.take(100).toList();
        }
        
        await _cacheTransactions();
      }
      
      notifyListeners();
      return transactions;
    } catch (e) {
      print('Error reading transactions for ${card.name}: $e');
      return [];
    }
  }

  Future<void> refreshAllBalances(List<NFCCard> cards) async {
    _setRefreshing(true);
    _setError(null);
    
    try {
      final futures = cards.map((card) => readCardBalance(card)).toList();
      await Future.wait(futures);
    } catch (e) {
      _setError('Failed to refresh balances: $e');
    } finally {
      _setRefreshing(false);
    }
  }

  Future<void> refreshCardBalance(String cardId, NFCCard card) async {
    await readCardBalance(card);
  }

  CardBalance? getCardBalance(String cardId) {
    return _cardBalances[cardId];
  }

  List<Transaction> getCardTransactions(String cardId) {
    return _cardTransactions[cardId] ?? [];
  }

  List<Transaction> getTransactionsByCategory(TransactionCategory category) {
    return _recentTransactions.where((t) => t.category == category).toList();
  }

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _recentTransactions.where((t) =>
        t.timestamp.isAfter(start) && t.timestamp.isBefore(end)
    ).toList();
  }

  Future<void> setPrimaryCurrency(Currency currency) async {
    if (_primaryCurrency != currency) {
      _primaryCurrency = currency;
      await _secureStorage.setSetting('primary_currency', currency.index);
      notifyListeners();
    }
  }

  Future<void> setAutoRefreshEnabled(bool enabled) async {
    if (_autoRefreshEnabled != enabled) {
      _autoRefreshEnabled = enabled;
      await _secureStorage.setSetting('auto_refresh_enabled', enabled);
      
      if (enabled) {
        _startAutoRefresh();
      } else {
        _stopAutoRefresh();
      }
      
      notifyListeners();
    }
  }

  Future<void> setAutoRefreshInterval(Duration interval) async {
    if (_autoRefreshInterval != interval) {
      _autoRefreshInterval = interval;
      await _secureStorage.setSetting('auto_refresh_interval', interval.inMinutes);
      
      if (_autoRefreshEnabled) {
        _stopAutoRefresh();
        _startAutoRefresh();
      }
      
      notifyListeners();
    }
  }

  Future<void> setLowBalanceNotificationsEnabled(bool enabled) async {
    if (_lowBalanceNotificationsEnabled != enabled) {
      _lowBalanceNotificationsEnabled = enabled;
      await _secureStorage.setSetting('low_balance_notifications', enabled);
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    // Implement auto-refresh timer
    Timer.periodic(_autoRefreshInterval, (timer) async {
      if (!_autoRefreshEnabled) {
        timer.cancel();
        return;
      }
      
      // Auto-refresh cards that need updating
      final cardsNeedingRefresh = _cardBalances.values
          .where((balance) => balance.needsRefresh)
          .toList();
      
      if (cardsNeedingRefresh.isNotEmpty) {
        // Would need access to cards list to refresh
        print('Auto-refresh: ${cardsNeedingRefresh.length} cards need updating');
      }
    });
  }

  void _stopAutoRefresh() {
    // Timer would be stored as instance variable to cancel
  }

  Future<void> _cacheBalances() async {
    try {
      final cacheData = {
        'balances': _cardBalances.values.map((b) => b.toMap()).toList(),
        'last_update': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.storeSecureJson('cached_balances', cacheData);
    } catch (e) {
      print('Error caching balances: $e');
    }
  }

  Future<void> _cacheTransactions() async {
    try {
      final cacheData = {
        'transactions': _recentTransactions.map((t) => t.toMap()).toList(),
        'last_update': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.storeSecureJson('recent_transactions', cacheData);
    } catch (e) {
      print('Error caching transactions: $e');
    }
  }

  Future<void> _showLowBalanceNotification(NFCCard card, CardBalance balance) async {
    // This would integrate with a notification service
    print('Low balance notification: ${card.name} has ${balance.formattedAmount}');
  }

  Decimal _convertCurrency(Decimal amount, Currency from, Currency to) {
    // Simplified currency conversion - in production, use real exchange rates
    if (from == to) return amount;
    
    // Mock conversion rates
    final rates = {
      Currency.usd: 1.0,
      Currency.eur: 0.85,
      Currency.gbp: 0.73,
      Currency.jpy: 110.0,
      Currency.cad: 1.25,
      Currency.aud: 1.35,
    };
    
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    final conversionRate = Decimal.parse((toRate / fromRate).toString());
    
    return amount * conversionRate;
  }

  // Analytics methods
  Map<TransactionCategory, Decimal> getCategorySpending({
    Duration? period,
  }) {
    final now = DateTime.now();
    final cutoff = period != null ? now.subtract(period) : null;
    
    final relevantTransactions = _recentTransactions.where((t) =>
        t.type == TransactionType.debit &&
        (cutoff == null || t.timestamp.isAfter(cutoff))
    );
    
    final categoryTotals = <TransactionCategory, Decimal>{};
    
    for (final transaction in relevantTransactions) {
      final category = transaction.category ?? TransactionCategory.other;
      categoryTotals[category] = (categoryTotals[category] ?? Decimal.zero) + transaction.amount;
    }
    
    return categoryTotals;
  }

  List<Transaction> getTopMerchants({int limit = 5}) {
    final merchantTotals = <String, Decimal>{};
    final merchantTransactions = <String, Transaction>{};
    
    for (final transaction in _recentTransactions) {
      if (transaction.merchantName != null && transaction.type == TransactionType.debit) {
        final merchant = transaction.merchantName!;
        merchantTotals[merchant] = (merchantTotals[merchant] ?? Decimal.zero) + transaction.amount;
        merchantTransactions[merchant] = transaction;
      }
    }
    
    final sortedMerchants = merchantTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMerchants
        .take(limit)
        .map((entry) => merchantTransactions[entry.key]!)
        .toList();
  }

  List<CardBalance> getLowBalanceCards() {
    return _cardBalances.values.where((balance) => balance.isLowBalance).toList();
  }

  List<CardBalance> getExpiredCards() {
    return _cardBalances.values.where((balance) => balance.isExpired).toList();
  }

  Map<String, int> getMonthlyTransactionCounts() {
    final monthlyCounts = <String, int>{};
    
    for (final transaction in _recentTransactions) {
      final monthKey = '${transaction.timestamp.year}-${transaction.timestamp.month.toString().padLeft(2, '0')}';
      monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
    }
    
    return monthlyCounts;
  }

  // Export functionality
  Future<Map<String, dynamic>> exportBalanceData({
    List<String>? cardIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final exportData = <String, dynamic>{};
    
    // Filter balances
    final balancesToExport = cardIds != null
        ? _cardBalances.entries.where((entry) => cardIds.contains(entry.key))
        : _cardBalances.entries;
    
    exportData['balances'] = balancesToExport
        .map((entry) => entry.value.toJson())
        .toList();
    
    // Filter transactions
    var transactionsToExport = _recentTransactions.asMap().entries.where((entry) {
      final transaction = entry.value;
      
      if (cardIds != null && !cardIds.contains(transaction.cardId)) {
        return false;
      }
      
      if (startDate != null && transaction.timestamp.isBefore(startDate)) {
        return false;
      }
      
      if (endDate != null && transaction.timestamp.isAfter(endDate)) {
        return false;
      }
      
      return true;
    });
    
    exportData['transactions'] = transactionsToExport
        .map((entry) => entry.value.toJson())
        .toList();
    
    exportData['metadata'] = {
      'exported_at': DateTime.now().toIso8601String(),
      'primary_currency': _primaryCurrency.name,
      'total_balance': totalBalance.toString(),
      'export_range': {
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      },
    };
    
    return exportData;
  }

  // State management helpers
  void _setLoadingBalances(bool loading) {
    if (_isLoadingBalances != loading) {
      _isLoadingBalances = loading;
      notifyListeners();
    }
  }

  void _setRefreshing(bool refreshing) {
    if (_isRefreshing != refreshing) {
      _isRefreshing = refreshing;
      notifyListeners();
    }
  }

  void _setCardRefreshing(String cardId, bool refreshing) {
    final wasRefreshing = _cardRefreshStates[cardId] ?? false;
    if (wasRefreshing != refreshing) {
      _cardRefreshStates[cardId] = refreshing;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  bool isCardRefreshing(String cardId) {
    return _cardRefreshStates[cardId] ?? false;
  }

  void clearError() {
    _setError(null);
  }

  void resetStatistics() {
    _successfulReads = 0;
    _failedReads = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}