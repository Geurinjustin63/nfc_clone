import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/nfc_card.dart';
import '../models/card_balance.dart';
import '../models/card_transaction.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Stream controllers for real-time updates
  final StreamController<List<CardBalance>> _balancesController = 
      StreamController<List<CardBalance>>.broadcast();
  final StreamController<List<CardTransaction>> _transactionsController = 
      StreamController<List<CardTransaction>>.broadcast();

  // Cache for performance
  final Map<String, CardBalance> _balanceCache = {};
  final Map<String, List<CardTransaction>> _transactionCache = {};

  // Getters for streams
  Stream<List<CardBalance>> get balancesStream => _balancesController.stream;
  Stream<List<CardTransaction>> get transactionsStream => _transactionsController.stream;

  /// Initialize the balance service
  Future<void> initialize() async {
    try {
      await _createBalanceTables();
      await _loadBalanceCache();
      debugPrint('✅ BalanceService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize BalanceService: $e');
    }
  }

  /// Create balance-related database tables
  Future<void> _createBalanceTables() async {
    final db = await _databaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS card_balances(
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        current_balance REAL NOT NULL,
        previous_balance REAL,
        currency TEXT NOT NULL DEFAULT 'USD',
        balance_type INTEGER NOT NULL,
        last_updated TEXT NOT NULL,
        last_transaction_id TEXT,
        is_encrypted INTEGER DEFAULT 0,
        raw_balance_data TEXT,
        confidence_level REAL DEFAULT 1.0,
        balance_source TEXT,
        FOREIGN KEY(card_id) REFERENCES cards(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS card_transactions(
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        transaction_type INTEGER NOT NULL,
        amount REAL NOT NULL,
        balance_before REAL,
        balance_after REAL,
        timestamp TEXT NOT NULL,
        description TEXT,
        location TEXT,
        merchant_info TEXT,
        transaction_id TEXT,
        is_estimated INTEGER DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD',
        metadata TEXT,
        source TEXT,
        FOREIGN KEY(card_id) REFERENCES cards(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS balance_parsing_rules(
        id TEXT PRIMARY KEY,
        card_type TEXT NOT NULL,
        card_subtype TEXT,
        balance_location TEXT NOT NULL,
        parsing_algorithm TEXT NOT NULL,
        currency_code TEXT,
        decimal_places INTEGER DEFAULT 2,
        byte_order TEXT DEFAULT 'little_endian',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      );
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_balances_card_id ON card_balances(card_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_card_id ON card_transactions(card_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON card_transactions(timestamp);');
  }

  /// Load balance cache from database
  Future<void> _loadBalanceCache() async {
    try {
      final balances = await getAllBalances();
      _balanceCache.clear();
      for (final balance in balances) {
        _balanceCache[balance.cardId] = balance;
      }
      
      _balancesController.add(balances);
    } catch (e) {
      debugPrint('Failed to load balance cache: $e');
    }
  }

  /// Extract balance from NFC card data
  Future<CardBalance?> extractBalanceFromCard(NFCCard card) async {
    try {
      // Detect balance type based on card type and data
      final balanceType = _detectBalanceType(card);
      if (balanceType == BalanceType.unknown) {
        debugPrint('No balance support detected for card: ${card.name}');
        return null;
      }

      // Detect currency based on card data and location
      final currency = _detectCurrency(card);

      // Create balance from NFC data
      final balance = CardBalance.fromNFCData(
        cardId: card.id,
        nfcData: card.rawData,
        balanceType: balanceType,
        currency: currency,
      );

      // Only save if balance is reasonable (> 0 and confidence > 0.3)
      if (balance.currentBalance > 0 && balance.confidenceLevel > 0.3) {
        await saveBalance(balance);
        return balance;
      } else {
        debugPrint('Balance extraction failed or unreliable for card: ${card.name}');
        return null;
      }
    } catch (e) {
      debugPrint('Error extracting balance from card ${card.name}: $e');
      return null;
    }
  }

  /// Detect balance type based on card characteristics
  BalanceType _detectBalanceType(NFCCard card) {
    // Check card name and description for clues
    final cardInfo = '${card.name} ${card.description ?? ''}'.toLowerCase();
    
    if (cardInfo.contains('transit') || 
        cardInfo.contains('metro') || 
        cardInfo.contains('bus') ||
        cardInfo.contains('train') ||
        cardInfo.contains('subway')) {
      return BalanceType.transit;
    }
    
    if (cardInfo.contains('gift') || cardInfo.contains('store')) {
      return BalanceType.gift;
    }
    
    if (cardInfo.contains('loyalty') || 
        cardInfo.contains('reward') || 
        cardInfo.contains('points')) {
      return BalanceType.loyalty;
    }
    
    if (cardInfo.contains('parking')) {
      return BalanceType.parking;
    }
    
    if (cardInfo.contains('campus') || 
        cardInfo.contains('student') || 
        cardInfo.contains('university')) {
      return BalanceType.campus;
    }
    
    if (cardInfo.contains('healthcare') || 
        cardInfo.contains('medical') || 
        cardInfo.contains('hospital')) {
      return BalanceType.healthcare;
    }
    
    if (cardInfo.contains('prepaid')) {
      return BalanceType.prepaid;
    }

    // Check card type for common patterns
    switch (card.type) {
      case CardType.mifareClassic:
      case CardType.mifareUltralight:
        // MIFARE cards often used for transit
        return BalanceType.transit;
      case CardType.desfire:
        // DESFire often used for payment/campus
        return BalanceType.payment;
      default:
        break;
    }

    // Check if card has balance-like data
    if (_hasBalanceData(card.rawData)) {
      return BalanceType.prepaid; // Default for cards with balance data
    }

    return BalanceType.unknown;
  }

  /// Detect currency based on card data and regional settings
  CurrencyType _detectCurrency(NFCCard card) {
    final cardInfo = '${card.name} ${card.description ?? ''}'.toLowerCase();
    
    // Check for explicit currency mentions
    if (cardInfo.contains('usd') || cardInfo.contains('dollar')) {
      return CurrencyType.usd;
    }
    if (cardInfo.contains('eur') || cardInfo.contains('euro')) {
      return CurrencyType.eur;
    }
    if (cardInfo.contains('gbp') || cardInfo.contains('pound')) {
      return CurrencyType.gbp;
    }
    if (cardInfo.contains('jpy') || cardInfo.contains('yen')) {
      return CurrencyType.jpy;
    }
    if (cardInfo.contains('krw') || cardInfo.contains('won')) {
      return CurrencyType.krw;
    }
    if (cardInfo.contains('cny') || cardInfo.contains('yuan')) {
      return CurrencyType.cny;
    }
    if (cardInfo.contains('point') || cardInfo.contains('pts')) {
      return CurrencyType.points;
    }
    if (cardInfo.contains('credit')) {
      return CurrencyType.credits;
    }
    
    // Default to USD
    return CurrencyType.usd;
  }

  /// Check if card data contains balance-like patterns
  bool _hasBalanceData(Map<String, dynamic> rawData) {
    final dataString = rawData.toString().toLowerCase();
    
    // Look for balance-related keywords
    if (dataString.contains('balance') || 
        dataString.contains('value') || 
        dataString.contains('amount') ||
        dataString.contains('credit')) {
      return true;
    }
    
    // Look for structured data that might contain balances
    if (rawData.containsKey('mifare_classic')) {
      final mifareData = rawData['mifare_classic'] as Map<String, dynamic>?;
      if (mifareData?.containsKey('sectors') == true) {
        return true; // MIFARE Classic with sectors likely has balance data
      }
    }
    
    if (rawData.containsKey('mifare_ultralight')) {
      final ultralightData = rawData['mifare_ultralight'] as Map<String, dynamic>?;
      if (ultralightData?.containsKey('pages') == true) {
        return true; // MIFARE Ultralight with pages might have balance data
      }
    }
    
    return false;
  }

  /// Save or update card balance
  Future<void> saveBalance(CardBalance balance) async {
    try {
      final db = await _databaseService.database;
      
      // Check if balance already exists
      final existing = await getBalanceForCard(balance.cardId);
      
      if (existing != null) {
        // Update existing balance, keeping previous balance
        final updatedBalance = balance.copyWith(
          previousBalance: existing.currentBalance,
        );
        
        await db.update(
          'card_balances',
          updatedBalance.toMap(),
          where: 'card_id = ?',
          whereArgs: [balance.cardId],
        );
        
        _balanceCache[balance.cardId] = updatedBalance;
        
        // Create transaction if balance changed
        if (existing.currentBalance != updatedBalance.currentBalance) {
          final transaction = CardTransaction.fromBalanceChange(
            cardId: balance.cardId,
            previousBalance: existing,
            currentBalance: updatedBalance,
          );
          await saveTransaction(transaction);
        }
      } else {
        // Insert new balance
        await db.insert('card_balances', balance.toMap());
        _balanceCache[balance.cardId] = balance;
      }
      
      // Update streams
      final allBalances = await getAllBalances();
      _balancesController.add(allBalances);
      
      debugPrint('✅ Balance saved for card: ${balance.cardId}');
    } catch (e) {
      debugPrint('❌ Failed to save balance: $e');
      rethrow;
    }
  }

  /// Get balance for specific card
  Future<CardBalance?> getBalanceForCard(String cardId) async {
    try {
      // Check cache first
      if (_balanceCache.containsKey(cardId)) {
        return _balanceCache[cardId];
      }
      
      final db = await _databaseService.database;
      final results = await db.query(
        'card_balances',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      
      if (results.isNotEmpty) {
        final balance = CardBalance.fromMap(results.first);
        _balanceCache[cardId] = balance;
        return balance;
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get balance for card $cardId: $e');
      return null;
    }
  }

  /// Get all card balances
  Future<List<CardBalance>> getAllBalances() async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'card_balances',
        orderBy: 'last_updated DESC',
      );
      
      return results.map((map) => CardBalance.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get all balances: $e');
      return [];
    }
  }

  /// Save transaction
  Future<void> saveTransaction(CardTransaction transaction) async {
    try {
      final db = await _databaseService.database;
      await db.insert('card_transactions', transaction.toMap());
      
      // Update cache
      if (!_transactionCache.containsKey(transaction.cardId)) {
        _transactionCache[transaction.cardId] = [];
      }
      _transactionCache[transaction.cardId]!.add(transaction);
      
      // Update stream
      final allTransactions = await getAllTransactions();
      _transactionsController.add(allTransactions);
      
      debugPrint('✅ Transaction saved: ${transaction.formattedAmount}');
    } catch (e) {
      debugPrint('❌ Failed to save transaction: $e');
      rethrow;
    }
  }

  /// Get transactions for specific card
  Future<List<CardTransaction>> getTransactionsForCard(
    String cardId, {
    int? limit,
    DateTime? since,
  }) async {
    try {
      final db = await _databaseService.database;
      
      String whereClause = 'card_id = ?';
      List<dynamic> whereArgs = [cardId];
      
      if (since != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(since.toIso8601String());
      }
      
      final results = await db.query(
        'card_transactions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      
      return results.map((map) => CardTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get transactions for card $cardId: $e');
      return [];
    }
  }

  /// Get all transactions
  Future<List<CardTransaction>> getAllTransactions({
    int? limit,
    DateTime? since,
  }) async {
    try {
      final db = await _databaseService.database;
      
      String? whereClause;
      List<dynamic>? whereArgs;
      
      if (since != null) {
        whereClause = 'timestamp >= ?';
        whereArgs = [since.toIso8601String()];
      }
      
      final results = await db.query(
        'card_transactions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      
      return results.map((map) => CardTransaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get all transactions: $e');
      return [];
    }
  }

  /// Get balance statistics
  Future<Map<String, dynamic>> getBalanceStatistics() async {
    try {
      final balances = await getAllBalances();
      final transactions = await getAllTransactions();
      
      if (balances.isEmpty) {
        return {
          'total_balance': 0.0,
          'total_cards_with_balance': 0,
          'average_balance': 0.0,
          'total_transactions': 0,
          'total_spent_this_month': 0.0,
          'total_added_this_month': 0.0,
        };
      }
      
      // Calculate total balance (convert to USD for simplicity)
      double totalBalance = 0.0;
      for (final balance in balances) {
        totalBalance += balance.currentBalance; // Simplified - should convert currencies
      }
      
      // Calculate monthly transactions
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthlyTransactions = transactions.where(
        (t) => t.timestamp.isAfter(monthStart),
      ).toList();
      
      double monthlySpent = 0.0;
      double monthlyAdded = 0.0;
      
      for (final transaction in monthlyTransactions) {
        if (transaction.isDebit) {
          monthlySpent += transaction.amount;
        } else if (transaction.isCredit) {
          monthlyAdded += transaction.amount;
        }
      }
      
      return {
        'total_balance': totalBalance,
        'total_cards_with_balance': balances.length,
        'average_balance': totalBalance / balances.length,
        'total_transactions': transactions.length,
        'monthly_transactions': monthlyTransactions.length,
        'total_spent_this_month': monthlySpent,
        'total_added_this_month': monthlyAdded,
        'net_change_this_month': monthlyAdded - monthlySpent,
      };
    } catch (e) {
      debugPrint('Failed to get balance statistics: $e');
      return {};
    }
  }

  /// Delete balance for card
  Future<void> deleteBalanceForCard(String cardId) async {
    try {
      final db = await _databaseService.database;
      
      await db.delete(
        'card_balances',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      
      await db.delete(
        'card_transactions',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      
      _balanceCache.remove(cardId);
      _transactionCache.remove(cardId);
      
      // Update streams
      final allBalances = await getAllBalances();
      final allTransactions = await getAllTransactions();
      _balancesController.add(allBalances);
      _transactionsController.add(allTransactions);
      
      debugPrint('✅ Balance and transactions deleted for card: $cardId');
    } catch (e) {
      debugPrint('❌ Failed to delete balance for card $cardId: $e');
      rethrow;
    }
  }

  /// Export balance data
  Future<Map<String, dynamic>> exportBalanceData({
    List<String>? cardIds,
    DateTime? since,
  }) async {
    try {
      List<CardBalance> balances;
      List<CardTransaction> transactions;
      
      if (cardIds != null) {
        balances = [];
        transactions = [];
        
        for (final cardId in cardIds) {
          final balance = await getBalanceForCard(cardId);
          if (balance != null) balances.add(balance);
          
          final cardTransactions = await getTransactionsForCard(cardId, since: since);
          transactions.addAll(cardTransactions);
        }
      } else {
        balances = await getAllBalances();
        transactions = await getAllTransactions(since: since);
      }
      
      return {
        'exported_at': DateTime.now().toIso8601String(),
        'export_type': 'balance_data',
        'balances': balances.map((b) => b.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'statistics': await getBalanceStatistics(),
      };
    } catch (e) {
      debugPrint('Failed to export balance data: $e');
      rethrow;
    }
  }

  /// Clean up old transactions (keep last 1000 per card)
  Future<void> cleanupOldTransactions({int keepCount = 1000}) async {
    try {
      final db = await _databaseService.database;
      
      // Get all card IDs with transactions
      final cardIds = await db.rawQuery('''
        SELECT DISTINCT card_id FROM card_transactions
      ''');
      
      for (final row in cardIds) {
        final cardId = row['card_id'] as String;
        
        // Delete old transactions for this card
        await db.rawDelete('''
          DELETE FROM card_transactions 
          WHERE card_id = ? AND id NOT IN (
            SELECT id FROM card_transactions 
            WHERE card_id = ? 
            ORDER BY timestamp DESC 
            LIMIT ?
          )
        ''', [cardId, cardId, keepCount]);
      }
      
      // Clear cache to force reload
      _transactionCache.clear();
      
      debugPrint('✅ Old transactions cleaned up');
    } catch (e) {
      debugPrint('❌ Failed to cleanup old transactions: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _balancesController.close();
    _transactionsController.close();
    _balanceCache.clear();
    _transactionCache.clear();
  }
}