import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Setup'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getBiometricIcon(authProvider.availableBiometrics),
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Title
                Text(
                  'Secure Your App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Description
                Text(
                  _getBiometricDescription(authProvider.availableBiometrics),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Benefits
                _buildBenefitsList(),
                
                const SizedBox(height: AppConstants.largePadding * 2),
                
                // Action Buttons
                if (authProvider.biometricAvailable) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _setupBiometric(authProvider),
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_getBiometricIcon(authProvider.availableBiometrics)),
                      label: Text(_isLoading ? 'Setting up...' : 'Enable Biometric Authentication'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => _skipBiometric(),
                      child: const Text('Skip for now'),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Biometric Not Available',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your device doesn\'t support biometric authentication or it\'s not set up in system settings.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _continueWithoutBiometric(),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Privacy Note
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Expanded(
                        child: Text(
                          'Your biometric data is stored securely on your device and never leaves your phone.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {'icon': Icons.security, 'title': 'Enhanced Security', 'description': 'Protect your NFC card data with biometric authentication'},
      {'icon': Icons.speed, 'title': 'Quick Access', 'description': 'Unlock the app instantly without typing passwords'},
      {'icon': Icons.privacy_tip, 'title': 'Privacy Protection', 'description': 'Your biometric data stays on your device'},
    ];

    return Column(
      children: benefits.map((benefit) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      benefit['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getBiometricIcon(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (types.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    }
    return Icons.security;
  }

  String _getBiometricDescription(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Use Face ID to quickly and securely access your NFC card data.';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Use your fingerprint to quickly and securely access your NFC card data.';
    } else if (types.contains(BiometricType.iris)) {
      return 'Use iris recognition to quickly and securely access your NFC card data.';
    }
    return 'Use biometric authentication to quickly and securely access your NFC card data.';
  }

  Future<void> _setupBiometric(AuthProvider authProvider) async {
    setState(() => _isLoading = true);

    try {
      await authProvider.enableBiometric();
      
      if (mounted) {
        if (authProvider.biometricEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          AppRoutes.navigateToMain(context);
        } else if (authProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup biometric: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipBiometric() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Biometric Setup?'),
        content: const Text(
          'You can always enable biometric authentication later in the settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppRoutes.navigateToMain(context);
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _continueWithoutBiometric() {
    AppRoutes.navigateToMain(context);
  }
}