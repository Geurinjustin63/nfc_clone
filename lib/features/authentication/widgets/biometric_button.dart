import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class BiometricButton extends StatelessWidget {
  final List<BiometricType> biometricTypes;
  final VoidCallback? onPressed;
  final bool isLoading;

  const BiometricButton({
    super.key,
    required this.biometricTypes,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryBiometric = _getPrimaryBiometricType();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBiometricIcon(primaryBiometric),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getBiometricText(primaryBiometric),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touch to authenticate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  BiometricType _getPrimaryBiometricType() {
    if (biometricTypes.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (biometricTypes.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (biometricTypes.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    return BiometricType.fingerprint; // Default fallback
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      case BiometricType.none:
        return Icons.security;
    }
  }

  String _getBiometricText(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Use Face ID';
      case BiometricType.fingerprint:
        return 'Use Fingerprint';
      case BiometricType.iris:
        return 'Use Iris Recognition';
      case BiometricType.none:
        return 'Use Biometric';
    }
  }
}