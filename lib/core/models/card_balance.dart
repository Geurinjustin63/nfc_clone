import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

enum BalanceType {
  transit,     // Bus, train, subway cards
  payment,     // Credit/debit cards
  gift,        // Gift cards
  loyalty,     // Loyalty/reward points
  parking,     // Parking cards
  campus,      // Student ID cards
  healthcare,  // Medical cards
  prepaid,     // Prepaid cards
  unknown,
}

enum TransactionType {
  debit,       // Money spent
  credit,      // Money added
  reload,      // Card topped up
  transfer,    // Money transferred
  fee,         // Service fees
  refund,      // Money refunded
  penalty,     // Penalty charges
  bonus,       // Bonus credits
  unknown,
}

enum CurrencyType {
  usd('USD', '\$', 2),
  eur('EUR', '€', 2),
  gbp('GBP', '£', 2),
  jpy('JPY', '¥', 0),
  cny('CNY', '¥', 2),
  krw('KRW', '₩', 0),
  points('PTS', 'pts', 0),
  credits('CRD', 'credits', 0);

  const CurrencyType(this.code, this.symbol, this.decimalPlaces);
  final String code;
  final String symbol;
  final int decimalPlaces;
}

class CardBalance {
  final String id;
  final String cardId;
  final double currentBalance;
  final double? previousBalance;
  final CurrencyType currency;
  final BalanceType balanceType;
  final DateTime lastUpdated;
  final String? lastTransactionId;
  final bool isEncrypted;
  final Map<String, dynamic>? rawBalanceData;
  final double confidenceLevel; // 0.0-1.0 accuracy level
  final String? balanceSource; // Where balance was read from

  CardBalance({
    String? id,
    required this.cardId,
    required this.currentBalance,
    this.previousBalance,
    required this.currency,
    required this.balanceType,
    DateTime? lastUpdated,
    this.lastTransactionId,
    this.isEncrypted = false,
    this.rawBalanceData,
    this.confidenceLevel = 1.0,
    this.balanceSource,
  }) : id = id ?? const Uuid().v4(),
       lastUpdated = lastUpdated ?? DateTime.now();

  // Factory constructor from NFC card data
  factory CardBalance.fromNFCData({
    required String cardId,
    required Map<String, dynamic> nfcData,
    required BalanceType balanceType,
    CurrencyType currency = CurrencyType.usd,
  }) {
    final balance = _parseBalanceFromNFCData(nfcData, balanceType);
    final confidence = _calculateConfidence(nfcData, balanceType);
    
    return CardBalance(
      cardId: cardId,
      currentBalance: balance.amount,
      currency: currency,
      balanceType: balanceType,
      rawBalanceData: nfcData,
      confidenceLevel: confidence,
      balanceSource: balance.source,
    );
  }

  // Factory constructor from database
  factory CardBalance.fromMap(Map<String, dynamic> map) {
    return CardBalance(
      id: map['id'],
      cardId: map['card_id'],
      currentBalance: map['current_balance']?.toDouble() ?? 0.0,
      previousBalance: map['previous_balance']?.toDouble(),
      currency: CurrencyType.values.firstWhere(
        (c) => c.code == map['currency'],
        orElse: () => CurrencyType.usd,
      ),
      balanceType: BalanceType.values[map['balance_type'] ?? 0],
      lastUpdated: DateTime.parse(map['last_updated']),
      lastTransactionId: map['last_transaction_id'],
      isEncrypted: map['is_encrypted'] == 1,
      rawBalanceData: map['raw_balance_data'] != null
          ? Map<String, dynamic>.from(map['raw_balance_data'])
          : null,
      confidenceLevel: map['confidence_level']?.toDouble() ?? 1.0,
      balanceSource: map['balance_source'],
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'current_balance': currentBalance,
      'previous_balance': previousBalance,
      'currency': currency.code,
      'balance_type': balanceType.index,
      'last_updated': lastUpdated.toIso8601String(),
      'last_transaction_id': lastTransactionId,
      'is_encrypted': isEncrypted ? 1 : 0,
      'raw_balance_data': rawBalanceData,
      'confidence_level': confidenceLevel,
      'balance_source': balanceSource,
    };
  }

  // Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'currentBalance': currentBalance,
      'previousBalance': previousBalance,
      'currency': currency.code,
      'balanceType': balanceType.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastTransactionId': lastTransactionId,
      'isEncrypted': isEncrypted,
      'confidenceLevel': confidenceLevel,
      'balanceSource': balanceSource,
    };
  }

  // Create copy with updated values
  CardBalance copyWith({
    double? currentBalance,
    double? previousBalance,
    CurrencyType? currency,
    BalanceType? balanceType,
    DateTime? lastUpdated,
    String? lastTransactionId,
    bool? isEncrypted,
    Map<String, dynamic>? rawBalanceData,
    double? confidenceLevel,
    String? balanceSource,
  }) {
    return CardBalance(
      id: id,
      cardId: cardId,
      currentBalance: currentBalance ?? this.currentBalance,
      previousBalance: previousBalance ?? this.previousBalance,
      currency: currency ?? this.currency,
      balanceType: balanceType ?? this.balanceType,
      lastUpdated: lastUpdated ?? DateTime.now(),
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      rawBalanceData: rawBalanceData ?? this.rawBalanceData,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      balanceSource: balanceSource ?? this.balanceSource,
    );
  }

  // Getters
  double? get balanceChange => previousBalance != null 
      ? currentBalance - previousBalance! 
      : null;

  bool get hasBalanceChanged => balanceChange != null && balanceChange != 0;

  bool get isLowBalance => currentBalance < _getLowBalanceThreshold();

  bool get isZeroBalance => currentBalance <= 0;

  String get formattedBalance {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    ).format(currentBalance);
  }

  String get formattedBalanceChange {
    if (balanceChange == null) return '';
    final change = balanceChange!;
    final prefix = change > 0 ? '+' : '';
    return '$prefix${NumberFormat.currency(
      locale: 'en_US',
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    ).format(change)}';
  }

  String get balanceTypeDisplayName {
    switch (balanceType) {
      case BalanceType.transit:
        return 'Transit Card';
      case BalanceType.payment:
        return 'Payment Card';
      case BalanceType.gift:
        return 'Gift Card';
      case BalanceType.loyalty:
        return 'Loyalty Card';
      case BalanceType.parking:
        return 'Parking Card';
      case BalanceType.campus:
        return 'Campus Card';
      case BalanceType.healthcare:
        return 'Healthcare Card';
      case BalanceType.prepaid:
        return 'Prepaid Card';
      case BalanceType.unknown:
        return 'Unknown Card';
    }
  }

  // Confidence level description
  String get confidenceDescription {
    if (confidenceLevel >= 0.9) return 'High confidence';
    if (confidenceLevel >= 0.7) return 'Medium confidence';
    if (confidenceLevel >= 0.5) return 'Low confidence';
    return 'Very low confidence';
  }

  bool get isReliable => confidenceLevel >= 0.7;

  // Private helper methods
  double _getLowBalanceThreshold() {
    switch (balanceType) {
      case BalanceType.transit:
        return 5.0; // $5 for transit
      case BalanceType.payment:
        return 10.0; // $10 for payment
      case BalanceType.gift:
        return 1.0; // $1 for gift cards
      case BalanceType.parking:
        return 2.0; // $2 for parking
      default:
        return 5.0;
    }
  }

  // Static helper methods for parsing NFC data
  static ({double amount, String source}) _parseBalanceFromNFCData(
    Map<String, dynamic> nfcData, 
    BalanceType balanceType,
  ) {
    // MIFARE Classic balance parsing
    if (nfcData.containsKey('mifare_classic')) {
      return _parseMifareClassicBalance(nfcData['mifare_classic']);
    }
    
    // MIFARE Ultralight balance parsing
    if (nfcData.containsKey('mifare_ultralight')) {
      return _parseMifareUltralightBalance(nfcData['mifare_ultralight']);
    }
    
    // NDEF balance parsing
    if (nfcData.containsKey('ndef')) {
      return _parseNDEFBalance(nfcData['ndef']);
    }
    
    // Default: try to find balance in raw data
    return _parseGenericBalance(nfcData);
  }

  static ({double amount, String source}) _parseMifareClassicBalance(
    Map<String, dynamic> mifareData,
  ) {
    // Common transit card patterns
    if (mifareData.containsKey('sectors')) {
      final sectors = mifareData['sectors'] as Map<String, dynamic>;
      
      // Check sector 1 (common for transit cards)
      if (sectors.containsKey('sector_1')) {
        final sector1 = sectors['sector_1'] as Map<String, dynamic>;
        if (sector1.containsKey('blocks')) {
          final blocks = sector1['blocks'] as List<dynamic>;
          if (blocks.isNotEmpty) {
            final firstBlock = blocks[0] as Map<String, dynamic>;
            if (firstBlock.containsKey('data')) {
              final data = List<int>.from(firstBlock['data']);
              // Parse balance from bytes 0-3 (little endian)
              if (data.length >= 4) {
                final balanceRaw = (data[3] << 24) | 
                                  (data[2] << 16) | 
                                  (data[1] << 8) | 
                                  data[0];
                final balance = balanceRaw / 100.0; // Cents to dollars
                return (amount: balance, source: 'MIFARE Classic Sector 1');
              }
            }
          }
        }
      }
      
      // Check other common sectors (4, 8, 12)
      for (final sectorKey in ['sector_4', 'sector_8', 'sector_12']) {
        if (sectors.containsKey(sectorKey)) {
          final result = _parseBalanceFromSector(sectors[sectorKey]);
          if (result.amount > 0) {
            return (amount: result.amount, source: 'MIFARE Classic $sectorKey');
          }
        }
      }
    }
    
    return (amount: 0.0, source: 'MIFARE Classic - No balance found');
  }

  static ({double amount, String source}) _parseMifareUltralightBalance(
    Map<String, dynamic> ultralightData,
  ) {
    if (ultralightData.containsKey('pages')) {
      final pages = ultralightData['pages'] as List<dynamic>;
      
      // Check pages 4-7 (common for value storage)
      for (int pageIndex = 4; pageIndex < pages.length && pageIndex < 8; pageIndex++) {
        final page = pages[pageIndex] as Map<String, dynamic>;
        if (page.containsKey('data')) {
          final data = List<int>.from(page['data']);
          if (data.length >= 4) {
            // Try different balance parsing methods
            final balanceMethod1 = (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
            final balanceMethod2 = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
            
            // Use the method that gives a reasonable balance (0.01 - 999.99)
            final balance1 = balanceMethod1 / 100.0;
            final balance2 = balanceMethod2 / 100.0;
            
            if (balance1 >= 0.01 && balance1 <= 999.99) {
              return (amount: balance1, source: 'MIFARE Ultralight Page $pageIndex (LE)');
            } else if (balance2 >= 0.01 && balance2 <= 999.99) {
              return (amount: balance2, source: 'MIFARE Ultralight Page $pageIndex (BE)');
            }
          }
        }
      }
    }
    
    return (amount: 0.0, source: 'MIFARE Ultralight - No balance found');
  }

  static ({double amount, String source}) _parseNDEFBalance(
    Map<String, dynamic> ndefData,
  ) {
    if (ndefData.containsKey('records')) {
      final records = ndefData['records'] as List<dynamic>;
      
      for (int i = 0; i < records.length; i++) {
        final record = records[i] as Map<String, dynamic>;
        if (record.containsKey('payload')) {
          final payload = List<int>.from(record['payload']);
          final payloadString = String.fromCharCodes(payload);
          
          // Look for balance patterns in payload
          final balanceMatch = RegExp(r'balance[:\s]*\$?(\d+\.?\d*)').firstMatch(payloadString.toLowerCase());
          if (balanceMatch != null) {
            final balance = double.tryParse(balanceMatch.group(1) ?? '0') ?? 0.0;
            return (amount: balance, source: 'NDEF Record $i');
          }
          
          // Look for value patterns
          final valueMatch = RegExp(r'value[:\s]*\$?(\d+\.?\d*)').firstMatch(payloadString.toLowerCase());
          if (valueMatch != null) {
            final balance = double.tryParse(valueMatch.group(1) ?? '0') ?? 0.0;
            return (amount: balance, source: 'NDEF Value Record $i');
          }
        }
      }
    }
    
    return (amount: 0.0, source: 'NDEF - No balance found');
  }

  static ({double amount, String source}) _parseGenericBalance(
    Map<String, dynamic> nfcData,
  ) {
    // Try to find balance in any part of the data
    final dataString = nfcData.toString().toLowerCase();
    
    final balanceMatch = RegExp(r'balance[:\s]*\$?(\d+\.?\d*)').firstMatch(dataString);
    if (balanceMatch != null) {
      final balance = double.tryParse(balanceMatch.group(1) ?? '0') ?? 0.0;
      return (amount: balance, source: 'Generic parsing');
    }
    
    return (amount: 0.0, source: 'No balance data found');
  }

  static ({double amount, String source}) _parseBalanceFromSector(
    Map<String, dynamic> sectorData,
  ) {
    if (sectorData.containsKey('blocks')) {
      final blocks = sectorData['blocks'] as List<dynamic>;
      for (int blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
        final block = blocks[blockIndex] as Map<String, dynamic>;
        if (block.containsKey('data')) {
          final data = List<int>.from(block['data']);
          if (data.length >= 4) {
            final balance = ((data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]) / 100.0;
            if (balance > 0 && balance <= 999.99) {
              return (amount: balance, source: 'Block $blockIndex');
            }
          }
        }
      }
    }
    return (amount: 0.0, source: 'No balance in sector');
  }

  static double _calculateConfidence(
    Map<String, dynamic> nfcData, 
    BalanceType balanceType,
  ) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence based on data completeness
    if (nfcData.containsKey('mifare_classic') || nfcData.containsKey('mifare_ultralight')) {
      confidence += 0.3; // Well-known card types
    }
    
    if (nfcData.containsKey('ndef')) {
      confidence += 0.2; // NDEF data available
    }
    
    // Adjust based on balance type and card type match
    if (balanceType == BalanceType.transit && 
        (nfcData.containsKey('mifare_classic') || nfcData.containsKey('mifare_ultralight'))) {
      confidence += 0.2; // Transit cards commonly use MIFARE
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardBalance && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CardBalance{id: $id, cardId: $cardId, balance: $formattedBalance, type: ${balanceType.name}}';
  }
}