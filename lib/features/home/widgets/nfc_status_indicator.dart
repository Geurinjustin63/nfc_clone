import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../nfc/providers/nfc_provider.dart';
import '../../../core/services/enhanced_nfc_service.dart';

class NFCStatusIndicator extends StatelessWidget {
  const NFCStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NFCProvider>(
      builder: (context, nfc, child) {
        return Card(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(nfc.status).withOpacity(0.1),
                  _getStatusColor(nfc.status).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Status Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(nfc.status).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(nfc.status),
                        color: _getStatusColor(nfc.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFC Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusText(nfc.status),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(nfc.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nfc.isReading || nfc.isWriting)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(nfc.status),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Status Message
                const SizedBox(height: AppConstants.defaultPadding),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius - 4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    nfc.statusMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Progress Indicators
                if (nfc.isReading || nfc.isWriting) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nfc.isReading ? 'Reading...' : 'Writing...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${((nfc.isReading ? nfc.readProgress : nfc.writeProgress) * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: nfc.isReading ? nfc.readProgress : nfc.writeProgress,
                        backgroundColor: _getStatusColor(nfc.status).withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(nfc.status),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Statistics Row
                if (nfc.successfulReads > 0 || nfc.failedReads > 0) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Successful',
                          '${nfc.successfulReads}',
                          Colors.green,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Failed',
                          '${nfc.failedReads + nfc.failedWrites}',
                          Colors.red,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Success Rate',
                          '${(nfc.readSuccessRate * 100).toInt()}%',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(NFCStatus status) {
    switch (status) {
      case NFCStatus.enabled:
        return Colors.green;
      case NFCStatus.reading:
        return Colors.blue;
      case NFCStatus.writing:
        return Colors.orange;
      case NFCStatus.disabled:
        return Colors.orange;
      case NFCStatus.notAvailable:
        return Colors.grey;
      case NFCStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(NFCStatus status) {
    switch (status) {
      case NFCStatus.enabled:
        return Icons.nfc;
      case NFCStatus.reading:
        return Icons.search;
      case NFCStatus.writing:
        return Icons.edit;
      case NFCStatus.disabled:
        return Icons.nfc_outlined;
      case NFCStatus.notAvailable:
        return Icons.portable_wifi_off;
      case NFCStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(NFCStatus status) {
    switch (status) {
      case NFCStatus.enabled:
        return 'Ready';
      case NFCStatus.reading:
        return 'Reading Card';
      case NFCStatus.writing:
        return 'Writing Card';
      case NFCStatus.disabled:
        return 'Disabled';
      case NFCStatus.notAvailable:
        return 'Not Available';
      case NFCStatus.error:
        return 'Error';
    }
  }
}