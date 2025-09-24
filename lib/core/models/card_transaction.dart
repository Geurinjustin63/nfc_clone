import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'card_balance.dart';

class CardTransaction {
  final String id;
  final String cardId;
  final TransactionType type;
  final double amount;
  final double? balanceBefore;
  final double? balanceAfter;
  final DateTime timestamp;
  final String? description;
  final String? location;
  final String? merchantInfo;
  final String? transactionId; // From card data
  final bool isEstimated;
  final CurrencyType currency;
  final Map<String, dynamic>? metadata;
  final String? source; // Where transaction was detected

  CardTransaction({
    String? id,
    required this.cardId,
    required this.type,
    required this.amount,
    this.balanceBefore,
    this.balanceAfter,
    DateTime? timestamp,
    this.description,
    this.location,
    this.merchantInfo,
    this.transactionId,
    this.isEstimated = false,
    this.currency = CurrencyType.usd,
    this.metadata,
    this.source,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  // Factory constructor from NFC transaction data
  factory CardTransaction.fromNFCData({
    required String cardId,
    required Map<String, dynamic> transactionData,
    required CurrencyType currency,
  }) {
    final type = _parseTransactionType(transactionData);
    final amount = _parseAmount(transactionData);
    final balanceBefore = _parseBalanceBefore(transactionData);
    final balanceAfter = _parseBalanceAfter(transactionData);
    final timestamp = _parseTimestamp(transactionData);
    final description = _parseDescription(transactionData);
    final location = _parseLocation(transactionData);
    final merchantInfo = _parseMerchantInfo(transactionData);
    final transactionId = _parseTransactionId(transactionData);

    return CardTransaction(
      cardId: cardId,
      type: type,
      amount: amount,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      timestamp: timestamp,
      description: description,
      location: location,
      merchantInfo: merchantInfo,
      transactionId: transactionId,
      isEstimated: _isEstimatedTransaction(transactionData),
      currency: currency,
      metadata: Map<String, dynamic>.from(transactionData),
      source: 'NFC Card Data',
    );
  }

  // Factory constructor from balance change
  factory CardTransaction.fromBalanceChange({
    required String cardId,
    required CardBalance previousBalance,
    required CardBalance currentBalance,
    String? description,
    String? location,
  }) {
    final balanceChange = currentBalance.currentBalance - previousBalance.currentBalance;
    final type = balanceChange >= 0 ? TransactionType.credit : TransactionType.debit;
    
    return CardTransaction(
      cardId: cardId,
      type: type,
      amount: balanceChange.abs(),
      balanceBefore: previousBalance.currentBalance,
      balanceAfter: currentBalance.currentBalance,
      timestamp: currentBalance.lastUpdated,
      description: description ?? 'Balance change detected',
      location: location,
      isEstimated: true,
      currency: currentBalance.currency,
      source: 'Balance Change Detection',
    );
  }

  // Factory constructor from database
  factory CardTransaction.fromMap(Map<String, dynamic> map) {
    return CardTransaction(
      id: map['id'],
      cardId: map['card_id'],
      type: TransactionType.values[map['transaction_type'] ?? 0],
      amount: map['amount']?.toDouble() ?? 0.0,
      balanceBefore: map['balance_before']?.toDouble(),
      balanceAfter: map['balance_after']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'],
      location: map['location'],
      merchantInfo: map['merchant_info'],
      transactionId: map['transaction_id'],
      isEstimated: map['is_estimated'] == 1,
      currency: CurrencyType.values.firstWhere(
        (c) => c.code == (map['currency'] ?? 'USD'),
        orElse: () => CurrencyType.usd,
      ),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
      source: map['source'],
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'transaction_type': type.index,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'location': location,
      'merchant_info': merchantInfo,
      'transaction_id': transactionId,
      'is_estimated': isEstimated ? 1 : 0,
      'currency': currency.code,
      'metadata': metadata,
      'source': source,
    };
  }

  // Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'type': type.name,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'location': location,
      'merchantInfo': merchantInfo,
      'transactionId': transactionId,
      'isEstimated': isEstimated,
      'currency': currency.code,
      'source': source,
    };
  }

  // Create copy with updated values
  CardTransaction copyWith({
    String? cardId,
    TransactionType? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    DateTime? timestamp,
    String? description,
    String? location,
    String? merchantInfo,
    String? transactionId,
    bool? isEstimated,
    CurrencyType? currency,
    Map<String, dynamic>? metadata,
    String? source,
  }) {
    return CardTransaction(
      id: id,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      location: location ?? this.location,
      merchantInfo: merchantInfo ?? this.merchantInfo,
      transactionId: transactionId ?? this.transactionId,
      isEstimated: isEstimated ?? this.isEstimated,
      currency: currency ?? this.currency,
      metadata: metadata ?? this.metadata,
      source: source ?? this.source,
    );
  }

  // Getters
  String get formattedAmount {
    final prefix = type == TransactionType.debit ? '-' : '+';
    return '$prefix${NumberFormat.currency(
      locale: 'en_US',
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    ).format(amount)}';
  }

  String get formattedBalanceBefore {
    if (balanceBefore == null) return 'N/A';
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    ).format(balanceBefore!);
  }

  String get formattedBalanceAfter {
    if (balanceAfter == null) return 'N/A';
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    ).format(balanceAfter!);
  }

  String get formattedTimestamp {
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(timestamp);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(timestamp);
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.debit:
        return 'Payment';
      case TransactionType.credit:
        return 'Top-up';
      case TransactionType.reload:
        return 'Reload';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.fee:
        return 'Fee';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.penalty:
        return 'Penalty';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.unknown:
        return 'Unknown';
    }
  }

  bool get isCredit => type == TransactionType.credit || 
                     type == TransactionType.reload || 
                     type == TransactionType.refund || 
                     type == TransactionType.bonus;

  bool get isDebit => type == TransactionType.debit || 
                     type == TransactionType.fee || 
                     type == TransactionType.penalty;

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
           timestamp.month == now.month &&
           timestamp.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(weekStart);
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return timestamp.year == now.year && timestamp.month == now.month;
  }

  // Static parsing methods for NFC data
  static TransactionType _parseTransactionType(Map<String, dynamic> data) {
    // Look for transaction type indicators in the data
    final dataString = data.toString().toLowerCase();
    
    if (dataString.contains('debit') || dataString.contains('payment')) {
      return TransactionType.debit;
    }
    if (dataString.contains('credit') || dataString.contains('topup') || dataString.contains('reload')) {
      return TransactionType.credit;
    }
    if (dataString.contains('fee') || dataString.contains('charge')) {
      return TransactionType.fee;
    }
    if (dataString.contains('refund')) {
      return TransactionType.refund;
    }
    if (dataString.contains('transfer')) {
      return TransactionType.transfer;
    }
    if (dataString.contains('penalty')) {
      return TransactionType.penalty;
    }
    if (dataString.contains('bonus') || dataString.contains('reward')) {
      return TransactionType.bonus;
    }
    
    return TransactionType.unknown;
  }

  static double _parseAmount(Map<String, dynamic> data) {
    // Try to find amount in various fields
    if (data.containsKey('amount')) {
      return (data['amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (data.containsKey('value')) {
      return (data['value'] as num?)?.toDouble() ?? 0.0;
    }
    
    // Look for amount patterns in string data
    final dataString = data.toString();
    final amountMatch = RegExp(r'amount[:\s]*\$?(\d+\.?\d*)').firstMatch(dataString.toLowerCase());
    if (amountMatch != null) {
      return double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
    }
    
    return 0.0;
  }

  static double? _parseBalanceBefore(Map<String, dynamic> data) {
    if (data.containsKey('balance_before')) {
      return (data['balance_before'] as num?)?.toDouble();
    }
    if (data.containsKey('previous_balance')) {
      return (data['previous_balance'] as num?)?.toDouble();
    }
    return null;
  }

  static double? _parseBalanceAfter(Map<String, dynamic> data) {
    if (data.containsKey('balance_after')) {
      return (data['balance_after'] as num?)?.toDouble();
    }
    if (data.containsKey('current_balance')) {
      return (data['current_balance'] as num?)?.toDouble();
    }
    if (data.containsKey('new_balance')) {
      return (data['new_balance'] as num?)?.toDouble();
    }
    return null;
  }

  static DateTime _parseTimestamp(Map<String, dynamic> data) {
    if (data.containsKey('timestamp')) {
      final timestamp = data['timestamp'];
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    if (data.containsKey('date')) {
      final date = data['date'];
      if (date is String) {
        return DateTime.tryParse(date) ?? DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  static String? _parseDescription(Map<String, dynamic> data) {
    if (data.containsKey('description')) {
      return data['description']?.toString();
    }
    if (data.containsKey('memo')) {
      return data['memo']?.toString();
    }
    if (data.containsKey('note')) {
      return data['note']?.toString();
    }
    return null;
  }

  static String? _parseLocation(Map<String, dynamic> data) {
    if (data.containsKey('location')) {
      return data['location']?.toString();
    }
    if (data.containsKey('terminal')) {
      return data['terminal']?.toString();
    }
    if (data.containsKey('station')) {
      return data['station']?.toString();
    }
    return null;
  }

  static String? _parseMerchantInfo(Map<String, dynamic> data) {
    if (data.containsKey('merchant')) {
      return data['merchant']?.toString();
    }
    if (data.containsKey('store')) {
      return data['store']?.toString();
    }
    if (data.containsKey('vendor')) {
      return data['vendor']?.toString();
    }
    return null;
  }

  static String? _parseTransactionId(Map<String, dynamic> data) {
    if (data.containsKey('transaction_id')) {
      return data['transaction_id']?.toString();
    }
    if (data.containsKey('txn_id')) {
      return data['txn_id']?.toString();
    }
    if (data.containsKey('id')) {
      return data['id']?.toString();
    }
    return null;
  }

  static bool _isEstimatedTransaction(Map<String, dynamic> data) {
    if (data.containsKey('is_estimated')) {
      return data['is_estimated'] == true;
    }
    
    // If transaction has incomplete data, mark as estimated
    return !data.containsKey('amount') || 
           !data.containsKey('timestamp') ||
           !data.containsKey('transaction_id');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardTransaction && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CardTransaction{id: $id, type: ${type.name}, amount: $formattedAmount, timestamp: $formattedTimestamp}';
  }
}