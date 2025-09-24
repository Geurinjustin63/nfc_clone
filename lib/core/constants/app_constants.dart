class AppConstants {
  // App Information
  static const String appName = 'NFC Card Clone Pro';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Professional NFC card reading and cloning application';
  
  // Database
  static const String databaseName = 'nfc_clone.db';
  static const int databaseVersion = 1;
  static const String cardsTableName = 'cards';
  static const String sessionsTableName = 'sessions';
  static const String tagsTableName = 'tags';
  
  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String secureBox = 'secure';
  
  // Secure Storage Keys
  static const String encryptionKey = 'encryption_key';
  static const String biometricEnabled = 'biometric_enabled';
  static const String sessionToken = 'session_token';
  static const String lastAuthTime = 'last_auth_time';
  
  // Settings Keys
  static const String themeMode = 'theme_mode';
  static const String textScaleFactor = 'text_scale_factor';
  static const String autoLockDuration = 'auto_lock_duration';
  static const String hapticFeedback = 'haptic_feedback';
  static const String soundEnabled = 'sound_enabled';
  static const String firstRun = 'first_run';
  
  // NFC Configuration
  static const Duration nfcSessionTimeout = Duration(seconds: 30);
  static const Duration nfcReadTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  
  // Security Configuration
  static const Duration sessionTimeout = Duration(minutes: 15);
  static const Duration biometricTimeout = Duration(seconds: 30);
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // File Paths
  static const String assetsImages = 'assets/images/';
  static const String assetsIcons = 'assets/icons/';
  static const String assetsAnimations = 'assets/animations/';
  
  // Export Formats
  static const List<String> exportFormats = ['JSON', 'CSV', 'XML'];
  static const List<String> importFormats = ['JSON', 'CSV'];
  
  // Card Types
  static const Map<String, String> cardTypes = {
    'mifare_classic': 'MIFARE Classic',
    'mifare_ultralight': 'MIFARE Ultralight',
    'ntag': 'NTAG',
    'desfire': 'DESFire',
    'felica': 'FeliCa',
    'iso15693': 'ISO 15693',
    'iso14443_a': 'ISO 14443 Type A',
    'iso14443_b': 'ISO 14443 Type B',
    'unknown': 'Unknown',
  };
  
  // NFC Standards
  static const Map<String, List<String>> nfcStandards = {
    'ISO 14443 Type A': ['MIFARE Classic', 'MIFARE Ultralight', 'NTAG'],
    'ISO 14443 Type B': ['Calypso', 'B Prime'],
    'ISO 15693': ['ICODE', 'Tag-it'],
    'FeliCa': ['FeliCa Lite', 'FeliCa Standard'],
  };
  
  // Error Messages
  static const String nfcNotAvailable = 'NFC is not available on this device';
  static const String nfcNotEnabled = 'Please enable NFC in system settings';
  static const String biometricNotAvailable = 'Biometric authentication is not available';
  static const String biometricNotSetup = 'Please setup biometric authentication in system settings';
  static const String sessionExpired = 'Session has expired. Please authenticate again';
  static const String networkError = 'Network connection error';
  static const String storageError = 'Storage error occurred';
  static const String encryptionError = 'Encryption/Decryption error';
  
  // Success Messages
  static const String cardReadSuccessfully = 'Card read successfully';
  static const String cardClonedSuccessfully = 'Card cloned successfully';
  static const String dataExportedSuccessfully = 'Data exported successfully';
  static const String settingsSavedSuccessfully = 'Settings saved successfully';
  static const String biometricSetupSuccessfully = 'Biometric authentication setup completed';
  
  // Validation
  static const int minTagNameLength = 1;
  static const int maxTagNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxCardsPerSession = 100;
  
  // Chart Colors
  static const List<int> chartColors = [
    0xFF1976D2, // Blue
    0xFF03DAC6, // Teal
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFFF44336, // Red
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String fullDateTimeFormat = 'EEEE, MMMM dd, yyyy HH:mm:ss';
}