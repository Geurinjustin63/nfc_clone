import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Box? _settingsBox;
  Box? _cacheBox;
  Box<String>? _secureBox;
  String? _encryptionKey;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Generate or retrieve encryption key
    _encryptionKey = await _getOrCreateEncryptionKey();
    
    // Open Hive boxes
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _cacheBox = await Hive.openBox(AppConstants.cacheBox);
    
    // Open encrypted box for sensitive data
    final encryptionKeyBytes = _deriveKeyFromString(_encryptionKey!);
    _secureBox = await Hive.openBox<String>(
      AppConstants.secureBox,
      encryptionCipher: HiveAesCipher(encryptionKeyBytes),
    );
  }

  // Encryption key management
  Future<String> _getOrCreateEncryptionKey() async {
    String? existingKey = await _secureStorage.read(key: AppConstants.encryptionKey);
    
    if (existingKey != null) {
      return existingKey;
    }
    
    // Generate new encryption key
    final random = Random.secure();
    final bytes = Uint8List(32); // 256-bit key
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    final newKey = base64Encode(bytes);
    await _secureStorage.write(key: AppConstants.encryptionKey, value: newKey);
    
    return newKey;
  }

  Uint8List _deriveKeyFromString(String keyString) {
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  // Secure storage operations (for highly sensitive data)
  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearAllSecure() async {
    await _secureStorage.deleteAll();
  }

  // Encrypted local storage (for sensitive app data)
  Future<void> storeEncrypted(String key, dynamic value) async {
    if (_secureBox == null) throw Exception('Secure storage not initialized');
    
    final jsonString = jsonEncode(value);
    final encrypted = _encrypt(jsonString);
    await _secureBox!.put(key, encrypted);
  }

  Future<T?> getEncrypted<T>(String key) async {
    if (_secureBox == null) throw Exception('Secure storage not initialized');
    
    final encrypted = _secureBox!.get(key);
    if (encrypted == null) return null;
    
    try {
      final decrypted = _decrypt(encrypted);
      final decoded = jsonDecode(decrypted);
      return decoded as T?;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteEncrypted(String key) async {
    if (_secureBox == null) throw Exception('Secure storage not initialized');
    await _secureBox!.delete(key);
  }

  // Regular storage operations (for non-sensitive data)
  Future<void> store(String key, dynamic value) async {
    if (_settingsBox == null) throw Exception('Settings storage not initialized');
    await _settingsBox!.put(key, value);
  }

  T? get<T>(String key, {T? defaultValue}) {
    if (_settingsBox == null) throw Exception('Settings storage not initialized');
    return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> delete(String key) async {
    if (_settingsBox == null) throw Exception('Settings storage not initialized');
    await _settingsBox!.delete(key);
  }

  // Cache operations (for temporary data)
  Future<void> cache(String key, dynamic value, {Duration? expiry}) async {
    if (_cacheBox == null) throw Exception('Cache storage not initialized');
    
    final cacheEntry = {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    
    await _cacheBox!.put(key, cacheEntry);
  }

  T? getCache<T>(String key) {
    if (_cacheBox == null) throw Exception('Cache storage not initialized');
    
    final cacheEntry = _cacheBox!.get(key);
    if (cacheEntry == null) return null;
    
    // Check if cache entry has expired
    if (cacheEntry['expiry'] != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        cacheEntry['timestamp'] + cacheEntry['expiry']
      );
      
      if (DateTime.now().isAfter(expiry)) {
        _cacheBox!.delete(key); // Remove expired entry
        return null;
      }
    }
    
    return cacheEntry['value'] as T?;
  }

  Future<void> clearCache() async {
    if (_cacheBox == null) throw Exception('Cache storage not initialized');
    await _cacheBox!.clear();
  }

  Future<void> clearExpiredCache() async {
    if (_cacheBox == null) throw Exception('Cache storage not initialized');
    
    final keysToDelete = <String>[];
    
    for (final key in _cacheBox!.keys) {
      final cacheEntry = _cacheBox!.get(key);
      if (cacheEntry != null && cacheEntry['expiry'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          cacheEntry['timestamp'] + cacheEntry['expiry']
        );
        
        if (DateTime.now().isAfter(expiry)) {
          keysToDelete.add(key);
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _cacheBox!.delete(key);
    }
  }

  // Authentication related storage
  Future<void> storeBiometricEnabled(bool enabled) async {
    await storeSecure(AppConstants.biometricEnabled, enabled.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final value = await getSecure(AppConstants.biometricEnabled);
    return value == 'true';
  }

  Future<void> storeSessionToken(String token) async {
    await storeSecure(AppConstants.sessionToken, token);
  }

  Future<String?> getSessionToken() async {
    return await getSecure(AppConstants.sessionToken);
  }

  Future<void> storeLastAuthTime(DateTime time) async {
    await storeSecure(AppConstants.lastAuthTime, time.toIso8601String());
  }

  Future<DateTime?> getLastAuthTime() async {
    final timeString = await getSecure(AppConstants.lastAuthTime);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Settings related storage
  Future<void> storeThemeMode(String mode) async {
    await store(AppConstants.themeMode, mode);
  }

  String getThemeMode() {
    return get<String>(AppConstants.themeMode, defaultValue: 'system') ?? 'system';
  }

  Future<void> storeTextScaleFactor(double factor) async {
    await store(AppConstants.textScaleFactor, factor);
  }

  double getTextScaleFactor() {
    return get<double>(AppConstants.textScaleFactor, defaultValue: 1.0) ?? 1.0;
  }

  Future<void> storeAutoLockDuration(int minutes) async {
    await store(AppConstants.autoLockDuration, minutes);
  }

  int getAutoLockDuration() {
    return get<int>(AppConstants.autoLockDuration, defaultValue: 15) ?? 15;
  }

  Future<void> storeHapticFeedback(bool enabled) async {
    await store(AppConstants.hapticFeedback, enabled);
  }

  bool getHapticFeedback() {
    return get<bool>(AppConstants.hapticFeedback, defaultValue: true) ?? true;
  }

  Future<void> storeSoundEnabled(bool enabled) async {
    await store(AppConstants.soundEnabled, enabled);
  }

  bool getSoundEnabled() {
    return get<bool>(AppConstants.soundEnabled, defaultValue: true) ?? true;
  }

  Future<void> storeFirstRun(bool isFirstRun) async {
    await store(AppConstants.firstRun, isFirstRun);
  }

  bool getFirstRun() {
    return get<bool>(AppConstants.firstRun, defaultValue: true) ?? true;
  }

  // Card data encryption/decryption
  Future<String> encryptCardData(Map<String, dynamic> cardData) async {
    final jsonString = jsonEncode(cardData);
    return _encrypt(jsonString);
  }

  Future<Map<String, dynamic>> decryptCardData(String encryptedData) async {
    final decrypted = _decrypt(encryptedData);
    return jsonDecode(decrypted);
  }

  // Internal encryption/decryption methods
  String _encrypt(String data) {
    if (_encryptionKey == null) throw Exception('Encryption key not available');
    
    final key = _deriveKeyFromString(_encryptionKey!);
    final bytes = utf8.encode(data);
    
    // Simple XOR encryption with key rotation (for demonstration)
    // In production, use proper encryption like AES
    final encrypted = <int>[];
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ key[i % key.length]);
    }
    
    return base64Encode(encrypted);
  }

  String _decrypt(String encryptedData) {
    if (_encryptionKey == null) throw Exception('Encryption key not available');
    
    final key = _deriveKeyFromString(_encryptionKey!);
    final encrypted = base64Decode(encryptedData);
    
    // Simple XOR decryption with key rotation (for demonstration)
    // In production, use proper decryption like AES
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ key[i % key.length]);
    }
    
    return utf8.decode(decrypted);
  }

  // Data export/import with encryption
  Future<String> exportEncryptedData(List<String> keys) async {
    final exportData = <String, dynamic>{};
    
    for (final key in keys) {
      final value = await getEncrypted(key);
      if (value != null) {
        exportData[key] = value;
      }
    }
    
    return _encrypt(jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'data': exportData,
    }));
  }

  Future<bool> importEncryptedData(String encryptedData) async {
    try {
      final decrypted = _decrypt(encryptedData);
      final importData = jsonDecode(decrypted);
      
      final data = importData['data'] as Map<String, dynamic>;
      
      for (final entry in data.entries) {
        await storeEncrypted(entry.key, entry.value);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return {
      'settings_keys': _settingsBox?.length ?? 0,
      'cache_keys': _cacheBox?.length ?? 0,
      'secure_keys': _secureBox?.length ?? 0,
      'settings_size_bytes': _calculateBoxSize(_settingsBox),
      'cache_size_bytes': _calculateBoxSize(_cacheBox),
      'secure_size_bytes': _calculateBoxSize(_secureBox),
    };
  }

  int _calculateBoxSize(Box? box) {
    if (box == null) return 0;
    
    int totalSize = 0;
    for (final value in box.values) {
      totalSize += value.toString().length;
    }
    return totalSize;
  }

  // Cleanup and maintenance
  Future<void> performMaintenance() async {
    await clearExpiredCache();
    await _compactBoxes();
  }

  Future<void> _compactBoxes() async {
    await _settingsBox?.compact();
    await _cacheBox?.compact();
    await _secureBox?.compact();
  }

  Future<void> clearAllData() async {
    await clearCache();
    await _settingsBox?.clear();
    await _secureBox?.clear();
    await clearAllSecure();
  }

  Future<void> close() async {
    await _settingsBox?.close();
    await _cacheBox?.close();
    await _secureBox?.close();
  }

  // Backup and restore
  Future<Map<String, dynamic>> createBackup() async {
    final settingsData = Map<String, dynamic>.from(_settingsBox?.toMap() ?? {});
    final cacheData = Map<String, dynamic>.from(_cacheBox?.toMap() ?? {});
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': AppConstants.appVersion,
      'settings': settingsData,
      'cache': cacheData,
      // Note: Secure data is intentionally not included in backups
    };
  }

  Future<bool> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      // Validate backup format
      if (!backup.containsKey('timestamp') || !backup.containsKey('version')) {
        return false;
      }
      
      // Restore settings
      if (backup.containsKey('settings')) {
        final settings = backup['settings'] as Map<String, dynamic>;
        for (final entry in settings.entries) {
          await store(entry.key, entry.value);
        }
      }
      
      // Note: Cache data is not restored as it's temporary
      // Note: Secure data is not restored for security reasons
      
      return true;
    } catch (e) {
      return false;
    }
  }
}