import 'dart:math';
import '../../../core/models/card_balance.dart';
import '../../../core/models/card_transaction.dart';
import '../../../core/models/nfc_card.dart';

class DemoBalanceGenerator {
  static final Random _random = Random();

  /// Generate demo balance data for testing
  static Map<String, dynamic> generateDemoBalanceData(CardType cardType) {
    switch (cardType) {
      case CardType.mifareClassic:
        return _generateMifareClassicBalance();
      case CardType.mifareUltralight:
        return _generateMifareUltralightBalance();
      case CardType.ntag:
        return _generateNTAGBalance();
      default:
        return _generateGenericBalance();
    }
  }

  /// Generate MIFARE Classic demo balance (transit card pattern)
  static Map<String, dynamic> _generateMifareClassicBalance() {
    final balance = _random.nextDouble() * 50 + 5; // $5-$55
    final balanceInCents = (balance * 100).toInt();
    
    // Convert to little-endian bytes
    final byte0 = balanceInCents & 0xFF;
    final byte1 = (balanceInCents >> 8) & 0xFF;
    final byte2 = (balanceInCents >> 16) & 0xFF;
    final byte3 = (balanceInCents >> 24) & 0xFF;

    return {
      'mifare_classic': {
        'blockCount': 64,
        'sectorCount': 16,
        'size': 1024,
        'type': '1K',
        'sectors': {
          'sector_1': {
            'authenticated': true,
            'key_used': [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
            'blocks': [
              {
                'index': 4,
                'data': [
                  byte0, byte1, byte2, byte3, // Balance in cents (little-endian)
                  0x00, 0x00, 0x00, 0x00,     // Reserved
                  0x12, 0x34, 0x56, 0x78,     // Transaction counter
                  0xAB, 0xCD, 0xEF, 0x01,     // Checksum
                ],
              },
              {
                'index': 5,
                'data': List.generate(16, (i) => _random.nextInt(256)),
              },
            ],
          },
          'sector_4': {
            'authenticated': true,
            'blocks': [
              {
                'index': 16,
                'data': [
                  // Last transaction data
                  0x01, 0x23, // Transaction type
                  byte0, byte1, byte2, byte3, // Amount
                  ...List.generate(10, (i) => _random.nextInt(256)),
                ],
              },
            ],
          },
        },
      },
    };
  }

  /// Generate MIFARE Ultralight demo balance (gift card pattern)
  static Map<String, dynamic> _generateMifareUltralightBalance() {
    final balance = _random.nextDouble() * 100 + 10; // $10-$110
    final balanceInCents = (balance * 100).toInt();
    
    // Convert to big-endian bytes for Ultralight
    final byte0 = (balanceInCents >> 24) & 0xFF;
    final byte1 = (balanceInCents >> 16) & 0xFF;
    final byte2 = (balanceInCents >> 8) & 0xFF;
    final byte3 = balanceInCents & 0xFF;

    return {
      'mifare_ultralight': {
        'type': 'EV1_MF0UL11',
        'pages': [
          {
            'page': 0,
            'data': [0x04, 0xA8, 0x95, 0xE2], // UID part 1
          },
          {
            'page': 1,
            'data': [0x12, 0x34, 0x56, 0x78], // UID part 2
          },
          {
            'page': 2,
            'data': [0xAB, 0x48, 0x00, 0x00], // UID + BCC
          },
          {
            'page': 3,
            'data': [0xE1, 0x10, 0x12, 0x00], // Capability container
          },
          {
            'page': 4,
            'data': [byte0, byte1, byte2, byte3], // Balance (big-endian)
          },
          {
            'page': 5,
            'data': [0x03, 0x0F, 0xD1, 0x01], // NDEF header
          },
          {
            'page': 6,
            'data': [0x0B, 0x54, 0x02, 0x65], // NDEF payload start
          },
          {
            'page': 7,
            'data': [0x6E, 0x47, 0x69, 0x66], // Gift card identifier
          },
        ],
      },
    };
  }

  /// Generate NTAG demo balance (loyalty card pattern)
  static Map<String, dynamic> _generateNTAGBalance() {
    final points = _random.nextInt(5000) + 100; // 100-5100 points
    
    return {
      'ndef': {
        'isWritable': true,
        'maxSize': 924,
        'cachedMessage': {
          'records': [
            {
              'typeNameFormat': 1,
              'type': [0x54], // Text record
              'identifier': [],
              'payload': [
                0x02, 0x65, 0x6E, // Language code: "en"
                ...('Loyalty Points: $points').codeUnits,
              ],
            },
            {
              'typeNameFormat': 1,
              'type': [0x55], // URI record
              'identifier': [],
              'payload': [
                0x01, // URI prefix "http://www."
                ...('example.com/balance?points=$points').codeUnits,
              ],
            },
          ],
        },
      },
    };
  }

  /// Generate generic balance data
  static Map<String, dynamic> _generateGenericBalance() {
    final balance = _random.nextDouble() * 75 + 25; // $25-$100
    
    return {
      'generic_data': {
        'balance': balance,
        'balance_string': 'Balance: \$${balance.toStringAsFixed(2)}',
        'last_transaction': {
          'amount': _random.nextDouble() * 10,
          'type': _random.nextBool() ? 'debit' : 'credit',
          'timestamp': DateTime.now().subtract(
            Duration(hours: _random.nextInt(168)), // Last week
          ).toIso8601String(),
        },
      },
    };
  }

  /// Create demo card with balance data
  static NFCCard createDemoCardWithBalance({
    required String name,
    required CardType cardType,
    required BalanceType balanceType,
    String? description,
  }) {
    final balanceData = generateDemoBalanceData(cardType);
    final uid = List.generate(7, (i) => _random.nextInt(256));
    
    return NFCCard(
      name: name,
      description: description ?? _getDefaultDescription(balanceType),
      type: cardType,
      rawData: balanceData,
      uid: uid,
      standard: _getStandardForCardType(cardType),
      tags: [balanceType.name, 'demo', 'with_balance'],
      metadata: {
        'is_demo': true,
        'has_balance': true,
        'balance_type': balanceType.name,
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Generate demo transaction history
  static List<CardTransaction> generateDemoTransactions({
    required String cardId,
    required CurrencyType currency,
    int count = 10,
  }) {
    final transactions = <CardTransaction>[];
    var currentBalance = _random.nextDouble() * 50 + 50; // Start with $50-$100
    
    for (int i = 0; i < count; i++) {
      final isDebit = _random.nextBool();
      final amount = _random.nextDouble() * (isDebit ? 20 : 50) + 1; // $1-$20 debit, $1-$50 credit
      
      final previousBalance = currentBalance;
      currentBalance = isDebit ? currentBalance - amount : currentBalance + amount;
      
      final transaction = CardTransaction(
        cardId: cardId,
        type: isDebit ? TransactionType.debit : TransactionType.credit,
        amount: amount,
        balanceBefore: previousBalance,
        balanceAfter: currentBalance.clamp(0, double.infinity),
        timestamp: DateTime.now().subtract(Duration(days: i)),
        description: _generateTransactionDescription(isDebit),
        location: _generateLocation(),
        merchantInfo: isDebit ? _generateMerchant() : null,
        isEstimated: _random.nextDouble() < 0.3, // 30% estimated
        currency: currency,
        source: 'Demo Data',
      );
      
      transactions.add(transaction);
    }
    
    return transactions.reversed.toList(); // Chronological order
  }

  static String _getDefaultDescription(BalanceType balanceType) {
    switch (balanceType) {
      case BalanceType.transit:
        return 'Metro/Bus transit card with stored value';
      case BalanceType.payment:
        return 'Contactless payment card';
      case BalanceType.gift:
        return 'Store gift card with remaining balance';
      case BalanceType.loyalty:
        return 'Loyalty card with reward points';
      case BalanceType.parking:
        return 'Parking meter card with credit';
      case BalanceType.campus:
        return 'Campus card for dining and services';
      case BalanceType.healthcare:
        return 'Healthcare card with medical credits';
      case BalanceType.prepaid:
        return 'Prepaid card with stored value';
      case BalanceType.unknown:
        return 'Card with unknown balance type';
    }
  }

  static String _getStandardForCardType(CardType cardType) {
    switch (cardType) {
      case CardType.mifareClassic:
      case CardType.mifareUltralight:
      case CardType.ntag:
        return 'ISO 14443 Type A';
      case CardType.desfire:
        return 'ISO 14443 Type A (DESFire)';
      case CardType.felica:
        return 'FeliCa';
      case CardType.iso15693:
        return 'ISO 15693';
      case CardType.iso14443A:
        return 'ISO 14443 Type A';
      case CardType.iso14443B:
        return 'ISO 14443 Type B';
      case CardType.unknown:
        return 'Unknown Standard';
    }
  }

  static String _generateTransactionDescription(bool isDebit) {
    if (isDebit) {
      final descriptions = [
        'Subway ride',
        'Bus fare',
        'Coffee purchase',
        'Parking fee',
        'Store purchase',
        'Food court',
        'Vending machine',
        'Service charge',
      ];
      return descriptions[_random.nextInt(descriptions.length)];
    } else {
      final descriptions = [
        'Card reload',
        'Top-up',
        'Credit added',
        'Refund',
        'Bonus credit',
        'Cashback',
        'Promotional credit',
      ];
      return descriptions[_random.nextInt(descriptions.length)];
    }
  }

  static String _generateLocation() {
    final locations = [
      'Downtown Station',
      'Main Street',
      'Shopping Mall',
      'University Campus',
      'Airport Terminal',
      'City Center',
      'Parking Garage',
      'Medical Center',
      'Food Court',
      'Transit Hub',
    ];
    return locations[_random.nextInt(locations.length)];
  }

  static String _generateMerchant() {
    final merchants = [
      'Metro Transit',
      'City Parking',
      'Coffee Shop',
      'University Store',
      'Airport Services',
      'Retail Store',
      'Food Vendor',
      'Service Provider',
    ];
    return merchants[_random.nextInt(merchants.length)];
  }

  /// Create multiple demo cards with different balance types
  static List<NFCCard> createDemoBalanceCards() {
    return [
      createDemoCardWithBalance(
        name: 'Metro Transit Card',
        cardType: CardType.mifareClassic,
        balanceType: BalanceType.transit,
        description: 'City metro system card',
      ),
      createDemoCardWithBalance(
        name: 'Campus ID Card',
        cardType: CardType.mifareUltralight,
        balanceType: BalanceType.campus,
        description: 'University student ID with dining credits',
      ),
      createDemoCardWithBalance(
        name: 'Coffee Shop Gift Card',
        cardType: CardType.ntag,
        balanceType: BalanceType.gift,
        description: 'Prepaid coffee shop gift card',
      ),
      createDemoCardWithBalance(
        name: 'Loyalty Rewards Card',
        cardType: CardType.ntag,
        balanceType: BalanceType.loyalty,
        description: 'Store loyalty card with points',
      ),
      createDemoCardWithBalance(
        name: 'Parking Meter Card',
        cardType: CardType.mifareUltralight,
        balanceType: BalanceType.parking,
        description: 'City parking meter prepaid card',
      ),
    ];
  }

  /// Generate realistic balance based on card type
  static double generateRealisticBalance(BalanceType balanceType) {
    switch (balanceType) {
      case BalanceType.transit:
        return _random.nextDouble() * 40 + 10; // $10-$50
      case BalanceType.payment:
        return _random.nextDouble() * 500 + 50; // $50-$550
      case BalanceType.gift:
        return _random.nextDouble() * 75 + 5; // $5-$80
      case BalanceType.loyalty:
        return _random.nextDouble() * 2000 + 100; // 100-2100 points
      case BalanceType.parking:
        return _random.nextDouble() * 25 + 5; // $5-$30
      case BalanceType.campus:
        return _random.nextDouble() * 150 + 25; // $25-$175
      case BalanceType.healthcare:
        return _random.nextDouble() * 200 + 50; // $50-$250
      case BalanceType.prepaid:
        return _random.nextDouble() * 100 + 20; // $20-$120
      case BalanceType.unknown:
        return _random.nextDouble() * 50 + 10; // $10-$60
    }
  }

  /// Create demo balance with realistic transaction history
  static Future<({CardBalance balance, List<CardTransaction> transactions})> createDemoBalanceWithHistory({
    required String cardId,
    required BalanceType balanceType,
    required CurrencyType currency,
    int transactionCount = 15,
  }) async {
    // Generate balance
    final currentBalance = generateRealisticBalance(balanceType);
    final previousBalance = currentBalance + (_random.nextDouble() * 20 - 10); // ±$10 change
    
    final balance = CardBalance(
      cardId: cardId,
      currentBalance: currentBalance,
      previousBalance: previousBalance > 0 ? previousBalance : null,
      currency: currency,
      balanceType: balanceType,
      confidenceLevel: 0.85 + (_random.nextDouble() * 0.15), // 85-100% confidence
      balanceSource: 'Demo ${balanceType.name} card data',
    );

    // Generate transaction history
    final transactions = generateDemoTransactions(
      cardId: cardId,
      currency: currency,
      count: transactionCount,
    );

    return (balance: balance, transactions: transactions);
  }

  /// Generate spending patterns based on balance type
  static Map<String, double> generateSpendingPatterns(BalanceType balanceType) {
    switch (balanceType) {
      case BalanceType.transit:
        return {
          'Daily Commute': 60.0,
          'Weekend Travel': 25.0,
          'Airport Express': 15.0,
        };
      case BalanceType.gift:
        return {
          'Coffee & Snacks': 45.0,
          'Meals': 35.0,
          'Merchandise': 20.0,
        };
      case BalanceType.campus:
        return {
          'Dining Hall': 50.0,
          'Library Services': 20.0,
          'Laundry': 15.0,
          'Vending': 15.0,
        };
      case BalanceType.parking:
        return {
          'Hourly Parking': 70.0,
          'Daily Parking': 25.0,
          'Monthly Pass': 5.0,
        };
      default:
        return {
          'General Usage': 100.0,
        };
    }
  }

  /// Simulate balance update based on realistic usage
  static CardBalance simulateBalanceUpdate(
    CardBalance currentBalance, 
    Duration timePassed,
  ) {
    final usageRate = _getUsageRate(currentBalance.balanceType);
    final dailyUsage = usageRate * (timePassed.inHours / 24.0);
    
    // Add some randomness
    final variation = (dailyUsage * 0.3) * (_random.nextDouble() - 0.5);
    final actualUsage = dailyUsage + variation;
    
    final newBalance = (currentBalance.currentBalance - actualUsage).clamp(0.0, double.infinity);
    
    return currentBalance.copyWith(
      previousBalance: currentBalance.currentBalance,
      currentBalance: newBalance,
      lastUpdated: DateTime.now(),
    );
  }

  static double _getUsageRate(BalanceType balanceType) {
    switch (balanceType) {
      case BalanceType.transit:
        return 5.0; // $5/day average
      case BalanceType.campus:
        return 12.0; // $12/day for meals
      case BalanceType.parking:
        return 8.0; // $8/day for parking
      case BalanceType.gift:
        return 3.0; // $3/day occasional use
      default:
        return 2.0; // $2/day default
    }
  }
}