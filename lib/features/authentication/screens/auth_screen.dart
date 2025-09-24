import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../providers/auth_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    try {
      // Provide haptic feedback
      settingsProvider.performHapticFeedback();
      
      final success = await authProvider.authenticate();
      
      if (success) {
        settingsProvider.performSuccessHaptic();
        if (mounted) {
          AppRoutes.navigateToMain(context);
        }
      } else {
        settingsProvider.performErrorHaptic();
        _showErrorSnackBar(authProvider.errorMessage ?? 'Authentication failed');
      }
    } catch (e) {
      settingsProvider.performErrorHaptic();
      _showErrorSnackBar('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _continueAsGuest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      await authProvider.continueAsGuest();
      if (mounted) {
        AppRoutes.navigateToMain(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to continue as guest: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildHeader(),
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildAuthContent(),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo
        Hero(
          tag: 'app_logo',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.nfc,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: AppConstants.largePadding),
        
        // App Name and Description
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppConstants.smallPadding),
        
        Text(
          'Professional NFC card reading and cloning',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthContent() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Message
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: _getStatusColor(auth).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: _getStatusColor(auth).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(auth),
                    color: _getStatusColor(auth),
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Text(
                      _getStatusMessage(auth),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(auth),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.largePadding),
            
            // Biometric Authentication Button
            if (auth.biometricAvailable)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isAuthenticating ? null : _authenticateWithBiometric,
                  icon: _isAuthenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_getBiometricIcon(auth)),
                  label: Text(
                    _isAuthenticating 
                        ? 'Authenticating...' 
                        : 'Authenticate with ${auth.getBiometricTypeDisplayName()}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ),
            
            // Biometric not available message
            if (!auth.biometricAvailable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'Biometric authentication is not available on this device',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Guest Access Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _continueAsGuest,
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Guest'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
            ),
            
            // Error Display
            if (auth.errorMessage?.isNotEmpty == true) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Lockout Display
            if (auth.isLockedOut) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_clock,
                      color: Colors.red,
                      size: 32,
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'Account Locked',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Too many failed attempts. Please wait ${auth.lockoutTimeRemaining?.inMinutes ?? 0} minutes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Version Info
        Text(
          'Version ${AppConstants.appVersion}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        
        const SizedBox(height: AppConstants.smallPadding),
        
        // Help Link
        TextButton(
          onPressed: _showHelpDialog,
          child: Text(
            'Need help?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AuthProvider auth) {
    if (auth.isLockedOut) return Colors.red;
    if (auth.errorMessage?.isNotEmpty == true) return Colors.orange;
    if (auth.biometricAvailable) return Colors.green;
    return Colors.blue;
  }

  IconData _getStatusIcon(AuthProvider auth) {
    if (auth.isLockedOut) return Icons.lock;
    if (auth.errorMessage?.isNotEmpty == true) return Icons.warning;
    if (auth.biometricAvailable) return Icons.check_circle;
    return Icons.info;
  }

  String _getStatusMessage(AuthProvider auth) {
    if (auth.isLockedOut) {
      return 'Account locked due to failed attempts';
    }
    if (auth.errorMessage?.isNotEmpty == true) {
      return auth.errorMessage!;
    }
    if (auth.biometricAvailable) {
      return '${auth.getBiometricTypeDisplayName()} authentication is ready';
    }
    return 'Biometric authentication not available';
  }

  IconData _getBiometricIcon(AuthProvider auth) {
    if (auth.availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (auth.availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biometric Authentication:'),
            Text('• Make sure biometric authentication is enabled in your device settings'),
            Text('• Supported methods: Face ID, Touch ID, Fingerprint'),
            SizedBox(height: 16),
            Text('Guest Mode:'),
            Text('• Limited functionality without authentication'),
            Text('• Some features may not be available'),
            SizedBox(height: 16),
            Text('If you\'re having trouble, try restarting the app or check your device settings.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}