import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/secure_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;

  // Security settings
  bool _biometricEnabled = true;
  int _autoLockDuration = 15; // minutes
  bool _requireBiometricForSensitiveActions = true;
  bool _showCardPreviewsInList = true;

  // App behavior settings
  bool _hapticFeedback = true;
  bool _soundEnabled = true;
  bool _showNFCStatusInAppBar = true;
  bool _autoSaveReadCards = true;
  bool _confirmBeforeCardDeletion = true;

  // NFC settings
  int _nfcReadTimeout = 30; // seconds
  int _nfcRetryAttempts = 3;
  bool _enableAdvancedNFCFeatures = true;
  bool _showRawCardData = false;

  // Data management settings
  int _maxStoredCards = 1000;
  bool _autoBackupEnabled = false;
  int _backupFrequencyDays = 7;
  bool _exportIncludeArchivedCards = false;

  // Developer settings
  bool _developerModeEnabled = false;
  bool _showDebugInfo = false;
  bool _enableLogging = false;

  // App info
  String _appVersion = '2.0.0';
  String _buildNumber = '1';

  // Getters
  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  bool get biometricEnabled => _biometricEnabled;
  int get autoLockDuration => _autoLockDuration;
  bool get requireBiometricForSensitiveActions => _requireBiometricForSensitiveActions;
  bool get showCardPreviewsInList => _showCardPreviewsInList;
  bool get hapticFeedback => _hapticFeedback;
  bool get soundEnabled => _soundEnabled;
  bool get showNFCStatusInAppBar => _showNFCStatusInAppBar;
  bool get autoSaveReadCards => _autoSaveReadCards;
  bool get confirmBeforeCardDeletion => _confirmBeforeCardDeletion;
  int get nfcReadTimeout => _nfcReadTimeout;
  int get nfcRetryAttempts => _nfcRetryAttempts;
  bool get enableAdvancedNFCFeatures => _enableAdvancedNFCFeatures;
  bool get showRawCardData => _showRawCardData;
  int get maxStoredCards => _maxStoredCards;
  bool get autoBackupEnabled => _autoBackupEnabled;
  int get backupFrequencyDays => _backupFrequencyDays;
  bool get exportIncludeArchivedCards => _exportIncludeArchivedCards;
  bool get developerModeEnabled => _developerModeEnabled;
  bool get showDebugInfo => _showDebugInfo;
  bool get enableLogging => _enableLogging;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;

  // Computed properties
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  Duration get autoLockDurationDuration => Duration(minutes: _autoLockDuration);
  Duration get nfcReadTimeoutDuration => Duration(seconds: _nfcReadTimeout);

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Theme settings
      final themeModeString = _storage.getThemeMode();
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );
      
      _textScaleFactor = _storage.getTextScaleFactor();

      // Security settings
      _biometricEnabled = _storage.getBiometricEnabled();
      _autoLockDuration = _storage.getAutoLockDuration();
      
      _requireBiometricForSensitiveActions = _storage.getSetting<bool>(
        'require_biometric_for_sensitive_actions',
        defaultValue: true,
      ) ?? true;
      
      _showCardPreviewsInList = _storage.getSetting<bool>(
        'show_card_previews_in_list',
        defaultValue: true,
      ) ?? true;

      // App behavior settings
      _hapticFeedback = _storage.getHapticFeedback();
      _soundEnabled = _storage.getSoundEnabled();
      
      _showNFCStatusInAppBar = _storage.getSetting<bool>(
        'show_nfc_status_in_app_bar',
        defaultValue: true,
      ) ?? true;
      
      _autoSaveReadCards = _storage.getSetting<bool>(
        'auto_save_read_cards',
        defaultValue: true,
      ) ?? true;
      
      _confirmBeforeCardDeletion = _storage.getSetting<bool>(
        'confirm_before_card_deletion',
        defaultValue: true,
      ) ?? true;

      // NFC settings
      _nfcReadTimeout = _storage.getSetting<int>(
        'nfc_read_timeout',
        defaultValue: 30,
      ) ?? 30;
      
      _nfcRetryAttempts = _storage.getSetting<int>(
        'nfc_retry_attempts',
        defaultValue: 3,
      ) ?? 3;
      
      _enableAdvancedNFCFeatures = _storage.getSetting<bool>(
        'enable_advanced_nfc_features',
        defaultValue: true,
      ) ?? true;
      
      _showRawCardData = _storage.getSetting<bool>(
        'show_raw_card_data',
        defaultValue: false,
      ) ?? false;

      // Data management settings
      _maxStoredCards = _storage.getSetting<int>(
        'max_stored_cards',
        defaultValue: 1000,
      ) ?? 1000;
      
      _autoBackupEnabled = _storage.getSetting<bool>(
        'auto_backup_enabled',
        defaultValue: false,
      ) ?? false;
      
      _backupFrequencyDays = _storage.getSetting<int>(
        'backup_frequency_days',
        defaultValue: 7,
      ) ?? 7;
      
      _exportIncludeArchivedCards = _storage.getSetting<bool>(
        'export_include_archived_cards',
        defaultValue: false,
      ) ?? false;

      // Developer settings
      _developerModeEnabled = _storage.getSetting<bool>(
        'developer_mode_enabled',
        defaultValue: false,
      ) ?? false;
      
      _showDebugInfo = _storage.getSetting<bool>(
        'show_debug_info',
        defaultValue: false,
      ) ?? false;
      
      _enableLogging = _storage.getSetting<bool>(
        'enable_logging',
        defaultValue: false,
      ) ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  // Theme settings methods
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _storage.setThemeMode(mode.name);
      notifyListeners();
    }
  }

  Future<void> setTextScaleFactor(double factor) async {
    if (_textScaleFactor != factor) {
      _textScaleFactor = factor;
      await _storage.setTextScaleFactor(factor);
      notifyListeners();
    }
  }

  // Security settings methods
  Future<void> setBiometricEnabled(bool enabled) async {
    if (_biometricEnabled != enabled) {
      _biometricEnabled = enabled;
      await _storage.setBiometricEnabled(enabled);
      notifyListeners();
    }
  }

  Future<void> setAutoLockDuration(int minutes) async {
    if (_autoLockDuration != minutes) {
      _autoLockDuration = minutes;
      await _storage.setAutoLockDuration(minutes);
      notifyListeners();
    }
  }

  Future<void> setRequireBiometricForSensitiveActions(bool required) async {
    if (_requireBiometricForSensitiveActions != required) {
      _requireBiometricForSensitiveActions = required;
      await _storage.setSetting('require_biometric_for_sensitive_actions', required);
      notifyListeners();
    }
  }

  Future<void> setShowCardPreviewsInList(bool show) async {
    if (_showCardPreviewsInList != show) {
      _showCardPreviewsInList = show;
      await _storage.setSetting('show_card_previews_in_list', show);
      notifyListeners();
    }
  }

  // App behavior settings methods
  Future<void> setHapticFeedback(bool enabled) async {
    if (_hapticFeedback != enabled) {
      _hapticFeedback = enabled;
      await _storage.setHapticFeedback(enabled);
      notifyListeners();
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled != enabled) {
      _soundEnabled = enabled;
      await _storage.setSoundEnabled(enabled);
      notifyListeners();
    }
  }

  Future<void> setShowNFCStatusInAppBar(bool show) async {
    if (_showNFCStatusInAppBar != show) {
      _showNFCStatusInAppBar = show;
      await _storage.setSetting('show_nfc_status_in_app_bar', show);
      notifyListeners();
    }
  }

  Future<void> setAutoSaveReadCards(bool autoSave) async {
    if (_autoSaveReadCards != autoSave) {
      _autoSaveReadCards = autoSave;
      await _storage.setSetting('auto_save_read_cards', autoSave);
      notifyListeners();
    }
  }

  Future<void> setConfirmBeforeCardDeletion(bool confirm) async {
    if (_confirmBeforeCardDeletion != confirm) {
      _confirmBeforeCardDeletion = confirm;
      await _storage.setSetting('confirm_before_card_deletion', confirm);
      notifyListeners();
    }
  }

  // NFC settings methods
  Future<void> setNFCReadTimeout(int seconds) async {
    if (_nfcReadTimeout != seconds) {
      _nfcReadTimeout = seconds;
      await _storage.setSetting('nfc_read_timeout', seconds);
      notifyListeners();
    }
  }

  Future<void> setNFCRetryAttempts(int attempts) async {
    if (_nfcRetryAttempts != attempts) {
      _nfcRetryAttempts = attempts;
      await _storage.setSetting('nfc_retry_attempts', attempts);
      notifyListeners();
    }
  }

  Future<void> setEnableAdvancedNFCFeatures(bool enabled) async {
    if (_enableAdvancedNFCFeatures != enabled) {
      _enableAdvancedNFCFeatures = enabled;
      await _storage.setSetting('enable_advanced_nfc_features', enabled);
      notifyListeners();
    }
  }

  Future<void> setShowRawCardData(bool show) async {
    if (_showRawCardData != show) {
      _showRawCardData = show;
      await _storage.setSetting('show_raw_card_data', show);
      notifyListeners();
    }
  }

  // Data management settings methods
  Future<void> setMaxStoredCards(int maxCards) async {
    if (_maxStoredCards != maxCards) {
      _maxStoredCards = maxCards;
      await _storage.setSetting('max_stored_cards', maxCards);
      notifyListeners();
    }
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (_autoBackupEnabled != enabled) {
      _autoBackupEnabled = enabled;
      await _storage.setSetting('auto_backup_enabled', enabled);
      notifyListeners();
    }
  }

  Future<void> setBackupFrequencyDays(int days) async {
    if (_backupFrequencyDays != days) {
      _backupFrequencyDays = days;
      await _storage.setSetting('backup_frequency_days', days);
      notifyListeners();
    }
  }

  Future<void> setExportIncludeArchivedCards(bool include) async {
    if (_exportIncludeArchivedCards != include) {
      _exportIncludeArchivedCards = include;
      await _storage.setSetting('export_include_archived_cards', include);
      notifyListeners();
    }
  }

  // Developer settings methods
  Future<void> setDeveloperModeEnabled(bool enabled) async {
    if (_developerModeEnabled != enabled) {
      _developerModeEnabled = enabled;
      await _storage.setSetting('developer_mode_enabled', enabled);
      notifyListeners();
    }
  }

  Future<void> setShowDebugInfo(bool show) async {
    if (_showDebugInfo != show) {
      _showDebugInfo = show;
      await _storage.setSetting('show_debug_info', show);
      notifyListeners();
    }
  }

  Future<void> setEnableLogging(bool enabled) async {
    if (_enableLogging != enabled) {
      _enableLogging = enabled;
      await _storage.setSetting('enable_logging', enabled);
      notifyListeners();
    }
  }

  // Utility methods
  Future<void> resetToDefaults() async {
    try {
      _themeMode = ThemeMode.system;
      _textScaleFactor = 1.0;
      _biometricEnabled = true;
      _autoLockDuration = 15;
      _requireBiometricForSensitiveActions = true;
      _showCardPreviewsInList = true;
      _hapticFeedback = true;
      _soundEnabled = true;
      _showNFCStatusInAppBar = true;
      _autoSaveReadCards = true;
      _confirmBeforeCardDeletion = true;
      _nfcReadTimeout = 30;
      _nfcRetryAttempts = 3;
      _enableAdvancedNFCFeatures = true;
      _showRawCardData = false;
      _maxStoredCards = 1000;
      _autoBackupEnabled = false;
      _backupFrequencyDays = 7;
      _exportIncludeArchivedCards = false;
      _developerModeEnabled = false;
      _showDebugInfo = false;
      _enableLogging = false;

      // Save all default values
      await _storage.setThemeMode(_themeMode.name);
      await _storage.setTextScaleFactor(_textScaleFactor);
      await _storage.setBiometricEnabled(_biometricEnabled);
      await _storage.setAutoLockDuration(_autoLockDuration);
      await _storage.setHapticFeedback(_hapticFeedback);
      await _storage.setSoundEnabled(_soundEnabled);
      
      // Clear all custom settings
      await _storage.setSetting('require_biometric_for_sensitive_actions', _requireBiometricForSensitiveActions);
      await _storage.setSetting('show_card_previews_in_list', _showCardPreviewsInList);
      await _storage.setSetting('show_nfc_status_in_app_bar', _showNFCStatusInAppBar);
      await _storage.setSetting('auto_save_read_cards', _autoSaveReadCards);
      await _storage.setSetting('confirm_before_card_deletion', _confirmBeforeCardDeletion);
      await _storage.setSetting('nfc_read_timeout', _nfcReadTimeout);
      await _storage.setSetting('nfc_retry_attempts', _nfcRetryAttempts);
      await _storage.setSetting('enable_advanced_nfc_features', _enableAdvancedNFCFeatures);
      await _storage.setSetting('show_raw_card_data', _showRawCardData);
      await _storage.setSetting('max_stored_cards', _maxStoredCards);
      await _storage.setSetting('auto_backup_enabled', _autoBackupEnabled);
      await _storage.setSetting('backup_frequency_days', _backupFrequencyDays);
      await _storage.setSetting('export_include_archived_cards', _exportIncludeArchivedCards);
      await _storage.setSetting('developer_mode_enabled', _developerModeEnabled);
      await _storage.setSetting('show_debug_info', _showDebugInfo);
      await _storage.setSetting('enable_logging', _enableLogging);

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset settings: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exportSettings() async {
    try {
      return await _storage.exportSettings();
    } catch (e) {
      debugPrint('Failed to export settings: $e');
      rethrow;
    }
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      await _storage.importSettings(settings);
      await _loadSettings(); // Reload settings after import
    } catch (e) {
      debugPrint('Failed to import settings: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getStorageStats() async {
    try {
      return await _storage.getStorageStats();
    } catch (e) {
      debugPrint('Failed to get storage stats: $e');
      return {};
    }
  }

  Future<void> clearAllData() async {
    try {
      await _storage.clearAllData();
      await resetToDefaults();
    } catch (e) {
      debugPrint('Failed to clear all data: $e');
      rethrow;
    }
  }

  // Haptic feedback helper
  void performHapticFeedback() {
    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void performSuccessHaptic() {
    if (_hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  void performErrorHaptic() {
    if (_hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
  }

  // Theme helper methods
  bool isDarkModeForContext(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  Color getThemeColorForContext(BuildContext context) {
    return isDarkModeForContext(context) 
        ? Colors.white 
        : Colors.black;
  }

  @override
  void dispose() {
    super.dispose();
  }
}