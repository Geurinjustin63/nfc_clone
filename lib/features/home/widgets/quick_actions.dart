import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.nfc,
                    label: 'Scan Card',
                    color: Colors.blue,
                    onTap: () => AppRoutes.navigateToNFCScanner(context),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.credit_card,
                    label: 'View Cards',
                    color: Colors.green,
                    onTap: () => AppRoutes.navigateToCardsList(context),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    color: Colors.orange,
                    onTap: () => AppRoutes.navigateToAnalytics(context),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    color: Colors.purple,
                    onTap: () => AppRoutes.navigateToSettings(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.defaultPadding,
          horizontal: AppConstants.smallPadding,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}