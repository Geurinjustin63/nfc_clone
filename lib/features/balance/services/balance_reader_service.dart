import 'dart:async';
import 'package:decimal/decimal.dart';
import '../../../core/models/nfc_card.dart';
import '../models/card_balance.dart';
import '../models/transaction.dart';

class BalanceReaderService {
  static final BalanceReaderService _instance = BalanceReaderService._internal();
  factory BalanceReaderService() => _instance;
  BalanceReaderService._internal();

  // Supported card readers
  final Map<String, CardReader> _cardReaders = {
    'oyster': OysterCardReader(),
    'clipper': ClipperCardReader(),
    'metrocard': MetroCardReader(),
    'octopus': OctopusCardReader(),
    'starbucks': StarbucksCardReader(),
    'generic_mifare': GenericMifareReader(),
    'generic_ndef': GenericNDEFReader(),
  };

  Future<CardBalance?> readBalance(NFCCard card) async {
    try {
      // Determine the best reader for this card
      final reader = _selectReader(card);
      if (reader == null) {
        return null;
      }

      // Attempt to read balance
      final balance = await reader.readBalance(card);
      return balance;
    } catch (e) {
      print('Error reading balance: $e');
      return null;
    }
  }

  Future<List<Transaction>> readTransactionHistory(NFCCard card) async {
    try {
      final reader = _selectReader(card);
      if (reader == null) {
        return [];
      }

      final transactions = await reader.readTransactions(card);
      return transactions;
    } catch (e) {
      print('Error reading transactions: $e');
      return [];
    }
  }

  CardReader? _selectReader(NFCCard card) {
    // Smart card reader selection based on card data
    
    // Check for specific card identifiers
    final uid = card.formattedUID.toLowerCase();
    final rawData = card.rawData;

    // London Oyster Card
    if (_isOysterCard(card)) {
      return _cardReaders['oyster'];
    }

    // San Francisco Clipper
    if (_isClipperCard(card)) {
      return _cardReaders['clipper'];
    }

    // NYC MetroCard
    if (_isMetroCard(card)) {
      return _cardReaders['metrocard'];
    }

    // Hong Kong Octopus
    if (_isOctopusCard(card)) {
      return _cardReaders['octopus'];
    }

    // Starbucks Gift Card
    if (_isStarbucksCard(card)) {
      return _cardReaders['starbucks'];
    }

    // Generic readers based on card type
    if (card.type == CardType.mifareClassic || card.type == CardType.mifareUltralight) {
      return _cardReaders['generic_mifare'];
    }

    if (card.hasNDEFData) {
      return _cardReaders['generic_ndef'];
    }

    return null;
  }

  bool _isOysterCard(NFCCard card) {
    // Oyster cards have specific UID patterns and sector structures
    final uid = card.formattedUID;
    
    // Oyster cards typically start with specific prefixes
    if (uid.startsWith('04:') && card.type == CardType.mifareClassic) {
      // Check for Oyster-specific data in sectors
      final mifareData = card.rawData['mifare_classic'];
      if (mifareData != null) {
        final sectors = mifareData['sectors'];
        return sectors != null && sectors.containsKey('sector_1');
      }
    }
    return false;
  }

  bool _isClipperCard(NFCCard card) {
    // Clipper card identification
    final uid = card.formattedUID;
    return uid.startsWith('04:') && 
           card.type == CardType.mifareClassic &&
           card.rawData.toString().contains('clipper');
  }

  bool _isMetroCard(NFCCard card) {
    // NYC MetroCard identification
    return card.type == CardType.mifareUltralight &&
           card.rawData.toString().toLowerCase().contains('mta');
  }

  bool _isOctopusCard(NFCCard card) {
    // Hong Kong Octopus card identification
    final uid = card.formattedUID;
    return uid.startsWith('04:') && 
           card.type == CardType.felica;
  }

  bool _isStarbucksCard(NFCCard card) {
    // Starbucks gift card identification
    if (card.hasNDEFData) {
      final ndefData = card.rawData['ndef'];
      if (ndefData != null) {
        final records = ndefData['records'] as List?;
        if (records != null) {
          for (final record in records) {
            final payload = record['payload'] as List<int>?;
            if (payload != null) {
              final payloadString = String.fromCharCodes(payload).toLowerCase();
              if (payloadString.contains('starbucks') || payloadString.contains('sbux')) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  List<String> getSupportedCardTypes() {
    return [
      'London Oyster Card',
      'San Francisco Clipper Card',
      'NYC MetroCard',
      'Hong Kong Octopus Card',
      'Starbucks Gift Card',
      'Generic MIFARE Cards',
      'Generic NDEF Cards',
    ];
  }

  Future<bool> isBalanceReadingSupported(NFCCard card) async {
    final reader = _selectReader(card);
    return reader != null;
  }
}

// Abstract base class for card readers
abstract class CardReader {
  Future<CardBalance?> readBalance(NFCCard card);
  Future<List<Transaction>> readTransactions(NFCCard card);
  bool canRead(NFCCard card);
  String get readerName;
}

// London Oyster Card Reader
class OysterCardReader extends CardReader {
  @override
  String get readerName => 'London Oyster Card';

  @override
  bool canRead(NFCCard card) {
    return card.type == CardType.mifareClassic && 
           card.formattedUID.startsWith('04:');
  }

  @override
  Future<CardBalance?> readBalance(NFCCard card) async {
    try {
      final mifareData = card.rawData['mifare_classic'];
      if (mifareData == null) return null;

      final sectors = mifareData['sectors'] as Map<String, dynamic>?;
      if (sectors == null || !sectors.containsKey('sector_1')) return null;

      final sector1 = sectors['sector_1'] as Map<String, dynamic>;
      final blocks = sector1['blocks'] as List<dynamic>?;
      if (blocks == null || blocks.isEmpty) return null;

      final block0 = blocks[0] as Map<String, dynamic>;
      final data = block0['data'] as List<int>;

      // Parse Oyster balance (simplified implementation)
      final balancePence = (data[8] | (data[9] << 8));
      final balancePounds = balancePence / 100.0;

      return CardBalance(
        cardId: card.id,
        amount: Decimal.parse(balancePounds.toString()),
        currency: Currency.gbp,
        type: BalanceType.transit,
        issuerName: 'Transport for London',
        metadata: {
          'reader': readerName,
          'sector': 'sector_1',
          'raw_balance_pence': balancePence,
        },
      );
    } catch (e) {
      print('Error reading Oyster balance: $e');
      return null;
    }
  }

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async {
    try {
      final transactions = <Transaction>[];
      final mifareData = card.rawData['mifare_classic'];
      if (mifareData == null) return transactions;

      final sectors = mifareData['sectors'] as Map<String, dynamic>?;
      if (sectors == null) return transactions;

      // Oyster stores transaction history in multiple sectors
      for (int sectorNum = 2; sectorNum <= 8; sectorNum++) {
        final sectorKey = 'sector_$sectorNum';
        if (sectors.containsKey(sectorKey)) {
          final sectorData = sectors[sectorKey] as Map<String, dynamic>;
          final transaction = _parseOysterTransactionFromSector(card.id, sectorData);
          if (transaction != null) {
            transactions.add(transaction);
          }
        }
      }

      return transactions;
    } catch (e) {
      print('Error reading Oyster transactions: $e');
      return [];
    }
  }

  Transaction? _parseOysterTransactionFromSector(String cardId, Map<String, dynamic> sectorData) {
    try {
      final blocks = sectorData['blocks'] as List<dynamic>?;
      if (blocks == null || blocks.isEmpty) return null;

      final block = blocks[0] as Map<String, dynamic>;
      final data = block['data'] as List<int>;

      // Parse transaction data (simplified)
      final amount = (data[4] | (data[5] << 8)) / 100.0;
      final timestamp = _parseOysterTimestamp(data);
      final stationCode = data[6] | (data[7] << 8);
      final stationName = _getOysterStationName(stationCode);

      if (amount > 0) {
        return Transaction(
          cardId: cardId,
          amount: Decimal.parse(amount.toString()),
          currency: Currency.gbp,
          type: TransactionType.debit,
          timestamp: timestamp,
          merchantName: 'TfL',
          location: stationName,
          category: TransactionCategory.transport,
          description: 'London Underground/Bus',
          rawData: {'sector_data': sectorData},
        );
      }
    } catch (e) {
      print('Error parsing Oyster transaction: $e');
    }
    return null;
  }

  DateTime _parseOysterTimestamp(List<int> data) {
    // Simplified timestamp parsing - actual implementation would be more complex
    final days = data[10] | (data[11] << 8);
    final minutes = data[12] | (data[13] << 8);
    
    // Oyster epoch is January 1, 1997
    final oysterEpoch = DateTime(1997, 1, 1);
    final date = oysterEpoch.add(Duration(days: days));
    final time = date.add(Duration(minutes: minutes));
    
    return time;
  }

  String _getOysterStationName(int stationCode) {
    // Map station codes to names (simplified)
    final stationMap = {
      0x0001: 'King\'s Cross St. Pancras',
      0x0002: 'Oxford Circus',
      0x0003: 'London Bridge',
      0x0004: 'Victoria',
      0x0005: 'Paddington',
    };
    
    return stationMap[stationCode] ?? 'Unknown Station ($stationCode)';
  }
}

// Starbucks Gift Card Reader
class StarbucksCardReader extends CardReader {
  @override
  String get readerName => 'Starbucks Gift Card';

  @override
  bool canRead(NFCCard card) {
    return card.hasNDEFData;
  }

  @override
  Future<CardBalance?> readBalance(NFCCard card) async {
    try {
      final ndefData = card.rawData['ndef'];
      if (ndefData == null) return null;

      final records = ndefData['records'] as List<dynamic>?;
      if (records == null) return null;

      for (final record in records) {
        final recordMap = record as Map<String, dynamic>;
        final payload = recordMap['payload'] as List<int>?;
        
        if (payload != null) {
          final payloadString = String.fromCharCodes(payload);
          final balance = _parseStarbucksBalance(payloadString);
          
          if (balance != null) {
            return CardBalance(
              cardId: card.id,
              amount: balance,
              currency: Currency.usd,
              type: BalanceType.giftCard,
              issuerName: 'Starbucks',
              metadata: {
                'reader': readerName,
                'payload': payloadString,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error reading Starbucks balance: $e');
    }
    return null;
  }

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async {
    // Starbucks cards typically don't store transaction history
    return [];
  }

  Decimal? _parseStarbucksBalance(String payload) {
    // Parse Starbucks gift card balance from NDEF payload
    // Format varies, but typically includes balance information
    try {
      // Look for balance patterns in the payload
      final regex = RegExp(r'BALANCE[:\s]*\$?(\d+\.?\d*)', caseSensitive: false);
      final match = regex.firstMatch(payload);
      
      if (match != null) {
        final balanceString = match.group(1);
        if (balanceString != null) {
          return Decimal.parse(balanceString);
        }
      }
      
      // Alternative parsing for different formats
      final regex2 = RegExp(r'\$(\d+\.?\d*)', caseSensitive: false);
      final match2 = regex2.firstMatch(payload);
      
      if (match2 != null) {
        final balanceString = match2.group(1);
        if (balanceString != null) {
          return Decimal.parse(balanceString);
        }
      }
    } catch (e) {
      print('Error parsing Starbucks balance: $e');
    }
    return null;
  }
}

// Generic MIFARE Card Reader
class GenericMifareReader extends CardReader {
  @override
  String get readerName => 'Generic MIFARE';

  @override
  bool canRead(NFCCard card) {
    return card.type == CardType.mifareClassic || card.type == CardType.mifareUltralight;
  }

  @override
  Future<CardBalance?> readBalance(NFCCard card) async {
    try {
      // Attempt to find balance data in common locations
      if (card.type == CardType.mifareClassic) {
        return _readMifareClassicBalance(card);
      } else if (card.type == CardType.mifareUltralight) {
        return _readMifareUltralightBalance(card);
      }
    } catch (e) {
      print('Error reading generic MIFARE balance: $e');
    }
    return null;
  }

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async {
    // Generic transaction reading - limited without specific format knowledge
    return [];
  }

  CardBalance? _readMifareClassicBalance(NFCCard card) {
    final mifareData = card.rawData['mifare_classic'];
    if (mifareData == null) return null;

    final sectors = mifareData['sectors'] as Map<String, dynamic>?;
    if (sectors == null) return null;

    // Common balance locations in MIFARE Classic cards
    final balanceLocations = [
      {'sector': 'sector_1', 'block': 0, 'offset': 8},
      {'sector': 'sector_1', 'block': 1, 'offset': 0},
      {'sector': 'sector_2', 'block': 0, 'offset': 0},
    ];

    for (final location in balanceLocations) {
      final sectorKey = location['sector'] as String;
      final blockIndex = location['block'] as int;
      final offset = location['offset'] as int;

      if (sectors.containsKey(sectorKey)) {
        final sector = sectors[sectorKey] as Map<String, dynamic>;
        final blocks = sector['blocks'] as List<dynamic>?;
        
        if (blocks != null && blocks.length > blockIndex) {
          final block = blocks[blockIndex] as Map<String, dynamic>;
          final data = block['data'] as List<int>;
          
          if (data.length > offset + 1) {
            final balanceValue = _parseGenericBalance(data, offset);
            if (balanceValue > 0) {
              return CardBalance(
                cardId: card.id,
                amount: Decimal.parse(balanceValue.toString()),
                currency: Currency.usd, // Default currency
                type: BalanceType.unknown,
                metadata: {
                  'reader': readerName,
                  'location': location,
                  'raw_data': data.sublist(offset, offset + 4),
                },
              );
            }
          }
        }
      }
    }

    return null;
  }

  CardBalance? _readMifareUltralightBalance(NFCCard card) {
    final ultralightData = card.rawData['mifare_ultralight'];
    if (ultralightData == null) return null;

    final pages = ultralightData['pages'] as List<dynamic>?;
    if (pages == null) return null;

    // Common balance locations in MIFARE Ultralight
    for (int pageIndex = 4; pageIndex < pages.length && pageIndex < 12; pageIndex++) {
      final page = pages[pageIndex] as Map<String, dynamic>?;
      if (page != null && page.containsKey('data')) {
        final data = page['data'] as List<int>;
        final balanceValue = _parseGenericBalance(data, 0);
        
        if (balanceValue > 0) {
          return CardBalance(
            cardId: card.id,
            amount: Decimal.parse(balanceValue.toString()),
            currency: Currency.usd, // Default currency
            type: BalanceType.unknown,
            metadata: {
              'reader': readerName,
              'page': pageIndex,
              'raw_data': data,
            },
          );
        }
      }
    }

    return null;
  }

  double _parseGenericBalance(List<int> data, int offset) {
    try {
      // Try different common balance encoding formats
      
      // Little-endian 16-bit integer (common for small amounts)
      if (data.length >= offset + 2) {
        final value16 = data[offset] | (data[offset + 1] << 8);
        if (value16 > 0 && value16 < 100000) { // Reasonable range
          return value16 / 100.0; // Assume cents/pence
        }
      }

      // Little-endian 32-bit integer
      if (data.length >= offset + 4) {
        final value32 = data[offset] | 
                       (data[offset + 1] << 8) | 
                       (data[offset + 2] << 16) | 
                       (data[offset + 3] << 24);
        if (value32 > 0 && value32 < 10000000) { // Reasonable range
          return value32 / 100.0; // Assume cents
        }
      }

      // Big-endian formats
      if (data.length >= offset + 2) {
        final value16be = (data[offset] << 8) | data[offset + 1];
        if (value16be > 0 && value16be < 100000) {
          return value16be / 100.0;
        }
      }

    } catch (e) {
      print('Error parsing generic balance: $e');
    }
    
    return 0.0;
  }
}

// Generic NDEF Card Reader
class GenericNDEFReader extends CardReader {
  @override
  String get readerName => 'Generic NDEF';

  @override
  bool canRead(NFCCard card) {
    return card.hasNDEFData;
  }

  @override
  Future<CardBalance?> readBalance(NFCCard card) async {
    try {
      final ndefData = card.rawData['ndef'];
      if (ndefData == null) return null;

      final records = ndefData['records'] as List<dynamic>?;
      if (records == null) return null;

      for (final record in records) {
        final recordMap = record as Map<String, dynamic>;
        final payload = recordMap['payload'] as List<int>?;
        
        if (payload != null) {
          final payloadString = String.fromCharCodes(payload);
          final balance = _parseNDEFBalance(payloadString);
          
          if (balance != null) {
            return CardBalance(
              cardId: card.id,
              amount: balance,
              currency: Currency.usd,
              type: BalanceType.giftCard,
              metadata: {
                'reader': readerName,
                'payload': payloadString,
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error reading NDEF balance: $e');
    }
    return null;
  }

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async {
    // Generic NDEF cards typically don't store transaction history
    return [];
  }

  Decimal? _parseNDEFBalance(String payload) {
    try {
      // Common balance patterns in NDEF payloads
      final patterns = [
        RegExp(r'BALANCE[:\s]*\$?(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'VALUE[:\s]*\$?(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'AMOUNT[:\s]*\$?(\d+\.?\d*)', caseSensitive: false),
        RegExp(r'\$(\d+\.?\d*)'),
        RegExp(r'(\d+\.?\d*)\s*USD', caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(payload);
        if (match != null) {
          final balanceString = match.group(1);
          if (balanceString != null) {
            return Decimal.parse(balanceString);
          }
        }
      }
    } catch (e) {
      print('Error parsing NDEF balance: $e');
    }
    return null;
  }
}

// Placeholder implementations for other card readers
class ClipperCardReader extends CardReader {
  @override
  String get readerName => 'San Francisco Clipper';

  @override
  bool canRead(NFCCard card) => false; // Implement when needed

  @override
  Future<CardBalance?> readBalance(NFCCard card) async => null;

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async => [];
}

class MetroCardReader extends CardReader {
  @override
  String get readerName => 'NYC MetroCard';

  @override
  bool canRead(NFCCard card) => false; // Implement when needed

  @override
  Future<CardBalance?> readBalance(NFCCard card) async => null;

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async => [];
}

class OctopusCardReader extends CardReader {
  @override
  String get readerName => 'Hong Kong Octopus';

  @override
  bool canRead(NFCCard card) => false; // Implement when needed

  @override
  Future<CardBalance?> readBalance(NFCCard card) async => null;

  @override
  Future<List<Transaction>> readTransactions(NFCCard card) async => [];
}