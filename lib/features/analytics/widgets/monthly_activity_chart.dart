import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../cards/providers/cards_provider.dart';
import '../../../app/themes.dart';

class MonthlyActivityChart extends StatelessWidget {
  final CardsProvider cardsProvider;

  const MonthlyActivityChart({
    super.key,
    required this.cardsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final monthlyData = _generateMonthlyData();
    
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          'No activity data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textHint.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= monthlyData.length) {
                  return const Text('');
                }
                return Text(
                  monthlyData[index].month,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
            bottom: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: monthlyData
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.count.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: _getMaxValue(monthlyData) * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.darkSurface,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.spotIndex;
                if (index < monthlyData.length) {
                  final data = monthlyData[index];
                  return LineTooltipItem(
                    '${data.month}\n${data.count} cards',
                    TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<MonthlyData> _generateMonthlyData() {
    // Generate dummy data for the last 12 months
    final now = DateTime.now();
    final data = <MonthlyData>[];
    
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(date.month);
      
      // For demo purposes, generate some sample data
      // In real implementation, this would come from the database
      final count = _getCardCountForMonth(date);
      
      data.add(MonthlyData(
        month: monthName,
        count: count,
        date: date,
      ));
    }
    
    return data;
  }

  int _getCardCountForMonth(DateTime month) {
    // This is demo data - in real implementation, query the database
    // for cards created in this month
    final cards = cardsProvider.allCards.where((card) {
      return card.createdAt.year == month.year &&
             card.createdAt.month == month.month;
    }).toList();
    
    return cards.length;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  double _getMaxValue(List<MonthlyData> data) {
    if (data.isEmpty) return 10;
    return data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();
  }
}

class MonthlyData {
  final String month;
  final int count;
  final DateTime date;

  MonthlyData({
    required this.month,
    required this.count,
    required this.date,
  });
}