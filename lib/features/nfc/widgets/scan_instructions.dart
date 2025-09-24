import 'package:flutter/material.dart';
import '../../../core/services/enhanced_nfc_service.dart';
import '../../../core/constants/app_constants.dart';

class ScanInstructions extends StatelessWidget {
  final bool isScanning;
  final NFCStatus nfcStatus;

  const ScanInstructions({
    super.key,
    required this.isScanning,
    required this.nfcStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getInstructionTitle(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.smallPadding),
          
          ..._buildInstructionSteps(context),
          
          if (!isScanning && nfcStatus == NFCStatus.enabled) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            _buildTipSection(context),
          ],
        ],
      ),
    );
  }

  String _getInstructionTitle() {
    switch (nfcStatus) {
      case NFCStatus.enabled:
        return isScanning ? 'Scanning for NFC Cards' : 'How to Scan NFC Cards';
      case NFCStatus.reading:
        return 'Reading Card Data';
      case NFCStatus.writing:
        return 'Writing to Card';
      case NFCStatus.disabled:
        return 'NFC is Disabled';
      case NFCStatus.notAvailable:
        return 'NFC Not Available';
      case NFCStatus.error:
        return 'NFC Error';
    }
  }

  List<Widget> _buildInstructionSteps(BuildContext context) {
    List<Map<String, dynamic>> steps = [];

    switch (nfcStatus) {
      case NFCStatus.enabled:
        if (isScanning) {
          steps = [
            {
              'number': '1',
              'title': 'Hold your card steady',
              'description': 'Place the NFC card close to the back of your device',
              'icon': Icons.credit_card,
            },
            {
              'number': '2',
              'title': 'Keep it close',
              'description': 'Maintain contact until scanning completes',
              'icon': Icons.touch_app,
            },
            {
              'number': '3',
              'title': 'Wait for confirmation',
              'description': 'You\'ll see a success message when done',
              'icon': Icons.check_circle,
            },
          ];
        } else {
          steps = [
            {
              'number': '1',
              'title': 'Prepare your NFC card',
              'description': 'Make sure your card supports NFC technology',
              'icon': Icons.nfc,
            },
            {
              'number': '2',
              'title': 'Position your device',
              'description': 'Find the NFC antenna (usually on the back)',
              'icon': Icons.smartphone,
            },
            {
              'number': '3',
              'title': 'Tap to start',
              'description': 'Press the scan button and place your card',
              'icon': Icons.touch_app,
            },
          ];
        }
        break;

      case NFCStatus.reading:
        steps = [
          {
            'number': '',
            'title': 'Reading in progress...',
            'description': 'Keep the card steady until reading completes',
            'icon': Icons.search,
          },
        ];
        break;

      case NFCStatus.writing:
        steps = [
          {
            'number': '',
            'title': 'Writing data...',
            'description': 'Do not remove the card during writing process',
            'icon': Icons.edit,
          },
        ];
        break;

      case NFCStatus.disabled:
        steps = [
          {
            'number': '1',
            'title': 'Enable NFC',
            'description': 'Go to Settings → Connected devices → NFC',
            'icon': Icons.settings,
          },
          {
            'number': '2',
            'title': 'Toggle NFC ON',
            'description': 'Make sure the NFC switch is enabled',
            'icon': Icons.toggle_on,
          },
          {
            'number': '3',
            'title': 'Return to app',
            'description': 'Come back and try scanning again',
            'icon': Icons.arrow_back,
          },
        ];
        break;

      case NFCStatus.notAvailable:
        steps = [
          {
            'number': '',
            'title': 'Demo Mode Available',
            'description': 'Your device doesn\'t support NFC, but you can try demo mode to explore features',
            'icon': Icons.play_arrow,
          },
        ];
        break;

      case NFCStatus.error:
        steps = [
          {
            'number': '',
            'title': 'Something went wrong',
            'description': 'Please check your NFC settings and try again',
            'icon': Icons.refresh,
          },
        ];
        break;
    }

    return steps.map((step) => _buildInstructionStep(context, step)).toList();
  }

  Widget _buildInstructionStep(BuildContext context, Map<String, dynamic> step) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Row(
        children: [
          // Step number or icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: step['number'].isNotEmpty
                ? Center(
                    child: Text(
                      step['number'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Icon(
                    step['icon'],
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
          ),
          
          const SizedBox(width: AppConstants.defaultPadding),
          
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Different devices have NFC antennas in different locations. Try the center-back or top-back of your phone.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}