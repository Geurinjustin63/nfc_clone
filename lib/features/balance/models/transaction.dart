import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

enum TransactionType {
  debit,
  credit,
  refund,
  fee,
  bonus,
  transfer,
  topup,
  unknown,
}

enum TransactionStatus {
  completed,
  pending,
  failed,
  cancelled,
  disputed,
}

enum TransactionCategory {
  transport,
  food,
  shopping,
  entertainment,
  healthcare,
  education,
  utilities,
  fuel,
  parking,
  groceries,
  restaurants,
  coffee,
  other,
}

class Transaction {
  final String id;
  final String cardId;
  final Decimal amount;
  final Currency currency;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? merchantName;
  final String? merchantId;
  final String? location;
  final TransactionCategory? category;
  final String? description;
  final String? reference;
  final Decimal? balanceAfter;
  final Decimal? balanceBefore;
  final Map<String, dynamic> rawData;
  final Map<String, dynamic> metadata;

  Transaction({
    String? id,
    required this.cardId,
    required this.amount,
    this.currency = Currency.usd,
    required this.type,
    this.status = TransactionStatus.completed,
    DateTime? timestamp,
    this.merchantName,
    this.merchantId,
    this.location,
    this.category,
    this.description,
    this.reference,
    this.balanceAfter,
    this.balanceBefore,
    this.rawData = const {},
    this.metadata = const {},
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory Transaction.fromNFCData({
    required String cardId,
    required Map<String, dynamic> nfcData,
    required BalanceType balanceType,
  }) {
    // Parse transaction data based on card type
    switch (balanceType) {
      case BalanceType.transit:
        return _parseTransitTransaction(cardId, nfcData);
      case BalanceType.payment:
        return _parsePaymentTransaction(cardId, nfcData);
      case BalanceType.giftCard:
        return _parseGiftCardTransaction(cardId, nfcData);
      default:
        return _parseGenericTransaction(cardId, nfcData);
    }
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      cardId: map['card_id'],
      amount: Decimal.parse(map['amount'].toString()),
      currency: Currency.values[map['currency'] ?? 0],
      type: TransactionType.values[map['transaction_type']],
      status: TransactionStatus.values[map['status'] ?? 0],
      timestamp: DateTime.parse(map['timestamp']),
      merchantName: map['merchant_name'],
      merchantId: map['merchant_id'],
      location: map['merchant_location'],
      category: map['category'] != null ? TransactionCategory.values[map['category']] : null,
      description: map['description'],
      reference: map['reference'],
      balanceAfter: map['balance_after'] != null ? Decimal.parse(map['balance_after'].toString()) : null,
      balanceBefore: map['balance_before'] != null ? Decimal.parse(map['balance_before'].toString()) : null,
      rawData: Map<String, dynamic>.from(map['raw_data'] ?? {}),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'amount': amount.toString(),
      'currency': currency.index,
      'transaction_type': type.index,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
      'merchant_name': merchantName,
      'merchant_id': merchantId,
      'merchant_location': location,
      'category': category?.index,
      'description': description,
      'reference': reference,
      'balance_after': balanceAfter?.toString(),
      'balance_before': balanceBefore?.toString(),
      'raw_data': rawData,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'amount': amount.toString(),
      'currency': currency.name,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'merchantName': merchantName,
      'merchantId': merchantId,
      'location': location,
      'category': category?.name,
      'description': description,
      'reference': reference,
      'balanceAfter': balanceAfter?.toString(),
      'balanceBefore': balanceBefore?.toString(),
      'rawData': rawData,
      'metadata': metadata,
    };
  }

  // Helper methods
  String get formattedAmount {
    final symbol = CardBalance.getCurrencySymbol(currency);
    final sign = type == TransactionType.debit ? '-' : '+';
    return '$sign$symbol${amount.toStringAsFixed(2)}';
  }

  String get displayAmount {
    final symbol = CardBalance.getCurrencySymbol(currency);
    if (amount >= Decimal.fromInt(1000)) {
      return '$symbol${(amount / Decimal.fromInt(1000)).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  String get categoryDisplayName {
    if (category == null) return 'Other';
    
    switch (category!) {
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.healthcare:
        return 'Healthcare';
      case TransactionCategory.education:
        return 'Education';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.fuel:
        return 'Fuel';
      case TransactionCategory.parking:
        return 'Parking';
      case TransactionCategory.groceries:
        return 'Groceries';
      case TransactionCategory.restaurants:
        return 'Restaurants';
      case TransactionCategory.coffee:
        return 'Coffee & Cafes';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.debit:
        return 'Purchase';
      case TransactionType.credit:
        return 'Credit';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.fee:
        return 'Fee';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.topup:
        return 'Top-up';
      case TransactionType.unknown:
        return 'Unknown';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.disputed:
        return 'Disputed';
    }
  }

  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 24;
  }

  // Factory constructors for specific card types
  static Transaction _parseTransitTransaction(String cardId, Map<String, dynamic> nfcData) {
    // Parse transit card transaction data
    // Example: London Oyster card transaction parsing
    final mifareData = nfcData['mifare_classic'];
    if (mifareData != null) {
      return _parseOysterTransaction(cardId, mifareData);
    }
    
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Transit transaction data not available',
      rawData: nfcData,
    );
  }

  static Transaction _parsePaymentTransaction(String cardId, Map<String, dynamic> nfcData) {
    // Parse payment card transaction data
    // Note: Most payment cards don't store transaction history on chip
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Payment card transaction history not stored on chip',
      rawData: nfcData,
    );
  }

  static Transaction _parseGiftCardTransaction(String cardId, Map<String, dynamic> nfcData) {
    // Parse gift card transaction data from NDEF
    final ndefData = nfcData['ndef'];
    if (ndefData != null) {
      return _parseGiftCardNDEF(cardId, ndefData);
    }
    
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Gift card transaction data not available',
      rawData: nfcData,
    );
  }

  static Transaction _parseGenericTransaction(String cardId, Map<String, dynamic> nfcData) {
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Generic transaction - data format unknown',
      rawData: nfcData,
    );
  }

  static Transaction _parseOysterTransaction(String cardId, Map<String, dynamic> mifareData) {
    // Oyster card specific transaction parsing
    // Transactions are stored in specific sectors with encoded data
    try {
      final sectors = mifareData['sectors'] as Map<String, dynamic>?;
      if (sectors != null && sectors.containsKey('sector_2')) {
        final sector2 = sectors['sector_2'] as Map<String, dynamic>;
        final blocks = sector2['blocks'] as List<dynamic>?;
        
        if (blocks != null && blocks.isNotEmpty) {
          final transactionBlock = blocks[0] as Map<String, dynamic>;
          final data = transactionBlock['data'] as List<int>;
          
          // Parse Oyster transaction data (simplified)
          final amount = _parseOysterAmount(data);
          final timestamp = _parseOysterTimestamp(data);
          final location = _parseOysterLocation(data);
          
          return Transaction(
            cardId: cardId,
            amount: Decimal.parse(amount.toString()),
            currency: Currency.gbp,
            type: TransactionType.debit,
            timestamp: timestamp,
            location: location,
            category: TransactionCategory.transport,
            description: 'London Transport',
            rawData: {'sector_2': sector2},
          );
        }
      }
    } catch (e) {
      // Return empty transaction if parsing fails
    }
    
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Oyster transaction parsing failed',
      rawData: mifareData,
    );
  }

  static Transaction _parseGiftCardNDEF(String cardId, Map<String, dynamic> ndefData) {
    // Parse gift card NDEF data for transaction information
    try {
      final records = ndefData['records'] as List<dynamic>?;
      if (records != null) {
        for (final record in records) {
          final recordMap = record as Map<String, dynamic>;
          final payload = recordMap['payload'] as List<int>?;
          
          if (payload != null) {
            final payloadString = String.fromCharCodes(payload);
            
            // Look for transaction patterns in NDEF payload
            if (payloadString.contains('TRANSACTION') || payloadString.contains('BALANCE')) {
              return _parseNDEFTransaction(cardId, payloadString);
            }
          }
        }
      }
    } catch (e) {
      // Return empty transaction if parsing fails
    }
    
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'Gift card transaction data not found',
      rawData: ndefData,
    );
  }

  static Transaction _parseNDEFTransaction(String cardId, String payload) {
    // Parse transaction data from NDEF payload
    // This is highly dependent on the card issuer's format
    return Transaction(
      cardId: cardId,
      amount: Decimal.zero,
      type: TransactionType.unknown,
      description: 'NDEF transaction: $payload',
      rawData: {'ndef_payload': payload},
    );
  }

  // Helper methods for Oyster card parsing
  static double _parseOysterAmount(List<int> data) {
    // Oyster amount parsing (simplified)
    // Actual implementation would follow TfL's encoding format
    if (data.length >= 4) {
      return ((data[2] | (data[3] << 8)) / 100.0);
    }
    return 0.0;
  }

  static DateTime _parseOysterTimestamp(List<int> data) {
    // Oyster timestamp parsing (simplified)
    // Actual implementation would decode TfL's timestamp format
    return DateTime.now().subtract(const Duration(hours: 1));
  }

  static String _parseOysterLocation(List<int> data) {
    // Oyster location parsing (simplified)
    // Actual implementation would decode station codes
    return 'London Transport';
  }

  Transaction copyWith({
    Decimal? amount,
    Currency? currency,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? timestamp,
    String? merchantName,
    String? merchantId,
    String? location,
    TransactionCategory? category,
    String? description,
    String? reference,
    Decimal? balanceAfter,
    Decimal? balanceBefore,
    Map<String, dynamic>? rawData,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id,
      cardId: cardId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      merchantName: merchantName ?? this.merchantName,
      merchantId: merchantId ?? this.merchantId,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      rawData: rawData ?? this.rawData,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction{id: $id, amount: $formattedAmount, type: $type, merchant: $merchantName}';
  }
}