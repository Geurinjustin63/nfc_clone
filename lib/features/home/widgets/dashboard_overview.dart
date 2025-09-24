import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../cards/providers/cards_provider.dart';
import '../../nfc/providers/nfc_provider.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Consumer2<CardsProvider, NFCProvider>(
              builder: (context, cardsProvider, nfcProvider, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewCard(
                            title: 'Total Cards',
                            value: '${cardsProvider.cards.length}',
                            icon: Icons.credit_card,
                            color: Colors.blue,
                            onTap: () {
                              // Navigate to cards tab
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: _OverviewCard(
                            title: 'Favorites',
                            value: '${cardsProvider.favoriteCards.length}',
                            icon: Icons.favorite,
                            color: Colors.red,
                            onTap: () {
                              // Navigate to favorites
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Row(
                      children: [
                        Expanded(
                          child: _OverviewCard(
                            title: 'Successful Reads',
                            value: '${nfcProvider.successfulReads}',
                            icon: Icons.search,
                            color: Colors.green,
                            onTap: () {
                              // Show read statistics
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: _OverviewCard(
                            title: 'Success Rate',
                            value: '${(nfcProvider.readSuccessRate * 100).toInt()}%',
                            icon: Icons.analytics,
                            color: Colors.orange,
                            onTap: () {
                              // Navigate to analytics
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _OverviewCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}