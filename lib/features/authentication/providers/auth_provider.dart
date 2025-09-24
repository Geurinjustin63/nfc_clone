import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_session.dart';
import '../../../core/services/database_service.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  biometricSetup,
  locked,
  error,
}

enum BiometricType {
  none,
  fingerprint,
  face,
  iris,
  multiple,
}

class AuthProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DatabaseService _databaseService = DatabaseService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AuthState _authState = AuthState.unauthenticated;
  UserSession? _currentSession;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  String _errorMessage = '';
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  // Getters
  AuthState get authState => _authState;
  UserSession? get currentSession => _currentSession;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  DateTime? get lockoutUntil => _lockoutUntil;
  bool get isLocked => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  bool get isAuthenticated => _authState == AuthState.authenticated && _currentSession?.isValid == true;

  Future<void> initialize() async {
    try {
      await _checkBiometricCapability();
      await _loadBiometricSettings();
      await _checkExistingSession();
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    }
  }

  Future<void> _checkBiometricCapability() async {
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        _biometricAvailable = false;
        return;
      }

      _biometricAvailable = await _localAuth.canCheckBiometrics && 
                           await _localAuth.isDeviceSupported();

      if (_biometricAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _availableBiometrics = _mapBiometricTypes(availableBiometrics);
      }
    } catch (e) {
      _biometricAvailable = false;
      if (kDebugMode) {
        print('Error checking biometric capability: $e');
      }
    }
  }

  Future<void> _loadBiometricSettings() async {
    try {
      final enabled = await _secureStorage.read(key: AppConstants.biometricEnabled);
      _biometricEnabled = enabled == 'true';
    } catch (e) {
      _biometricEnabled = false;
    }
  }

  Future<void> _checkExistingSession() async {
    try {
      final session = await _databaseService.getActiveSession();
      if (session != null && session.isValid) {
        _currentSession = session;
        _authState = AuthState.authenticated;
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> authenticateWithBiometric() async {
    if (!_biometricAvailable || !_biometricEnabled) {
      _setError('Biometric authentication is not available or enabled');
      return false;
    }

    if (isLocked) {
      final remainingTime = _lockoutUntil!.difference(DateTime.now());
      _setError('Account locked. Try again in ${remainingTime.inMinutes} minutes');
      return false;
    }

    _authState = AuthState.authenticating;
    notifyListeners();

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access NFC Card Clone Pro',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        await _createSession(SessionType.biometric);
        _resetFailedAttempts();
        return true;
      } else {
        await _handleFailedAttempt();
        return false;
      }
    } on PlatformException catch (e) {
      await _handleAuthError(e);
      return false;
    }
  }

  Future<bool> authenticateWithPin(String pin) async {
    if (isLocked) {
      final remainingTime = _lockoutUntil!.difference(DateTime.now());
      _setError('Account locked. Try again in ${remainingTime.inMinutes} minutes');
      return false;
    }

    _authState = AuthState.authenticating;
    notifyListeners();

    try {
      final hashedPin = _hashPin(pin);
      final storedPin = await _secureStorage.read(key: 'user_pin');
      
      if (storedPin != null && storedPin == hashedPin) {
        await _createSession(SessionType.pin);
        _resetFailedAttempts();
        return true;
      } else {
        await _handleFailedAttempt();
        return false;
      }
    } catch (e) {
      _setError('PIN authentication failed: $e');
      return false;
    }
  }

  Future<bool> setupPin(String pin) async {
    try {
      final hashedPin = _hashPin(pin);
      await _secureStorage.write(key: 'user_pin', value: hashedPin);
      return true;
    } catch (e) {
      _setError('Failed to setup PIN: $e');
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    if (!_biometricAvailable) {
      _setError('Biometric authentication is not available on this device');
      return false;
    }

    try {
      // Test biometric authentication first
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for NFC Card Clone Pro',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(key: AppConstants.biometricEnabled, value: 'true');
        _biometricEnabled = true;
        notifyListeners();
        return true;
      } else {
        _setError('Biometric authentication failed');
        return false;
      }
    } on PlatformException catch (e) {
      _setError('Failed to enable biometric: ${e.message}');
      return false;
    }
  }

  Future<void> disableBiometric() async {
    try {
      await _secureStorage.write(key: AppConstants.biometricEnabled, value: 'false');
      _biometricEnabled = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to disable biometric: $e');
    }
  }

  Future<void> continueAsGuest() async {
    try {
      await _createSession(SessionType.guest);
    } catch (e) {
      _setError('Failed to create guest session: $e');
    }
  }

  Future<void> _createSession(SessionType type) async {
    try {
      final deviceId = await _getDeviceId();
      final deviceInfo = await _getDeviceInfo();
      
      final session = UserSession(
        type: type,
        deviceId: deviceId,
        deviceInfo: deviceInfo,
        expiresAt: DateTime.now().add(AppConstants.sessionTimeout),
        metadata: {
          'app_version': AppConstants.appVersion,
          'platform': Platform.operatingSystem,
          'created_via': type.name,
        },
      );

      await _databaseService.insertSession(session);
      await _secureStorage.write(key: AppConstants.sessionToken, value: session.id);
      await _secureStorage.write(key: AppConstants.lastAuthTime, value: DateTime.now().toIso8601String());

      _currentSession = session;
      _authState = AuthState.authenticated;
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _setError('Failed to create session: $e');
    }
  }

  Future<void> refreshSession() async {
    if (_currentSession == null) return;

    try {
      final updatedSession = _currentSession!.copyWith(
        lastAccessAt: DateTime.now(),
        expiresAt: DateTime.now().add(AppConstants.sessionTimeout),
      );

      await _databaseService.updateSession(updatedSession);
      _currentSession = updatedSession;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh session: $e');
      }
    }
  }

  Future<void> logout() async {
    try {
      if (_currentSession != null) {
        final expiredSession = _currentSession!.copyWith(
          status: SessionStatus.terminated,
        );
        await _databaseService.updateSession(expiredSession);
      }

      await _secureStorage.delete(key: AppConstants.sessionToken);
      await _secureStorage.delete(key: AppConstants.lastAuthTime);

      _currentSession = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = '';
      _failedAttempts = 0;
      _lockoutUntil = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout: $e');
    }
  }

  Future<void> lockApp() async {
    if (_currentSession != null) {
      final lockedSession = _currentSession!.copyWith(
        status: SessionStatus.locked,
      );
      await _databaseService.updateSession(lockedSession);
      _currentSession = lockedSession;
    }

    _authState = AuthState.locked;
    notifyListeners();
  }

  Future<void> _handleFailedAttempt() async {
    _failedAttempts++;
    
    if (_failedAttempts >= AppConstants.maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(AppConstants.lockoutDuration);
      _authState = AuthState.locked;
      _setError('Too many failed attempts. Account locked for ${AppConstants.lockoutDuration.inMinutes} minutes');
    } else {
      _setError('Authentication failed. ${AppConstants.maxFailedAttempts - _failedAttempts} attempts remaining');
    }
  }

  Future<void> _handleAuthError(PlatformException e) async {
    switch (e.code) {
      case 'NotAvailable':
        _setError('Biometric authentication is not available');
        break;
      case 'NotEnrolled':
        _setError('No biometric credentials are enrolled');
        break;
      case 'LockedOut':
        _setError('Biometric authentication is temporarily locked out');
        break;
      case 'PermanentlyLockedOut':
        _setError('Biometric authentication is permanently locked out');
        break;
      default:
        _setError('Authentication error: ${e.message}');
        break;
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    _authState = AuthState.error;
    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'nfc_clone_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
    } catch (e) {
      // Fallback to a generated ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'unknown_device';
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
    } catch (e) {
      return 'Unknown Device';
    }
    return 'Unknown Device';
  }

  List<BiometricType> _mapBiometricTypes(List<BiometricType> types) {
    return types;
  }

  // Check if session needs refresh
  bool shouldRefreshSession() {
    if (_currentSession == null) return false;
    
    final timeSinceLastAccess = DateTime.now().difference(_currentSession!.lastAccessAt);
    return timeSinceLastAccess.inMinutes > 5; // Refresh if inactive for 5+ minutes
  }

  // Auto-lock functionality
  void startAutoLockTimer() {
    // Implementation for auto-lock timer
    // This would be called from the main app to start monitoring user activity
  }

  void stopAutoLockTimer() {
    // Implementation for stopping auto-lock timer
  }

  @override
  void dispose() {
    stopAutoLockTimer();
    super.dispose();
  }
}