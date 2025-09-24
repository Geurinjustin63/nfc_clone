import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../models/nfc_card.dart';
import '../constants/app_constants.dart';

enum NFCStatus {
  notAvailable,
  disabled,
  enabled,
  reading,
  writing,
  error,
}

enum NFCOperation {
  read,
  write,
  format,
  authenticate,
}

class NFCReadResult {
  final bool success;
  final NFCCard? card;
  final String? error;
  final Map<String, dynamic>? rawData;
  final Duration readTime;

  NFCReadResult({
    required this.success,
    this.card,
    this.error,
    this.rawData,
    required this.readTime,
  });
}

class NFCWriteResult {
  final bool success;
  final String? error;
  final Duration writeTime;
  final int bytesWritten;

  NFCWriteResult({
    required this.success,
    this.error,
    required this.writeTime,
    this.bytesWritten = 0,
  });
}

class EnhancedNFCService extends ChangeNotifier {
  static final EnhancedNFCService _instance = EnhancedNFCService._internal();
  factory EnhancedNFCService() => _instance;
  EnhancedNFCService._internal();

  NFCStatus _status = NFCStatus.notAvailable;
  bool _isSessionActive = false;
  Timer? _timeoutTimer;
  Completer<NFCReadResult>? _readCompleter;
  Completer<NFCWriteResult>? _writeCompleter;
  
  // Statistics
  int _successfulReads = 0;
  int _failedReads = 0;
  int _successfulWrites = 0;
  int _failedWrites = 0;

  // Getters
  NFCStatus get status => _status;
  bool get isAvailable => _status != NFCStatus.notAvailable;
  bool get isEnabled => _status == NFCStatus.enabled || _status == NFCStatus.reading || _status == NFCStatus.writing;
  bool get isSessionActive => _isSessionActive;
  int get successfulReads => _successfulReads;
  int get failedReads => _failedReads;
  int get successfulWrites => _successfulWrites;
  int get failedWrites => _failedWrites;
  double get readSuccessRate => (_successfulReads + _failedReads) == 0 ? 0.0 : _successfulReads / (_successfulReads + _failedReads);

  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        _updateStatus(NFCStatus.notAvailable);
        return false;
      }

      if (!(Platform.isAndroid || Platform.isIOS)) {
        _updateStatus(NFCStatus.notAvailable);
        return false;
      }

      bool isAvailable = await NfcManager.instance.isAvailable();
      _updateStatus(isAvailable ? NFCStatus.enabled : NFCStatus.notAvailable);
      return isAvailable;
    } catch (e) {
      _updateStatus(NFCStatus.error);
      return false;
    }
  }

  Future<NFCReadResult> readCard({
    Duration timeout = AppConstants.nfcReadTimeout,
    bool enableRetry = true,
    int maxRetries = AppConstants.maxRetryAttempts,
  }) async {
    if (!isAvailable) {
      return NFCReadResult(
        success: false,
        error: AppConstants.nfcNotAvailable,
        readTime: Duration.zero,
      );
    }

    _updateStatus(NFCStatus.reading);
    final startTime = DateTime.now();
    int attemptCount = 0;

    while (attemptCount < (enableRetry ? maxRetries : 1)) {
      try {
        final result = await _performRead(timeout);
        final readTime = DateTime.now().difference(startTime);
        
        if (result.success) {
          _successfulReads++;
          _updateStatus(NFCStatus.enabled);
          return result.copyWith(readTime: readTime);
        } else if (!enableRetry || attemptCount >= maxRetries - 1) {
          _failedReads++;
          _updateStatus(NFCStatus.enabled);
          return result.copyWith(readTime: readTime);
        }
      } catch (e) {
        if (!enableRetry || attemptCount >= maxRetries - 1) {
          _failedReads++;
          _updateStatus(NFCStatus.error);
          return NFCReadResult(
            success: false,
            error: 'Read failed: ${e.toString()}',
            readTime: DateTime.now().difference(startTime),
          );
        }
      }
      
      attemptCount++;
      if (attemptCount < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _failedReads++;
    _updateStatus(NFCStatus.enabled);
    return NFCReadResult(
      success: false,
      error: 'Max retry attempts exceeded',
      readTime: DateTime.now().difference(startTime),
    );
  }

  Future<NFCReadResult> _performRead(Duration timeout) async {
    _readCompleter = Completer<NFCReadResult>();
    _isSessionActive = true;

    // Set timeout
    _timeoutTimer = Timer(timeout, () {
      if (!_readCompleter!.isCompleted) {
        _readCompleter!.complete(NFCReadResult(
          success: false,
          error: 'Read operation timed out',
          readTime: timeout,
        ));
      }
      _stopSession();
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: _onCardDiscovered,
        onError: (error) {
          if (!_readCompleter!.isCompleted) {
            _readCompleter!.complete(NFCReadResult(
              success: false,
              error: error.message,
              readTime: Duration.zero,
            ));
          }
        },
      );

      return await _readCompleter!.future;
    } catch (e) {
      return NFCReadResult(
        success: false,
        error: e.toString(),
        readTime: Duration.zero,
      );
    } finally {
      _stopSession();
    }
  }

  Future<NFCWriteResult> writeCard({
    required NFCCard sourceCard,
    Duration timeout = AppConstants.nfcReadTimeout,
    bool enableRetry = true,
    int maxRetries = AppConstants.maxRetryAttempts,
  }) async {
    if (!isAvailable) {
      return NFCWriteResult(
        success: false,
        error: AppConstants.nfcNotAvailable,
        writeTime: Duration.zero,
      );
    }

    _updateStatus(NFCStatus.writing);
    final startTime = DateTime.now();
    int attemptCount = 0;

    while (attemptCount < (enableRetry ? maxRetries : 1)) {
      try {
        final result = await _performWrite(sourceCard, timeout);
        final writeTime = DateTime.now().difference(startTime);
        
        if (result.success) {
          _successfulWrites++;
          _updateStatus(NFCStatus.enabled);
          return result.copyWith(writeTime: writeTime);
        } else if (!enableRetry || attemptCount >= maxRetries - 1) {
          _failedWrites++;
          _updateStatus(NFCStatus.enabled);
          return result.copyWith(writeTime: writeTime);
        }
      } catch (e) {
        if (!enableRetry || attemptCount >= maxRetries - 1) {
          _failedWrites++;
          _updateStatus(NFCStatus.error);
          return NFCWriteResult(
            success: false,
            error: 'Write failed: ${e.toString()}',
            writeTime: DateTime.now().difference(startTime),
          );
        }
      }
      
      attemptCount++;
      if (attemptCount < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _failedWrites++;
    _updateStatus(NFCStatus.enabled);
    return NFCWriteResult(
      success: false,
      error: 'Max retry attempts exceeded',
      writeTime: DateTime.now().difference(startTime),
    );
  }

  Future<NFCWriteResult> _performWrite(NFCCard sourceCard, Duration timeout) async {
    _writeCompleter = Completer<NFCWriteResult>();
    _isSessionActive = true;

    // Set timeout
    _timeoutTimer = Timer(timeout, () {
      if (!_writeCompleter!.isCompleted) {
        _writeCompleter!.complete(NFCWriteResult(
          success: false,
          error: 'Write operation timed out',
          writeTime: timeout,
        ));
      }
      _stopSession();
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) => _onCardWrite(tag, sourceCard),
        onError: (error) {
          if (!_writeCompleter!.isCompleted) {
            _writeCompleter!.complete(NFCWriteResult(
              success: false,
              error: error.message,
              writeTime: Duration.zero,
            ));
          }
        },
      );

      return await _writeCompleter!.future;
    } catch (e) {
      return NFCWriteResult(
        success: false,
        error: e.toString(),
        writeTime: Duration.zero,
      );
    } finally {
      _stopSession();
    }
  }

  Future<void> _onCardDiscovered(NfcTag tag) async {
    if (_readCompleter == null || _readCompleter!.isCompleted) return;

    try {
      final Map<String, dynamic> tagData = {};
      
      // Extract all available tag data
      tag.data.forEach((key, value) {
        if (value is Map) {
          tagData[key] = Map<String, dynamic>.from(value);
        } else {
          tagData[key] = value;
        }
      });

      // Enhanced data extraction based on card type
      await _extractEnhancedData(tag, tagData);

      final card = NFCCard.fromNFCTag(tagData: tagData);
      
      _readCompleter!.complete(NFCReadResult(
        success: true,
        card: card,
        rawData: tagData,
        readTime: Duration.zero, // Will be calculated in calling method
      ));
    } catch (e) {
      _readCompleter!.complete(NFCReadResult(
        success: false,
        error: 'Error processing card data: ${e.toString()}',
        readTime: Duration.zero,
      ));
    }
  }

  Future<void> _extractEnhancedData(NfcTag tag, Map<String, dynamic> tagData) async {
    try {
      // Try to read NDEF data if available
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        final ndefMessage = await ndef.read();
        if (ndefMessage != null) {
          tagData['ndef'] = {
            'isWritable': ndef.isWritable,
            'maxSize': ndef.maxSize,
            'cachedMessage': _parseNdefMessage(ndefMessage),
          };
        }
      }

      // Try to read MIFARE Classic data
      final mifareClassic = MifareClassic.from(tag);
      if (mifareClassic != null) {
        tagData['mifare_classic'] = {
          'blockCount': mifareClassic.blockCount,
          'sectorCount': mifareClassic.sectorCount,
          'size': mifareClassic.size,
          'type': mifareClassic.type,
        };
        
        // Try to read some sectors (with default keys)
        await _readMifareClassicSectors(mifareClassic, tagData);
      }

      // Try to read MIFARE Ultralight data
      final mifareUltralight = MifareUltralight.from(tag);
      if (mifareUltralight != null) {
        tagData['mifare_ultralight'] = {
          'type': mifareUltralight.type,
        };
        
        // Try to read pages
        await _readMifareUltralightPages(mifareUltralight, tagData);
      }

      // Extract ISO15693 data
      final iso15693 = Iso15693.from(tag);
      if (iso15693 != null) {
        tagData['iso15693'] = {
          'dsfId': iso15693.dsfId,
          'identifier': iso15693.identifier,
        };
      }

      // Extract FeliCa data
      final felica = Felica.from(tag);
      if (felica != null) {
        tagData['felica'] = {
          'currentIdm': felica.currentIdm,
          'currentSystemCode': felica.currentSystemCode,
        };
      }
    } catch (e) {
      // Log error but don't fail the entire operation
      tagData['extraction_error'] = e.toString();
    }
  }

  Map<String, dynamic> _parseNdefMessage(NdefMessage message) {
    return {
      'records': message.records.map((record) => {
        'typeNameFormat': record.typeNameFormat.index,
        'type': record.type,
        'identifier': record.identifier,
        'payload': record.payload,
      }).toList(),
    };
  }

  Future<void> _readMifareClassicSectors(MifareClassic mifareClassic, Map<String, dynamic> tagData) async {
    try {
      await mifareClassic.connect();
      
      List<List<int>> defaultKeys = [
        [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], // Default key
        [0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5], // Common key
        [0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7], // Common key
      ];

      Map<String, dynamic> sectorsData = {};
      
      for (int sector = 0; sector < mifareClassic.sectorCount && sector < 4; sector++) {
        for (List<int> key in defaultKeys) {
          try {
            bool authenticated = await mifareClassic.authenticateSectorWithKeyA(sector: sector, key: key);
            if (authenticated) {
              List<Map<String, dynamic>> blocks = [];
              int startBlock = mifareClassic.blockCountInSector(sector) * sector;
              
              for (int block = 0; block < mifareClassic.blockCountInSector(sector); block++) {
                try {
                  List<int> data = await mifareClassic.readBlock(blockIndex: startBlock + block);
                  blocks.add({
                    'index': startBlock + block,
                    'data': data,
                  });
                } catch (e) {
                  blocks.add({
                    'index': startBlock + block,
                    'error': e.toString(),
                  });
                }
              }
              
              sectorsData['sector_$sector'] = {
                'authenticated': true,
                'key_used': key,
                'blocks': blocks,
              };
              break;
            }
          } catch (e) {
            // Try next key
          }
        }
      }
      
      if (sectorsData.isNotEmpty) {
        tagData['mifare_classic']['sectors'] = sectorsData;
      }
    } catch (e) {
      tagData['mifare_classic']['read_error'] = e.toString();
    } finally {
      try {
        await mifareClassic.close();
      } catch (e) {
        // Ignore close errors
      }
    }
  }

  Future<void> _readMifareUltralightPages(MifareUltralight mifareUltralight, Map<String, dynamic> tagData) async {
    try {
      await mifareUltralight.connect();
      
      List<Map<String, dynamic>> pages = [];
      
      // Try to read first 16 pages (standard for most MIFARE Ultralight cards)
      for (int page = 0; page < 16; page++) {
        try {
          List<int> data = await mifareUltralight.readPages(pageOffset: page);
          pages.add({
            'page': page,
            'data': data,
          });
        } catch (e) {
          pages.add({
            'page': page,
            'error': e.toString(),
          });
        }
      }
      
      tagData['mifare_ultralight']['pages'] = pages;
    } catch (e) {
      tagData['mifare_ultralight']['read_error'] = e.toString();
    } finally {
      try {
        await mifareUltralight.close();
      } catch (e) {
        // Ignore close errors
      }
    }
  }

  Future<void> _onCardWrite(NfcTag tag, NFCCard sourceCard) async {
    if (_writeCompleter == null || _writeCompleter!.isCompleted) return;

    try {
      int bytesWritten = 0;

      // Check if target card is compatible with source card
      final compatibility = _checkCardCompatibility(tag, sourceCard);
      if (!compatibility['compatible']) {
        _writeCompleter!.complete(NFCWriteResult(
          success: false,
          error: compatibility['error'],
          writeTime: Duration.zero,
        ));
        return;
      }

      // Perform the actual writing based on card type
      switch (sourceCard.type) {
        case CardType.mifareClassic:
          bytesWritten = await _writeMifareClassic(tag, sourceCard);
          break;
        case CardType.mifareUltralight:
          bytesWritten = await _writeMifareUltralight(tag, sourceCard);
          break;
        case CardType.ntag:
          bytesWritten = await _writeNTAG(tag, sourceCard);
          break;
        default:
          // Try NDEF writing for other card types
          bytesWritten = await _writeNDEF(tag, sourceCard);
      }

      _writeCompleter!.complete(NFCWriteResult(
        success: true,
        writeTime: Duration.zero, // Will be calculated in calling method
        bytesWritten: bytesWritten,
      ));
    } catch (e) {
      _writeCompleter!.complete(NFCWriteResult(
        success: false,
        error: 'Error writing card: ${e.toString()}',
        writeTime: Duration.zero,
      ));
    }
  }

  Map<String, dynamic> _checkCardCompatibility(NfcTag tag, NFCCard sourceCard) {
    // Implement card compatibility checking logic
    // This is a simplified version - in reality you'd check card types, sizes, etc.
    return {'compatible': true, 'error': null};
  }

  Future<int> _writeMifareClassic(NfcTag tag, NFCCard sourceCard) async {
    final mifareClassic = MifareClassic.from(tag);
    if (mifareClassic == null) {
      throw Exception('Target card is not MIFARE Classic');
    }

    // Implement MIFARE Classic writing logic
    // This is a placeholder - actual implementation would be much more complex
    return 0;
  }

  Future<int> _writeMifareUltralight(NfcTag tag, NFCCard sourceCard) async {
    final mifareUltralight = MifareUltralight.from(tag);
    if (mifareUltralight == null) {
      throw Exception('Target card is not MIFARE Ultralight');
    }

    // Implement MIFARE Ultralight writing logic
    // This is a placeholder - actual implementation would be much more complex
    return 0;
  }

  Future<int> _writeNTAG(NfcTag tag, NFCCard sourceCard) async {
    // Implement NTAG writing logic
    // This is a placeholder - actual implementation would be much more complex
    return 0;
  }

  Future<int> _writeNDEF(NfcTag tag, NFCCard sourceCard) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) {
      throw Exception('Target card does not support NDEF');
    }

    try {
      await ndef.connect();
      
      if (!ndef.isWritable) {
        throw Exception('Target card is not writable');
      }

      // Extract NDEF data from source card
      final ndefData = sourceCard.rawData['ndef'];
      if (ndefData == null) {
        throw Exception('Source card does not contain NDEF data');
      }

      // Create NDEF message from source data
      // This is a simplified implementation
      final records = <NdefRecord>[];
      
      // Write the NDEF message
      final message = NdefMessage(records);
      await ndef.write(message);
      
      return message.byteLength;
    } finally {
      try {
        await ndef.close();
      } catch (e) {
        // Ignore close errors
      }
    }
  }

  void stopCurrentOperation() {
    _stopSession();
    if (_readCompleter != null && !_readCompleter!.isCompleted) {
      _readCompleter!.complete(NFCReadResult(
        success: false,
        error: 'Operation cancelled by user',
        readTime: Duration.zero,
      ));
    }
    if (_writeCompleter != null && !_writeCompleter!.isCompleted) {
      _writeCompleter!.complete(NFCWriteResult(
        success: false,
        error: 'Operation cancelled by user',
        writeTime: Duration.zero,
      ));
    }
  }

  void _stopSession() {
    if (_isSessionActive) {
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
      _isSessionActive = false;
      
      try {
        NfcManager.instance.stopSession();
      } catch (e) {
        // Ignore errors when stopping session
      }
    }
  }

  void _updateStatus(NFCStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  Future<bool> checkNFCEnabled() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      _updateStatus(isAvailable ? NFCStatus.enabled : NFCStatus.disabled);
      return isAvailable;
    } catch (e) {
      _updateStatus(NFCStatus.error);
      return false;
    }
  }

  void resetStatistics() {
    _successfulReads = 0;
    _failedReads = 0;
    _successfulWrites = 0;
    _failedWrites = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSession();
    super.dispose();
  }
}

// Extension methods for NFCWriteResult
extension NFCWriteResultExtension on NFCWriteResult {
  NFCWriteResult copyWith({
    bool? success,
    String? error,
    Duration? writeTime,
    int? bytesWritten,
  }) {
    return NFCWriteResult(
      success: success ?? this.success,
      error: error ?? this.error,
      writeTime: writeTime ?? this.writeTime,
      bytesWritten: bytesWritten ?? this.bytesWritten,
    );
  }
}

// Extension methods for NFCReadResult
extension NFCReadResultExtension on NFCReadResult {
  NFCReadResult copyWith({
    bool? success,
    NFCCard? card,
    String? error,
    Map<String, dynamic>? rawData,
    Duration? readTime,
  }) {
    return NFCReadResult(
      success: success ?? this.success,
      card: card ?? this.card,
      error: error ?? this.error,
      rawData: rawData ?? this.rawData,
      readTime: readTime ?? this.readTime,
    );
  }
}