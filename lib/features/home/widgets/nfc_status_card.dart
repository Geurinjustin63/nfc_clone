import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/enhanced_nfc_service.dart';
import '../../nfc/providers/nfc_provider.dart';

class NFCStatusCard extends StatelessWidget {
  const NFCStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NFCProvider>(
      builder: (context, nfcProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(nfcProvider.status),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFC Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _getStatusText(nfcProvider.status),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getStatusColor(nfcProvider.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nfcProvider.status == NFCStatus.disabled)
                      ElevatedButton(
                        onPressed: () => _showNFCInstructions(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text('Enable'),
                      ),
                    if (nfcProvider.status == NFCStatus.error)
                      ElevatedButton(
                        onPressed: () => nfcProvider.checkNFCStatus(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text('Retry'),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  nfcProvider.statusMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                
                // Show operation progress
                if (nfcProvider.isReading || nfcProvider.isWriting) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: nfcProvider.isReading 
                              ? nfcProvider.readProgress 
                              : nfcProvider.writeProgress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            nfcProvider.isReading ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      Text(
                        '${((nfcProvider.isReading ? nfcProvider.readProgress : nfcProvider.writeProgress) * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                
                // Show additional info for enabled state
                if (nfcProvider.status == NFCStatus.enabled && !nfcProvider.isReading && !nfcProvider.isWriting) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready to scan',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Place your NFC card near the device',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.nfc,
                        color: Colors.green,
                        size: 32,
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

  Widget _buildStatusIcon(NFCStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case NFCStatus.enabled:
        icon = Icons.nfc;
        color = Colors.green;
        break;
      case NFCStatus.disabled:
        icon = Icons.nfc_outlined;
        color = Colors.orange;
        break;
      case NFCStatus.notAvailable:
        icon = Icons.portable_wifi_off;
        color = Colors.grey;
        break;
      case NFCStatus.reading:
        icon = Icons.search;
        color = Colors.blue;
        break;
      case NFCStatus.writing:
        icon = Icons.edit;
        color = Colors.green;
        break;
      case NFCStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    if (status == NFCStatus.reading || status == NFCStatus.writing) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getStatusText(NFCStatus status) {
    switch (status) {
      case NFCStatus.enabled:
        return 'Enabled';
      case NFCStatus.disabled:
        return 'Disabled';
      case NFCStatus.notAvailable:
        return 'Not Available';
      case NFCStatus.reading:
        return 'Reading...';
      case NFCStatus.writing:
        return 'Writing...';
      case NFCStatus.error:
        return 'Error';
    }
  }

  Color _getStatusColor(NFCStatus status) {
    switch (status) {
      case NFCStatus.enabled:
        return Colors.green;
      case NFCStatus.disabled:
        return Colors.orange;
      case NFCStatus.notAvailable:
        return Colors.grey;
      case NFCStatus.reading:
        return Colors.blue;
      case NFCStatus.writing:
        return Colors.green;
      case NFCStatus.error:
        return Colors.red;
    }
  }

  void _showNFCInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable NFC'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To use NFC features, please enable NFC in your device settings:'),
            SizedBox(height: 16),
            Text('1. Open Settings'),
            Text('2. Go to Connected devices or Wireless & networks'),
            Text('3. Find and enable NFC'),
            Text('4. Return to this app and try again'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}