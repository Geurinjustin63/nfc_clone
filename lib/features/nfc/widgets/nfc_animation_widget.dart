import 'package:flutter/material.dart';
import '../../../core/services/enhanced_nfc_service.dart';
import '../../../app/themes.dart';

class NFCAnimationWidget extends StatefulWidget {
  final bool isScanning;
  final NFCStatus status;

  const NFCAnimationWidget({
    super.key,
    required this.isScanning,
    required this.status,
  });

  @override
  State<NFCAnimationWidget> createState() => _NFCAnimationWidgetState();
}

class _NFCAnimationWidgetState extends State<NFCAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _iconController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    if (widget.isScanning) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(NFCAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _rippleController.repeat();
      } else {
        _rippleController.stop();
        _iconController.forward().then((_) {
          _iconController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple effects
          if (widget.isScanning) ...[
            _buildRipple(80, 0.0),
            _buildRipple(100, 0.3),
            _buildRipple(120, 0.6),
          ],
          
          // Main NFC icon circle
          AnimatedBuilder(
            animation: _iconScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconScaleAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double size, double delay) {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        final delayedValue = (_rippleAnimation.value - delay).clamp(0.0, 1.0);
        
        return Container(
          width: size * delayedValue,
          height: size * delayedValue,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getStatusColor().withOpacity(0.8 * (1 - delayedValue)),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case NFCStatus.enabled:
        return AppColors.nfcActive;
      case NFCStatus.reading:
        return AppColors.nfcReading;
      case NFCStatus.writing:
        return AppColors.nfcCloning;
      case NFCStatus.error:
        return AppColors.error;
      case NFCStatus.disabled:
      case NFCStatus.notAvailable:
      default:
        return AppColors.nfcInactive;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case NFCStatus.enabled:
      case NFCStatus.reading:
        return Icons.nfc;
      case NFCStatus.writing:
        return Icons.edit;
      case NFCStatus.error:
        return Icons.error_outline;
      case NFCStatus.disabled:
      case NFCStatus.notAvailable:
      default:
        return Icons.nfc_outlined;
    }
  }
}