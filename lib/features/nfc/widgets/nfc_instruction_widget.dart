import 'package:flutter/material.dart';
import '../../../core/services/enhanced_nfc_service.dart';
import '../../../app/themes.dart';

class NFCInstructionWidget extends StatelessWidget {
  final NFCStatus status;
  final String? lastError;

  const NFCInstructionWidget({
    super.key,
    required this.status,
    this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _getMainInstruction(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getInstructionColor(),
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _getDetailedInstruction(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        if (lastError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lastError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildTipsCard(context),
      ],
    );
  }

  String _getMainInstruction() {
    switch (status) {
      case NFCStatus.reading:
        return 'Hold NFC card near device';
      case NFCStatus.writing:
        return 'Writing to card...';
      case NFCStatus.enabled:
        return 'Ready to scan';
      case NFCStatus.error:
        return 'Error occurred';
      case NFCStatus.disabled:
        return 'NFC is disabled';
      case NFCStatus.notAvailable:
        return 'NFC not available';
    }
  }

  String _getDetailedInstruction() {
    switch (status) {
      case NFCStatus.reading:
        return 'Keep the NFC card close to the back of your device and hold it steady until scanning completes.';
      case NFCStatus.writing:
        return 'Do not move the card until the writing process is complete.';
      case NFCStatus.enabled:
        return 'Place an NFC card near the back of your device to start scanning.';
      case NFCStatus.error:
        return 'An error occurred while trying to access NFC. Please try again.';
      case NFCStatus.disabled:
        return 'NFC is turned off in your device settings. Please enable NFC to continue.';
      case NFCStatus.notAvailable:
        return 'Your device does not support NFC or NFC is not available.';
    }
  }

  Color _getInstructionColor() {
    switch (status) {
      case NFCStatus.reading:
      case NFCStatus.writing:
        return AppColors.primary;
      case NFCStatus.enabled:
        return AppColors.success;
      case NFCStatus.error:
        return AppColors.error;
      case NFCStatus.disabled:
      case NFCStatus.notAvailable:
        return AppColors.textSecondary;
    }
  }

  Widget _buildTipsCard(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for better scanning',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Remove any phone case or cover'),
            _buildTipItem('Hold the card flat against the device'),
            _buildTipItem('Keep the card steady for 2-3 seconds'),
            _buildTipItem('Try different positions on the back of your device'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}