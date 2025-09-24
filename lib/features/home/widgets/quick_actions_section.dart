import 'package:flutter/material.dart';
import '../../../app/themes.dart';
import '../../../core/constants/app_constants.dart';
import '../../nfc/screens/nfc_scanner_screen.dart';
import '../../cards/screens/cards_list_screen.dart';
import '../../cards/screens/card_editor_screen.dart';
import '../../settings/screens/settings_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppConstants.smallPadding),
        
        Text(
          'Commonly used features for quick access',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppConstants.defaultPadding),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppConstants.smallPadding,
          mainAxisSpacing: AppConstants.smallPadding,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              context,
              'Scan NFC Card',
              'Read card data with NFC',
              Icons.nfc,
              AppColors.primary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NFCScannerScreen(),
                  ),
                );
              },
            ),
            
            _buildActionCard(
              context,
              'View All Cards',
              'Browse saved cards',
              Icons.credit_card,
              AppColors.info,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardsListScreen(),
                  ),
                );
              },
            ),
            
            _buildActionCard(
              context,
              'Create Card',
              'Manually create a card',
              Icons.add_card,
              AppColors.success,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CardEditorScreen(),
                  ),
                );
              },
            ),
            
            _buildActionCard(
              context,
              'Settings',
              'App configuration',
              Icons.settings,
              AppColors.textSecondary,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}