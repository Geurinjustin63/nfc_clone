import 'package:flutter/material.dart';
import '../../cards/providers/cards_provider.dart';
import '../../../app/themes.dart';

class StatisticsGrid extends StatelessWidget {
  final CardsProvider cardsProvider;

  const StatisticsGrid({
    super.key,
    required this.cardsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'Total Cards',
          cardsProvider.totalCards.toString(),
          Icons.credit_card,
          AppColors.primary,
        ),
        _buildStatCard(
          context,
          'Favorites',
          cardsProvider.getFavoriteCards().length.toString(),
          Icons.favorite,
          AppColors.error,
        ),
        _buildStatCard(
          context,
          'Recent',
          cardsProvider.getRecentCards(limit: 7).length.toString(),
          Icons.schedule,
          AppColors.success,
        ),
        _buildStatCard(
          context,
          'Most Read',
          _getMostReadCount().toString(),
          Icons.trending_up,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMostReadCount() {
    final mostReadCards = cardsProvider.getMostReadCards(limit: 1);
    return mostReadCards.isNotEmpty ? mostReadCards.first.readCount : 0;
  }
}