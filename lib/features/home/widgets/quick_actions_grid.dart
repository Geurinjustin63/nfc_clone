import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../../nfc/providers/nfc_provider.dart';
import '../../settings/providers/settings_provider.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppConstants.smallPadding,
          mainAxisSpacing: AppConstants.smallPadding,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              context,
              icon: Icons.nfc,
              title: 'Scan NFC',
              subtitle: 'Read NFC cards',
              color: Colors.blue,
              onTap: () => _handleScanNFC(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.credit_card,
              title: 'My Cards',
              subtitle: 'View all cards',
              color: Colors.green,
              onTap: () => AppRoutes.navigateToCardsList(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.content_copy,
              title: 'Demo Clone',
              subtitle: 'Test cloning',
              color: Colors.purple,
              onTap: () => _handleDemoClone(context),
            ),
            _buildActionCard(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              subtitle: 'View statistics',
              color: Colors.orange,
              onTap: () => AppRoutes.navigateToAnalytics(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          // Haptic feedback
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          settings.performHapticFeedback();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScanNFC(BuildContext context) {
    final nfc = Provider.of<NFCProvider>(context, listen: false);
    
    if (!nfc.isAvailable) {
      _showNFCNotAvailableDialog(context);
      return;
    }
    
    if (nfc.isReading || nfc.isWriting) {
      _showNFCBusyDialog(context);
      return;
    }
    
    AppRoutes.navigateToNFCScanner(context);
  }

  void _handleDemoClone(BuildContext context) {
    final nfc = Provider.of<NFCProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.science,
              color: Colors.purple,
            ),
            const SizedBox(width: 8),
            const Text('Demo Clone'),
          ],
        ),
        content: const Text(
          'This will demonstrate the cloning process using simulated NFC data. '
          'No actual cards will be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              settings.performHapticFeedback();
              
              // Simulate demo cloning process
              try {
                final demoReadResult = await nfc.readDemoCard();
                if (demoReadResult.success && demoReadResult.card != null) {
                  await nfc.cloneDemoCard(demoReadResult.card!);
                  
                  if (context.mounted) {
                    settings.performSuccessHaptic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Demo clone completed successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  throw Exception('Failed to read demo card');
                }
              } catch (e) {
                if (context.mounted) {
                  settings.performErrorHaptic();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Demo clone failed: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Demo'),
          ),
        ],
      ),
    );
  }

  void _showNFCNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('NFC Not Available'),
          ],
        ),
        content: const Text(
          'NFC is not available on this device or is currently disabled. '
          'You can use the demo mode to test the app functionality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDemoClone(context);
            },
            child: const Text('Try Demo'),
          ),
        ],
      ),
    );
  }

  void _showNFCBusyDialog(BuildContext context) {
    final nfc = Provider.of<NFCProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Text('NFC Busy'),
          ],
        ),
        content: Text(
          'NFC is currently ${nfc.isReading ? 'reading' : 'writing'} a card. '
          'Please wait for the current operation to complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              nfc.stopCurrentOperation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Operation'),
          ),
        ],
      ),
    );
  }
}