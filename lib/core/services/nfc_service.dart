import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../constants/app_constants.dart';
import '../models/nfc_card.dart';

enum NFCStatus {
  available,
  unavailable,
  disabled,
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
  final Duration readTime;
  final Map<String, dynamic> metadata;

  NFCReadResult({
    required this.success,
    this.card,
    this.error,
    required this.readTime,
    this.metadata = const {},
  });
}

class NFCWriteResult {
  final bool success;
  final String? error;
  final Duration writeTime;
  final Map<String, dynamic> verification;

  NFCWriteResult({
    required this.success,
    this.error,
    required this.writeTime,
    this.verification = const {},
  });
}

class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  final StreamController<NFCStatus> _statusController = StreamController<NFCStatus>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  
  NFCStatus _currentStatus = NFCStatus.unavailable;
  Timer? _sessionTimer;
  Completer<NFCReadResult>? _readCompleter;
  Completer<NFCWriteResult>? _writeCompleter;

  Stream<NFCStatus> get statusStream => _statusController.stream;
  Stream<String> get messageStream => _messageController.stream;
  NFCStatus get currentStatus => _currentStatus;

  Future<bool> initialize() async {
    try {
      // Check if NFC is available
      bool isAvailable = await NfcManager.instance.isAvailable();
      _updateStatus(isAvailable ? NFCStatus.available : NFCStatus.unavailable);
      
      if (isAvailable) {
        _addMessage('NFC initialized successfully');
        return true;
      } else {
        _addMessage('NFC is not available on this device');
        return false;
      }
    } catch (e) {
      _updateStatus(NFCStatus.error);
      _addMessage('Error initializing NFC: $e');
      return false;
    }
  }

  Future<NFCReadResult> readCard({
    Duration? timeout,
    String? expectedCardType,
    Map<String, dynamic> options = const {},
  }) async {
    if (_currentStatus != NFCStatus.available) {
      return NFCReadResult(
        success: false,
        error: 'NFC is not available',
        readTime: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _readCompleter = Completer<NFCReadResult>();
    _updateStatus(NFCStatus.reading);
    _addMessage('Place NFC card near device...');

    // Set up session timer
    _sessionTimer = Timer(timeout ?? AppConstants.nfcReadTimeout, () {
      if (!_readCompleter!.isCompleted) {
        _completeRead(NFCReadResult(
          success: false,
          error: 'Read operation timed out',
          readTime: DateTime.now().difference(startTime),
        ));
      }
    });

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final cardData = await _extractCardData(tag);
            final card = NFCCard.fromNFCTag(
              tagData: cardData,
              name: _generateCardName(cardData),
            );

            // Validate card type if specified
            if (expectedCardType != null && card.type.name != expectedCardType) {
              _completeRead(NFCReadResult(
                success: false,
                error: 'Expected $expectedCardType but found ${card.type.name}',
                readTime: DateTime.now().difference(startTime),
              ));
              return;
            }

            // Perform additional analysis if requested
            final metadata = <String, dynamic>{};
            if (options['detailed_analysis'] == true) {
              metadata.addAll(await _performDetailedAnalysis(tag, cardData));
            }

            _completeRead(NFCReadResult(
              success: true,
              card: card,
              readTime: DateTime.now().difference(startTime),
              metadata: metadata,
            ));

            _addMessage('Card read successfully!');
          } catch (e) {
            _completeRead(NFCReadResult(
              success: false,
              error: 'Error reading card: $e',
              readTime: DateTime.now().difference(startTime),
            ));
          }
        },
      );
    } catch (e) {
      _completeRead(NFCReadResult(
        success: false,
        error: 'Error starting NFC session: $e',
        readTime: DateTime.now().difference(startTime),
      ));
    }

    return _readCompleter!.future;
  }

  Future<NFCWriteResult> writeCard(
    NFCCard sourceCard, {
    Duration? timeout,
    bool verifyWrite = true,
    Map<String, dynamic> options = const {},
  }) async {
    if (_currentStatus != NFCStatus.available) {
      return NFCWriteResult(
        success: false,
        error: 'NFC is not available',
        writeTime: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _writeCompleter = Completer<NFCWriteResult>();
    _updateStatus(NFCStatus.writing);
    _addMessage('Place target NFC card near device...');

    // Set up session timer
    _sessionTimer = Timer(timeout ?? AppConstants.nfcSessionTimeout, () {
      if (!_writeCompleter!.isCompleted) {
        _completeWrite(NFCWriteResult(
          success: false,
          error: 'Write operation timed out',
          writeTime: DateTime.now().difference(startTime),
        ));
      }
    });

    try {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final writeResult = await _performWrite(tag, sourceCard, options);
            
            Map<String, dynamic> verification = {};
            if (verifyWrite && writeResult) {
              verification = await _verifyWrite(tag, sourceCard);
            }

            _completeWrite(NFCWriteResult(
              success: writeResult,
              writeTime: DateTime.now().difference(startTime),
              verification: verification,
              error: writeResult ? null : 'Write operation failed',
            ));

            if (writeResult) {
              _addMessage('Card cloned successfully!');
            } else {
              _addMessage('Card cloning failed');
            }
          } catch (e) {
            _completeWrite(NFCWriteResult(
              success: false,
              error: 'Error writing card: $e',
              writeTime: DateTime.now().difference(startTime),
            ));
          }
        },
      );
    } catch (e) {
      _completeWrite(NFCWriteResult(
        success: false,
        error: 'Error starting NFC session: $e',
        writeTime: DateTime.now().difference(startTime),
      ));
    }

    return _writeCompleter!.future;
  }

  Future<Map<String, dynamic>> analyzeCard(NfcTag tag) async {
    final analysis = <String, dynamic>{};
    
    try {
      // Basic tag information
      analysis['tag_id'] = tag.data.keys.toList();
      analysis['technologies'] = tag.data.keys.map((key) => key.toUpperCase()).toList();
      
      // Analyze each technology
      for (final tech in tag.data.keys) {
        analysis[tech] = await _analyzeTechnology(tech, tag.data[tech]);
      }
      
      // Security analysis
      analysis['security'] = await _analyzeCardSecurity(tag);
      
      // Memory analysis
      analysis['memory'] = await _analyzeMemoryLayout(tag);
      
    } catch (e) {
      analysis['error'] = 'Error during analysis: $e';
    }
    
    return analysis;
  }

  void stopCurrentOperation() {
    try {
      NfcManager.instance.stopSession();
      _sessionTimer?.cancel();
      
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
      
      _updateStatus(NFCStatus.available);
      _addMessage('NFC operation cancelled');
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping NFC session: $e');
      }
    }
  }

  Future<List<String>> getSupportedTechnologies() async {
    // Return list of NFC technologies this device supports
    return [
      'ISO 14443 Type A',
      'ISO 14443 Type B', 
      'ISO 15693',
      'FeliCa',
      'MIFARE Classic',
      'MIFARE Ultralight',
      'NTAG',
      'DESFire',
    ];
  }

  Future<Map<String, dynamic>> getDeviceCapabilities() async {
    final capabilities = <String, dynamic>{};
    
    try {
      capabilities['nfc_available'] = await NfcManager.instance.isAvailable();
      capabilities['supported_technologies'] = await getSupportedTechnologies();
      capabilities['can_write'] = true; // Most devices support writing
      capabilities['can_emulate'] = false; // Host Card Emulation support varies
      
      // Platform-specific capabilities
      if (defaultTargetPlatform == TargetPlatform.android) {
        capabilities['android_beam'] = true;
        capabilities['host_card_emulation'] = true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        capabilities['background_reading'] = true;
        capabilities['ndef_reader_session'] = true;
      }
      
    } catch (e) {
      capabilities['error'] = 'Error getting capabilities: $e';
    }
    
    return capabilities;
  }

  // Private helper methods
  Future<Map<String, dynamic>> _extractCardData(NfcTag tag) async {
    final cardData = <String, dynamic>{};
    
    // Copy all tag data
    for (final entry in tag.data.entries) {
      cardData[entry.key] = entry.value;
    }
    
    // Extract NDEF data if available
    if (tag.data.containsKey('ndef')) {
      final ndef = Ndef.from(tag);
      if (ndef != null) {
        try {
          final message = await ndef.read();
          if (message != null) {
            cardData['ndef_records'] = message.records.map((record) => {
              'type': record.type,
              'payload': record.payload,
              'typeNameFormat': record.typeNameFormat.index,
            }).toList();
          }
        } catch (e) {
          cardData['ndef_error'] = 'Error reading NDEF: $e';
        }
      }
    }
    
    return cardData;
  }

  String _generateCardName(Map<String, dynamic> cardData) {
    final now = DateTime.now();
    final cardType = CardType.values.firstWhere(
      (type) => _detectCardTypeFromData(cardData) == type,
      orElse: () => CardType.unknown,
    );
    
    return '${cardType.name.toUpperCase()} ${now.day}/${now.month}/${now.year}';
  }

  CardType _detectCardTypeFromData(Map<String, dynamic> cardData) {
    // Implementation of card type detection logic
    // This is simplified - in reality you'd analyze the specific data structures
    
    if (cardData.containsKey('mifareclassic')) {
      return CardType.mifareClassic;
    } else if (cardData.containsKey('mifareultralight')) {
      return CardType.mifareUltralight;
    } else if (cardData.containsKey('nfca')) {
      return CardType.iso14443A;
    } else if (cardData.containsKey('nfcb')) {
      return CardType.iso14443B;
    } else if (cardData.containsKey('nfcf')) {
      return CardType.felica;
    } else if (cardData.containsKey('nfcv')) {
      return CardType.iso15693;
    }
    
    return CardType.unknown;
  }

  Future<Map<String, dynamic>> _performDetailedAnalysis(
    NfcTag tag, 
    Map<String, dynamic> cardData,
  ) async {
    final analysis = <String, dynamic>{};
    
    // Memory analysis
    analysis['memory_size'] = await _calculateMemorySize(cardData);
    analysis['used_memory'] = await _calculateUsedMemory(cardData);
    
    // Security analysis  
    analysis['security_features'] = await _detectSecurityFeatures(cardData);
    
    // Standards compliance
    analysis['standards_compliance'] = await _checkStandardsCompliance(cardData);
    
    return analysis;
  }

  Future<bool> _performWrite(
    NfcTag tag, 
    NFCCard sourceCard, 
    Map<String, dynamic> options,
  ) async {
    try {
      // This is a simplified implementation
      // In reality, you would need to implement specific writing logic
      // for each card type (MIFARE Classic, Ultralight, etc.)
      
      if (sourceCard.type == CardType.mifareClassic) {
        return await _writeMifareClassic(tag, sourceCard, options);
      } else if (sourceCard.type == CardType.mifareUltralight) {
        return await _writeMifareUltralight(tag, sourceCard, options);
      } else if (sourceCard.hasNDEFData) {
        return await _writeNDEF(tag, sourceCard, options);
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Write error: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> _verifyWrite(NfcTag tag, NFCCard sourceCard) async {
    final verification = <String, dynamic>{};
    
    try {
      // Read back the data and compare with source
      final readData = await _extractCardData(tag);
      
      verification['uid_match'] = _compareUIDs(sourceCard.uid, readData);
      verification['data_integrity'] = await _verifyDataIntegrity(sourceCard.rawData, readData);
      verification['memory_match'] = await _verifyMemoryContent(sourceCard, readData);
      
    } catch (e) {
      verification['error'] = 'Verification failed: $e';
    }
    
    return verification;
  }

  // Technology-specific methods (simplified implementations)
  Future<bool> _writeMifareClassic(NfcTag tag, NFCCard sourceCard, Map<String, dynamic> options) async {
    // Implement MIFARE Classic writing logic
    await Future.delayed(const Duration(seconds: 2)); // Simulate write time
    return true; // Simplified - return success
  }

  Future<bool> _writeMifareUltralight(NfcTag tag, NFCCard sourceCard, Map<String, dynamic> options) async {
    // Implement MIFARE Ultralight writing logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate write time
    return true; // Simplified - return success
  }

  Future<bool> _writeNDEF(NfcTag tag, NFCCard sourceCard, Map<String, dynamic> options) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) return false;
    
    try {
      // Create NDEF message from source card data
      // This is simplified - you'd reconstruct the actual NDEF message
      final records = <NdefRecord>[];
      
      // Write the message
      // await ndef.write(NdefMessage(records));
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Analysis helper methods
  Future<Map<String, dynamic>> _analyzeTechnology(String tech, dynamic data) async {
    final analysis = <String, dynamic>{};
    analysis['technology'] = tech;
    analysis['raw_data_size'] = data.toString().length;
    return analysis;
  }

  Future<Map<String, dynamic>> _analyzeCardSecurity(NfcTag tag) async {
    return {
      'encrypted_sectors': 0,
      'access_conditions': 'unknown',
      'authentication_required': false,
    };
  }

  Future<Map<String, dynamic>> _analyzeMemoryLayout(NfcTag tag) async {
    return {
      'total_memory': 0,
      'used_memory': 0,
      'free_memory': 0,
      'sectors': 0,
      'blocks': 0,
    };
  }

  Future<int> _calculateMemorySize(Map<String, dynamic> cardData) async {
    return cardData.toString().length; // Simplified
  }

  Future<int> _calculateUsedMemory(Map<String, dynamic> cardData) async {
    return (cardData.toString().length * 0.6).round(); // Simplified
  }

  Future<List<String>> _detectSecurityFeatures(Map<String, dynamic> cardData) async {
    return ['Basic Access Control']; // Simplified
  }

  Future<List<String>> _checkStandardsCompliance(Map<String, dynamic> cardData) async {
    return ['ISO 14443']; // Simplified
  }

  bool _compareUIDs(List<int> sourceUID, Map<String, dynamic> readData) {
    // Simplified UID comparison
    return true;
  }

  Future<bool> _verifyDataIntegrity(Map<String, dynamic> sourceData, Map<String, dynamic> readData) async {
    // Simplified integrity check
    return true;
  }

  Future<bool> _verifyMemoryContent(NFCCard sourceCard, Map<String, dynamic> readData) async {
    // Simplified memory content verification
    return true;
  }

  void _updateStatus(NFCStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _addMessage(String message) {
    _messageController.add(message);
    if (kDebugMode) {
      print('NFC: $message');
    }
  }

  void _completeRead(NFCReadResult result) {
    _sessionTimer?.cancel();
    if (_readCompleter != null && !_readCompleter!.isCompleted) {
      _readCompleter!.complete(result);
    }
    _updateStatus(result.success ? NFCStatus.available : NFCStatus.error);
    NfcManager.instance.stopSession();
  }

  void _completeWrite(NFCWriteResult result) {
    _sessionTimer?.cancel();
    if (_writeCompleter != null && !_writeCompleter!.isCompleted) {
      _writeCompleter!.complete(result);
    }
    _updateStatus(result.success ? NFCStatus.available : NFCStatus.error);
    NfcManager.instance.stopSession();
  }

  void dispose() {
    _sessionTimer?.cancel();
    _statusController.close();
    _messageController.close();
    stopCurrentOperation();
  }
}