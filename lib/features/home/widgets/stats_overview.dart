import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/themes.dart';
import '../../../core/constants/app_constants.dart';
import '../../cards/providers/cards_provider.dart';
import '../../nfc/providers/nfc_provider.dart';

class StatsOverview extends StatelessWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CardsProvider, NFCProvider>(
      builder: (context, cardsProvider, nfcProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                IconButton(
                  onPressed: () {
                    // Navigate to detailed analytics
                  },
                  icon: const Icon(Icons.analytics),
                  iconSize: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            Text(
              'Quick overview of your NFC activity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Cards',
                    cardsProvider.cards.length.toString(),
                    Icons.credit_card,
                    AppColors.primary,
                    _buildCardTypeChart(cardsProvider.cardTypeDistribution),
                  ),
                ),
                
                const SizedBox(width: AppConstants.smallPadding),
                
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Success Rate',
                    '${(nfcProvider.readSuccessRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    _getSuccessRateColor(nfcProvider.readSuccessRate),
                    _buildSuccessRateChart(nfcProvider.readSuccessRate),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Favorites',
                    cardsProvider.favoriteCards.length.toString(),
                    Icons.favorite,
                    AppColors.warning,
                    _buildFavoritesIndicator(
                      cardsProvider.favoriteCards.length,
                      cardsProvider.cards.length,
                    ),
                  ),
                ),
                
                const SizedBox(width: AppConstants.smallPadding),
                
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Operations',
                    '${nfcProvider.successfulReads + nfcProvider.failedReads}',
                    Icons.nfc,
                    AppColors.info,
                    _buildOperationsChart(
                      nfcProvider.successfulReads,
                      nfcProvider.failedReads,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    Widget? chart,
  ) {
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
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                
                const Spacer(),
                
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            if (chart != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              SizedBox(
                height: 40,
                child: chart,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeChart(Map<CardType, int> distribution) {
    if (distribution.isEmpty) {
      return Container();
    }

    final sections = distribution.entries.map((entry) {
      return PieChartSectionData(
        color: _getCardTypeColor(entry.key),
        value: entry.value.toDouble(),
        title: '',
        radius: 8,
        titleStyle: const TextStyle(fontSize: 0),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 0,
        sectionsSpace: 1,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildSuccessRateChart(double successRate) {
    return LinearProgressIndicator(
      value: successRate,
      backgroundColor: AppColors.textHint.withOpacity(0.2),
      valueColor: AlwaysStoppedAnimation<Color>(
        _getSuccessRateColor(successRate),
      ),
      minHeight: 4,
    );
  }

  Widget _buildFavoritesIndicator(int favorites, int total) {
    if (total == 0) return Container();
    
    final ratio = favorites / total;
    return LinearProgressIndicator(
      value: ratio,
      backgroundColor: AppColors.textHint.withOpacity(0.2),
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
      minHeight: 4,
    );
  }

  Widget _buildOperationsChart(int successful, int failed) {
    if (successful + failed == 0) return Container();

    final total = successful + failed;
    final successRatio = successful / total;

    return Row(
      children: [
        Expanded(
          flex: successful,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        if (failed > 0) ...[
          const SizedBox(width: 1),
          Expanded(
            flex: failed,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getCardTypeColor(CardType type) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
      AppColors.nfcActive,
      AppColors.nfcCloning,
    ];
    
    return colors[type.index % colors.length];
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.8) return AppColors.success;
    if (rate >= 0.6) return AppColors.warning;
    return AppColors.error;
  }
}