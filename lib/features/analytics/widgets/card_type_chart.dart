import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/nfc_card.dart';
import '../../cards/providers/cards_provider.dart';
import '../../../app/themes.dart';

class CardTypeChart extends StatelessWidget {
  final CardsProvider cardsProvider;

  const CardTypeChart({
    super.key,
    required this.cardsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final distribution = cardsProvider.getCardTypeDistribution();
    
    if (distribution.isEmpty) {
      return Center(
        child: Text(
          'No card data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final sections = _createPieChartSections(distribution);
    final totalCards = distribution.values.fold<int>(0, (sum, count) => sum + count);

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch events if needed
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: distribution.entries.map((entry) {
            final percentage = (entry.value / totalCards * 100).toStringAsFixed(1);
            return _buildLegendItem(
              context,
              _getCardTypeColor(entry.key),
              _getCardTypeDisplayName(entry.key),
              '${entry.value} ($percentage%)',
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createPieChartSections(Map<CardType, int> distribution) {
    final totalCards = distribution.values.fold<int>(0, (sum, count) => sum + count);
    
    return distribution.entries.map((entry) {
      final percentage = entry.value / totalCards * 100;
      return PieChartSectionData(
        color: _getCardTypeColor(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 50,
        showTitle: percentage > 5, // Only show title if slice is large enough
      );
    }).toList();
  }

  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getCardTypeColor(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return Colors.blue;
      case CardType.mifareUltralight:
        return Colors.green;
      case CardType.ntag:
        return Colors.orange;
      case CardType.desfire:
        return Colors.purple;
      case CardType.felica:
        return Colors.red;
      case CardType.iso15693:
        return Colors.teal;
      case CardType.iso14443A:
        return Colors.indigo;
      case CardType.iso14443B:
        return Colors.amber;
      case CardType.unknown:
        return Colors.grey;
    }
  }

  String _getCardTypeDisplayName(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return 'MIFARE Classic';
      case CardType.mifareUltralight:
        return 'MIFARE Ultralight';
      case CardType.ntag:
        return 'NTAG';
      case CardType.desfire:
        return 'DESFire';
      case CardType.felica:
        return 'FeliCa';
      case CardType.iso15693:
        return 'ISO 15693';
      case CardType.iso14443A:
        return 'ISO 14443-A';
      case CardType.iso14443B:
        return 'ISO 14443-B';
      case CardType.unknown:
        return 'Unknown';
    }
  }
}