import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Box? _settingsBox;
  Box? _cacheBox;
  String? _encryptionKey;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Initialize encryption key
    await _initializeEncryptionKey();
    
    // Open Hive boxes
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _cacheBox = await Hive.openBox(AppConstants.cacheBox);
  }

  Future<void> _initializeEncryptionKey() async {
    try {
      _encryptionKey = await _secureStorage.read(key: AppConstants.encryptionKey);
      
      if (_encryptionKey == null) {
        _encryptionKey = _generateEncryptionKey();
        await _secureStorage.write(
          key: AppConstants.encryptionKey,
          value: _encryptionKey,
        );
      }
    } catch (e) {
      // Fallback: generate a new key
      _encryptionKey = _generateEncryptionKey();
    }
  }

  String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // Secure storage operations (encrypted)
  Future<void> storeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to store secure data: $e');
    }
  }

  Future<String?> getSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read secure data: $e');
    }
  }

  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data: $e');
    }
  }

  Future<void> clearAllSecure() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear secure storage: $e');
    }
  }

  // Encrypted data storage using AES
  Future<void> storeEncrypted(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final encrypted = _encryptData(jsonString);
      await storeSecure(key, encrypted);
    } catch (e) {
      throw SecureStorageException('Failed to store encrypted data: $e');
    }
  }

  Future<Map<String, dynamic>?> getEncrypted(String key) async {
    try {
      final encrypted = await getSecure(key);
      if (encrypted == null) return null;
      
      final decrypted = _decryptData(encrypted);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException('Failed to get encrypted data: $e');
    }
  }

  String _encryptData(String data) {
    if (_encryptionKey == null) {
      throw SecureStorageException('Encryption key not initialized');
    }
    
    final key = base64.decode(_encryptionKey!);
    final iv = _generateRandomBytes(16);
    
    // Simple XOR encryption for demo - in production use proper AES
    final dataBytes = utf8.encode(data);
    final encrypted = List<int>.generate(dataBytes.length, (i) => 
      dataBytes[i] ^ key[i % key.length]);
    
    final combined = [...iv, ...encrypted];
    return base64.encode(combined);
  }

  String _decryptData(String encryptedData) {
    if (_encryptionKey == null) {
      throw SecureStorageException('Encryption key not initialized');
    }
    
    final combined = base64.decode(encryptedData);
    final key = base64.decode(_encryptionKey!);
    
    final iv = combined.sublist(0, 16);
    final encrypted = combined.sublist(16);
    
    // Simple XOR decryption for demo - in production use proper AES
    final decrypted = List<int>.generate(encrypted.length, (i) => 
      encrypted[i] ^ key[i % key.length]);
    
    return utf8.decode(decrypted);
  }

  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (i) => random.nextInt(256));
  }

  // Settings storage (non-encrypted)
  Future<void> setSetting(String key, dynamic value) async {
    try {
      await _settingsBox!.put(key, value);
    } catch (e) {
      throw SecureStorageException('Failed to save setting: $e');
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      final value = _settingsBox!.get(key, defaultValue: defaultValue);
      return value as T?;
    } catch (e) {
      return defaultValue;
    }
  }

  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBox!.delete(key);
    } catch (e) {
      throw SecureStorageException('Failed to delete setting: $e');
    }
  }

  // Cache storage (temporary data)
  Future<void> setCache(String key, dynamic value, {Duration? ttl}) async {
    try {
      final expiresAt = ttl != null ? 
        DateTime.now().add(ttl).millisecondsSinceEpoch : null;
      
      await _cacheBox!.put(key, {
        'value': value,
        'expires_at': expiresAt,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw SecureStorageException('Failed to save cache: $e');
    }
  }

  T? getCache<T>(String key) {
    try {
      final cached = _cacheBox!.get(key);
      if (cached == null) return null;
      
      final Map<String, dynamic> cacheData = Map<String, dynamic>.from(cached);
      final expiresAt = cacheData['expires_at'];
      
      // Check if cache has expired
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        _cacheBox!.delete(key);
        return null;
      }
      
      return cacheData['value'] as T?;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCache(String key) async {
    try {
      await _cacheBox!.delete(key);
    } catch (e) {
      throw SecureStorageException('Failed to delete cache: $e');
    }
  }

  Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];
      
      for (final key in _cacheBox!.keys) {
        final cached = _cacheBox!.get(key);
        if (cached is Map) {
          final expiresAt = cached['expires_at'];
          if (expiresAt != null && now > expiresAt) {
            keysToDelete.add(key.toString());
          }
        }
      }
      
      for (final key in keysToDelete) {
        await _cacheBox!.delete(key);
      }
    } catch (e) {
      throw SecureStorageException('Failed to clear expired cache: $e');
    }
  }

  // Authentication related storage
  Future<void> storeBiometricToken(String token) async {
    await storeSecure(AppConstants.sessionToken, token);
  }

  Future<String?> getBiometricToken() async {
    return await getSecure(AppConstants.sessionToken);
  }

  Future<void> clearBiometricToken() async {
    await deleteSecure(AppConstants.sessionToken);
  }

  Future<void> storeLastAuthTime(DateTime time) async {
    await storeSecure(AppConstants.lastAuthTime, time.toIso8601String());
  }

  Future<DateTime?> getLastAuthTime() async {
    final timeString = await getSecure(AppConstants.lastAuthTime);
    if (timeString == null) return null;
    return DateTime.parse(timeString);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await setSetting(AppConstants.biometricEnabled, enabled);
  }

  bool getBiometricEnabled() {
    return getSetting<bool>(AppConstants.biometricEnabled, defaultValue: true) ?? true;
  }

  // App settings
  Future<void> setThemeMode(String mode) async {
    await setSetting(AppConstants.themeMode, mode);
  }

  String getThemeMode() {
    return getSetting<String>(AppConstants.themeMode, defaultValue: 'system') ?? 'system';
  }

  Future<void> setTextScaleFactor(double factor) async {
    await setSetting(AppConstants.textScaleFactor, factor);
  }

  double getTextScaleFactor() {
    return getSetting<double>(AppConstants.textScaleFactor, defaultValue: 1.0) ?? 1.0;
  }

  Future<void> setAutoLockDuration(int minutes) async {
    await setSetting(AppConstants.autoLockDuration, minutes);
  }

  int getAutoLockDuration() {
    return getSetting<int>(AppConstants.autoLockDuration, defaultValue: 15) ?? 15;
  }

  Future<void> setHapticFeedback(bool enabled) async {
    await setSetting(AppConstants.hapticFeedback, enabled);
  }

  bool getHapticFeedback() {
    return getSetting<bool>(AppConstants.hapticFeedback, defaultValue: true) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await setSetting(AppConstants.soundEnabled, enabled);
  }

  bool getSoundEnabled() {
    return getSetting<bool>(AppConstants.soundEnabled, defaultValue: true) ?? true;
  }

  Future<void> setFirstRun(bool isFirstRun) async {
    await setSetting(AppConstants.firstRun, isFirstRun);
  }

  bool isFirstRun() {
    return getSetting<bool>(AppConstants.firstRun, defaultValue: true) ?? true;
  }

  // Data export/import
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = <String, dynamic>{};
      
      // Export non-sensitive settings only
      final settingsKeys = [
        AppConstants.themeMode,
        AppConstants.textScaleFactor,
        AppConstants.hapticFeedback,
        AppConstants.soundEnabled,
      ];
      
      for (final key in settingsKeys) {
        final value = getSetting(key);
        if (value != null) {
          settings[key] = value;
        }
      }
      
      return {
        'settings': settings,
        'exported_at': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
      };
    } catch (e) {
      throw SecureStorageException('Failed to export settings: $e');
    }
  }

  Future<void> importSettings(Map<String, dynamic> data) async {
    try {
      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings == null) return;
      
      for (final entry in settings.entries) {
        await setSetting(entry.key, entry.value);
      }
    } catch (e) {
      throw SecureStorageException('Failed to import settings: $e');
    }
  }

  // Storage management
  Future<Map<String, int>> getStorageStats() async {
    try {
      return {
        'settings_count': _settingsBox!.length,
        'cache_count': _cacheBox!.length,
        'secure_storage_keys': (await _secureStorage.readAll()).length,
      };
    } catch (e) {
      return {
        'settings_count': 0,
        'cache_count': 0,
        'secure_storage_keys': 0,
      };
    }
  }

  Future<void> clearAllData() async {
    try {
      await _settingsBox!.clear();
      await _cacheBox!.clear();
      await clearAllSecure();
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }

  Future<void> close() async {
    try {
      await _settingsBox?.close();
      await _cacheBox?.close();
    } catch (e) {
      // Ignore close errors
    }
  }
}

class SecureStorageException implements Exception {
  final String message;
  SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}