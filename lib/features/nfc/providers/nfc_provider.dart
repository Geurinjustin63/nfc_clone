import 'package:flutter/foundation.dart';
import '../../../core/services/enhanced_nfc_service.dart';
import '../../../core/models/nfc_card.dart';
import '../../../core/services/database_service.dart';

class NFCProvider extends ChangeNotifier {
  final EnhancedNFCService _nfcService = EnhancedNFCService();
  final DatabaseService _database = DatabaseService();

  NFCStatus _status = NFCStatus.notAvailable;
  bool _isReading = false;
  bool _isWriting = false;
  NFCCard? _lastReadCard;
  String _statusMessage = 'Initializing NFC...';
  double _readProgress = 0.0;
  double _writeProgress = 0.0;
  Map<String, dynamic> _statistics = {};

  // Getters
  NFCStatus get status => _status;
  bool get isReading => _isReading;
  bool get isWriting => _isWriting;
  bool get isAvailable => _nfcService.isAvailable;
  bool get isEnabled => _nfcService.isEnabled;
  bool get isSessionActive => _nfcService.isSessionActive;
  NFCCard? get lastReadCard => _lastReadCard;
  String get statusMessage => _statusMessage;
  double get readProgress => _readProgress;
  double get writeProgress => _writeProgress;
  Map<String, dynamic> get statistics => _statistics;

  // Statistics getters
  int get successfulReads => _nfcService.successfulReads;
  int get failedReads => _nfcService.failedReads;
  int get successfulWrites => _nfcService.successfulWrites;
  int get failedWrites => _nfcService.failedWrites;
  double get readSuccessRate => _nfcService.readSuccessRate;

  Future<void> initialize() async {
    try {
      _updateStatus(NFCStatus.notAvailable, 'Checking NFC availability...');
      
      final isInitialized = await _nfcService.initialize();
      
      if (isInitialized) {
        _updateStatus(NFCStatus.enabled, 'NFC is ready');
      } else {
        _updateStatus(NFCStatus.notAvailable, 'NFC not available on this device');
      }
      
      _loadStatistics();
    } catch (e) {
      _updateStatus(NFCStatus.error, 'Failed to initialize NFC: ${e.toString()}');
    }
  }

  Future<NFCReadResult> readCard({
    Duration? timeout,
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    if (!_nfcService.isAvailable) {
      return NFCReadResult(
        success: false,
        error: 'NFC not available',
        readTime: Duration.zero,
      );
    }

    _isReading = true;
    _readProgress = 0.0;
    _updateStatus(NFCStatus.reading, 'Place your NFC card near the device...');

    try {
      // Simulate progress updates
      _startProgressSimulation(isReading: true);

      final result = await _nfcService.readCard(
        timeout: timeout ?? const Duration(seconds: 30),
        enableRetry: enableRetry,
        maxRetries: maxRetries,
      );

      _stopProgressSimulation();

      if (result.success && result.card != null) {
        _lastReadCard = result.card!;
        await _saveCardToDatabase(result.card!);
        _updateStatus(NFCStatus.enabled, 'Card read successfully');
      } else {
        _updateStatus(NFCStatus.error, result.error ?? 'Failed to read card');
      }

      return result;
    } catch (e) {
      _stopProgressSimulation();
      _updateStatus(NFCStatus.error, 'Error reading card: ${e.toString()}');
      return NFCReadResult(
        success: false,
        error: e.toString(),
        readTime: Duration.zero,
      );
    } finally {
      _isReading = false;
      _readProgress = 0.0;
      notifyListeners();
    }
  }

  Future<NFCWriteResult> writeCard({
    required NFCCard sourceCard,
    Duration? timeout,
    bool enableRetry = true,
    int maxRetries = 3,
  }) async {
    if (!_nfcService.isAvailable) {
      return NFCWriteResult(
        success: false,
        error: 'NFC not available',
        writeTime: Duration.zero,
      );
    }

    _isWriting = true;
    _writeProgress = 0.0;
    _updateStatus(NFCStatus.writing, 'Place the target card near the device...');

    try {
      // Simulate progress updates
      _startProgressSimulation(isWriting: true);

      final result = await _nfcService.writeCard(
        sourceCard: sourceCard,
        timeout: timeout ?? const Duration(seconds: 30),
        enableRetry: enableRetry,
        maxRetries: maxRetries,
      );

      _stopProgressSimulation();

      if (result.success) {
        // Create a cloned card record
        await _saveClonedCard(sourceCard, result.bytesWritten);
        _updateStatus(NFCStatus.enabled, 'Card cloned successfully');
      } else {
        _updateStatus(NFCStatus.error, result.error ?? 'Failed to clone card');
      }

      return result;
    } catch (e) {
      _stopProgressSimulation();
      _updateStatus(NFCStatus.error, 'Error cloning card: ${e.toString()}');
      return NFCWriteResult(
        success: false,
        error: e.toString(),
        writeTime: Duration.zero,
      );
    } finally {
      _isWriting = false;
      _writeProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> _saveCardToDatabase(NFCCard card) async {
    try {
      // Check if card already exists (by UID)
      final existingCards = await _database.getAllCards();
      final existing = existingCards.firstWhere(
        (c) => listEquals(c.uid, card.uid),
        orElse: () => card, // Return the new card if no existing one found
      );

      if (existing.id != card.id) {
        // Update existing card
        final updatedCard = existing.copyWith(
          readCount: existing.readCount + 1,
          updatedAt: DateTime.now(),
        );
        await _database.updateCard(updatedCard);
        _lastReadCard = updatedCard;
      } else {
        // Save new card
        await _database.insertCard(card);
        _lastReadCard = card;
      }
    } catch (e) {
      debugPrint('Failed to save card to database: $e');
    }
  }

  Future<void> _saveClonedCard(NFCCard sourceCard, int bytesWritten) async {
    try {
      final clonedCard = NFCCard(
        name: '${sourceCard.name} (Clone)',
        description: 'Cloned from ${sourceCard.name}',
        type: sourceCard.type,
        rawData: Map<String, dynamic>.from(sourceCard.rawData),
        uid: List<int>.from(sourceCard.uid),
        standard: sourceCard.standard,
        isCloned: true,
        sourceCardId: sourceCard.id,
        metadata: {
          ...sourceCard.metadata,
          'cloned_at': DateTime.now().toIso8601String(),
          'bytes_written': bytesWritten,
          'cloning_successful': true,
        },
      );

      await _database.insertCard(clonedCard);
    } catch (e) {
      debugPrint('Failed to save cloned card: $e');
    }
  }

  void _startProgressSimulation({bool isReading = false, bool isWriting = false}) {
    // Simulate realistic progress for better UX
    final duration = isReading ? const Duration(milliseconds: 100) : const Duration(milliseconds: 150);
    
    Stream.periodic(duration, (tick) {
      if (isReading && _isReading) {
        _readProgress = (tick * 0.1).clamp(0.0, 0.9);
      } else if (isWriting && _isWriting) {
        _writeProgress = (tick * 0.08).clamp(0.0, 0.9);
      }
      notifyListeners();
      return tick;
    }).take(9).listen(null);
  }

  void _stopProgressSimulation() {
    if (_isReading) {
      _readProgress = 1.0;
    }
    if (_isWriting) {
      _writeProgress = 1.0;
    }
    notifyListeners();
  }

  Future<void> stopCurrentOperation() async {
    try {
      _nfcService.stopCurrentOperation();
      _isReading = false;
      _isWriting = false;
      _readProgress = 0.0;
      _writeProgress = 0.0;
      _updateStatus(NFCStatus.enabled, 'Operation cancelled');
    } catch (e) {
      _updateStatus(NFCStatus.error, 'Failed to stop operation: ${e.toString()}');
    }
  }

  Future<bool> checkNFCStatus() async {
    try {
      final isEnabled = await _nfcService.checkNFCEnabled();
      if (isEnabled) {
        _updateStatus(NFCStatus.enabled, 'NFC is ready');
      } else {
        _updateStatus(NFCStatus.disabled, 'NFC is disabled. Please enable it in system settings.');
      }
      return isEnabled;
    } catch (e) {
      _updateStatus(NFCStatus.error, 'Failed to check NFC status: ${e.toString()}');
      return false;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      _statistics = {
        'total_reads': successfulReads + failedReads,
        'successful_reads': successfulReads,
        'failed_reads': failedReads,
        'total_writes': successfulWrites + failedWrites,
        'successful_writes': successfulWrites,
        'failed_writes': failedWrites,
        'read_success_rate': readSuccessRate,
        'write_success_rate': (successfulWrites + failedWrites) == 0 
            ? 0.0 
            : successfulWrites / (successfulWrites + failedWrites),
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load NFC statistics: $e');
    }
  }

  void resetStatistics() {
    _nfcService.resetStatistics();
    _loadStatistics();
  }

  // Card type detection helpers
  String getCardTypeDisplayName(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return 'MIFARE Classic';
      case CardType.mifareUltralight:
        return 'MIFARE Ultralight';
      case CardType.ntag:
        return 'NTAG';
      case CardType.desfire:
        return 'DESFire';
      case CardType.felica:
        return 'FeliCa';
      case CardType.iso15693:
        return 'ISO 15693';
      case CardType.iso14443A:
        return 'ISO 14443 Type A';
      case CardType.iso14443B:
        return 'ISO 14443 Type B';
      case CardType.unknown:
        return 'Unknown';
    }
  }

  String getCardTypeDescription(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return 'A widely used contactless smart card with 1KB or 4KB memory';
      case CardType.mifareUltralight:
        return 'A low-cost contactless smart card with 512 bits of memory';
      case CardType.ntag:
        return 'NFC Forum Type 2 tag with NDEF data structure support';
      case CardType.desfire:
        return 'Advanced contactless smart card with strong security features';
      case CardType.felica:
        return 'Sony\'s contactless RFID smart card system';
      case CardType.iso15693:
        return 'Long-range RFID standard operating at 13.56 MHz';
      case CardType.iso14443A:
      case CardType.iso14443B:
        return 'Proximity card standard for contactless smart cards';
      case CardType.unknown:
        return 'Card type could not be determined';
    }
  }

  // Demo data for testing without physical NFC
  Future<NFCReadResult> readDemoCard() async {
    _isReading = true;
    _readProgress = 0.0;
    _updateStatus(NFCStatus.reading, 'Loading demo card data...');

    try {
      _startProgressSimulation(isReading: true);
      
      // Simulate realistic read time
      await Future.delayed(const Duration(seconds: 2));
      
      _stopProgressSimulation();

      final demoCard = NFCCard(
        name: 'Demo Card ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Demonstration card for testing purposes',
        type: CardType.mifareClassic,
        rawData: {
          'nfca': {
            'identifier': [0x04, 0x68, 0x95, 0x71, 0xFA, 0x5C, 0x64],
            'atqa': [0x00, 0x04],
            'sak': 0x08,
          },
          'mifare_classic': {
            'type': 1,
            'size': 1024,
            'sectorCount': 16,
            'blockCount': 64,
          },
          'demo_data': true,
          'generated_at': DateTime.now().toIso8601String(),
        },
        uid: [0x04, 0x68, 0x95, 0x71, 0xFA, 0x5C, 0x64],
        standard: 'ISO 14443 Type A',
        metadata: {
          'demo_mode': true,
          'source': 'nfc_provider_demo',
        },
      );

      _lastReadCard = demoCard;
      await _saveCardToDatabase(demoCard);
      _updateStatus(NFCStatus.enabled, 'Demo card loaded successfully');

      return NFCReadResult(
        success: true,
        card: demoCard,
        rawData: demoCard.rawData,
        readTime: const Duration(seconds: 2),
      );
    } catch (e) {
      _stopProgressSimulation();
      _updateStatus(NFCStatus.error, 'Failed to load demo card: ${e.toString()}');
      return NFCReadResult(
        success: false,
        error: e.toString(),
        readTime: Duration.zero,
      );
    } finally {
      _isReading = false;
      _readProgress = 0.0;
      notifyListeners();
    }
  }

  Future<NFCWriteResult> cloneDemoCard(NFCCard sourceCard) async {
    _isWriting = true;
    _writeProgress = 0.0;
    _updateStatus(NFCStatus.writing, 'Simulating card cloning...');

    try {
      _startProgressSimulation(isWriting: true);
      
      // Simulate realistic write time
      await Future.delayed(const Duration(seconds: 3));
      
      _stopProgressSimulation();

      await _saveClonedCard(sourceCard, 1024); // Simulate 1KB written
      _updateStatus(NFCStatus.enabled, 'Demo card cloned successfully');

      return NFCWriteResult(
        success: true,
        writeTime: const Duration(seconds: 3),
        bytesWritten: 1024,
      );
    } catch (e) {
      _stopProgressSimulation();
      _updateStatus(NFCStatus.error, 'Failed to clone demo card: ${e.toString()}');
      return NFCWriteResult(
        success: false,
        error: e.toString(),
        writeTime: Duration.zero,
      );
    } finally {
      _isWriting = false;
      _writeProgress = 0.0;
      notifyListeners();
    }
  }

  void _updateStatus(NFCStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _nfcService.dispose();
    super.dispose();
  }
}