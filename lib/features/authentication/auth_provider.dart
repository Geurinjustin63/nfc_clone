import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../core/services/storage_service.dart';
import '../../core/services/database_service.dart';
import '../../core/models/user_session.dart';
import '../../core/constants/app_constants.dart';

enum AuthState {
  initial,
  checking,
  authenticated,
  unauthenticated,
  locked,
  error,
}

enum BiometricType {
  none,
  fingerprint,
  face,
  iris,
}

class AuthProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();
  
  AuthState _authState = AuthState.initial;
  UserSession? _currentSession;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  int _failedAttempts = 0;
  DateTime? _lockoutTime;
  String? _errorMessage;
  
  // Getters
  AuthState get authState => _authState;
  UserSession? get currentSession => _currentSession;
  bool get isAuthenticated => _authState == AuthState.authenticated && _currentSession?.isValid == true;
  bool get isLocked => _authState == AuthState.locked;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  int get failedAttempts => _failedAttempts;
  Duration? get lockoutRemaining => _lockoutTime != null 
      ? _lockoutTime!.add(AppConstants.lockoutDuration).difference(DateTime.now())
      : null;
  String? get errorMessage => _errorMessage;
  
  Future<void> initialize() async {
    _updateAuthState(AuthState.checking);
    
    try {
      // Check biometric availability
      await _checkBiometricSupport();
      
      // Load biometric settings
      _biometricEnabled = await _storageService.getBiometricEnabled();
      
      // Check for existing session
      final existingSession = await _databaseService.getActiveSession();
      if (existingSession != null && existingSession.isValid) {
        _currentSession = existingSession;
        _updateAuthState(AuthState.authenticated);
      } else {
        _updateAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _updateAuthState(AuthState.error);
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        _biometricAvailable = false;
        _availableBiometrics = [];
        return;
      }

      _biometricAvailable = await _localAuth.canCheckBiometrics && 
                           await _localAuth.isDeviceSupported();
      
      if (_biometricAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _availableBiometrics = availableBiometrics.map(_mapBiometricType).toList();
      } else {
        _availableBiometrics = [];
      }
    } catch (e) {
      _biometricAvailable = false;
      _availableBiometrics = [];
    }
  }

  BiometricType _mapBiometricType(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return BiometricType.fingerprint;
      case BiometricType.face:
        return BiometricType.face;
      case BiometricType.iris:
        return BiometricType.iris;
      default:
        return BiometricType.none;
    }
  }

  Future<bool> authenticateWithBiometrics({String? reason}) async {
    if (!_biometricAvailable || !_biometricEnabled) {
      return false;
    }

    if (_isLockedOut()) {
      _errorMessage = 'Account temporarily locked due to too many failed attempts';
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access NFC Card Clone Pro',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _onSuccessfulAuthentication(SessionType.biometric);
        return true;
      } else {
        _incrementFailedAttempts();
        return false;
      }
    } on PlatformException catch (e) {
      _errorMessage = _handleAuthException(e);
      _incrementFailedAttempts();
      return false;
    } catch (e) {
      _errorMessage = 'Authentication error: ${e.toString()}';
      _incrementFailedAttempts();
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    if (_isLockedOut()) {
      _errorMessage = 'Account temporarily locked due to too many failed attempts';
      return false;
    }

    try {
      // Simulate PIN validation (replace with actual validation)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For demo purposes, accept any 4-digit PIN
      if (pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin)) {
        await _onSuccessfulAuthentication(SessionType.pin);
        return true;
      } else {
        _errorMessage = 'Invalid PIN';
        _incrementFailedAttempts();
        return false;
      }
    } catch (e) {
      _errorMessage = 'PIN authentication error: ${e.toString()}';
      _incrementFailedAttempts();
      return false;
    }
  }

  Future<bool> authenticateAsGuest() async {
    try {
      await _onSuccessfulAuthentication(SessionType.guest);
      return true;
    } catch (e) {
      _errorMessage = 'Guest authentication error: ${e.toString()}';
      return false;
    }
  }

  Future<void> _onSuccessfulAuthentication(SessionType sessionType) async {
    _failedAttempts = 0;
    _lockoutTime = null;
    _errorMessage = null;
    
    // Get device info
    final deviceInfo = await _getDeviceInfo();
    
    // Create new session
    _currentSession = UserSession(
      type: sessionType,
      deviceId: deviceInfo['deviceId'],
      deviceInfo: deviceInfo['deviceInfo'],
    );
    
    // Store session in database
    await _databaseService.insertSession(_currentSession!);
    
    // Store auth time
    await _storageService.storeLastAuthTime(DateTime.now());
    
    _updateAuthState(AuthState.authenticated);
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceInfo': '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceInfo': '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})',
        };
      }
    } catch (e) {
      // Fallback to generic info
    }
    
    return {
      'deviceId': 'unknown_device',
      'deviceInfo': 'Unknown Device',
    };
  }

  void _incrementFailedAttempts() {
    _failedAttempts++;
    
    if (_failedAttempts >= AppConstants.maxFailedAttempts) {
      _lockoutTime = DateTime.now();
      _updateAuthState(AuthState.locked);
    }
    
    notifyListeners();
  }

  bool _isLockedOut() {
    if (_lockoutTime == null) return false;
    
    final lockoutEnd = _lockoutTime!.add(AppConstants.lockoutDuration);
    if (DateTime.now().isAfter(lockoutEnd)) {
      _lockoutTime = null;
      _failedAttempts = 0;
      if (_authState == AuthState.locked) {
        _updateAuthState(AuthState.unauthenticated);
      }
      return false;
    }
    
    return true;
  }

  String _handleAuthException(PlatformException exception) {
    switch (exception.code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available';
      case 'NotEnrolled':
        return 'No biometric credentials are enrolled';
      case 'LockedOut':
        return 'Biometric authentication is temporarily locked out';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is permanently locked out';
      case 'UserCancel':
        return 'Authentication cancelled by user';
      case 'UserFallback':
        return 'User requested fallback authentication';
      case 'BiometricOnly':
        return 'Device does not support biometric-only authentication';
      case 'InvalidContext':
        return 'Authentication context is invalid';
      default:
        return exception.message ?? 'Unknown biometric error';
    }
  }

  Future<void> enableBiometrics() async {
    if (!_biometricAvailable) {
      throw Exception('Biometric authentication is not available');
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for secure access',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _biometricEnabled = true;
        await _storageService.storeBiometricEnabled(true);
        notifyListeners();
      }
    } on PlatformException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  Future<void> disableBiometrics() async {
    _biometricEnabled = false;
    await _storageService.storeBiometricEnabled(false);
    notifyListeners();
  }

  Future<void> refreshSession() async {
    if (_currentSession == null || !_currentSession!.isValid) {
      await logout();
      return;
    }

    // Update session last access time
    _currentSession = _currentSession!.copyWith(
      lastAccessAt: DateTime.now(),
    );
    
    await _databaseService.updateSession(_currentSession!);
    notifyListeners();
  }

  Future<void> logout() async {
    if (_currentSession != null) {
      // Update session status to terminated
      _currentSession = _currentSession!.copyWith(
        status: SessionStatus.terminated,
      );
      await _databaseService.updateSession(_currentSession!);
    }
    
    _currentSession = null;
    _updateAuthState(AuthState.unauthenticated);
    
    // Clear sensitive data
    await _storageService.deleteSecure(AppConstants.sessionToken);
  }

  Future<void> expireAllSessions() async {
    await _databaseService.expireAllSessions();
    await logout();
  }

  Future<bool> checkSessionExpiry() async {
    if (_currentSession == null) return false;
    
    if (_currentSession!.isExpired) {
      await logout();
      return true;
    }
    
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _updateAuthState(AuthState newState) {
    if (_authState != newState) {
      _authState = newState;
      notifyListeners();
    }
  }

  // Session management
  Future<List<UserSession>> getSessionHistory() async {
    // This would fetch session history from database
    return [];
  }

  Future<void> cleanupOldSessions() async {
    await _databaseService.cleanupExpiredSessions();
  }

  // Security features
  bool shouldRequireReauth() {
    if (_currentSession == null) return true;
    
    final lastAuth = _currentSession!.lastAccessAt;
    final autoLockDuration = Duration(minutes: _storageService.getAutoLockDuration());
    
    return DateTime.now().difference(lastAuth) > autoLockDuration;
  }

  Future<void> lockApp() async {
    _updateAuthState(AuthState.locked);
  }

  Future<void> unlockApp() async {
    if (_currentSession != null && _currentSession!.isValid) {
      _updateAuthState(AuthState.authenticated);
    } else {
      _updateAuthState(AuthState.unauthenticated);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}