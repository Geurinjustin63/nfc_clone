import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/balance_provider.dart';
import '../../../core/models/card_balance.dart';
import '../../../app/themes.dart';

class BalanceChart extends StatefulWidget {
  final BalanceProvider provider;

  const BalanceChart({
    super.key,
    required this.provider,
  });

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  int _selectedTimeRange = 0; // 0: 7 days, 1: 30 days, 2: 90 days
  bool _showSpending = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                _getTimeRangeText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('7D'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('30D'),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('90D'),
                ),
              ],
              selected: {_selectedTimeRange},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _selectedTimeRange = selection.first;
                });
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _showSpending = !_showSpending;
                });
              },
              icon: Icon(
                _showSpending ? Icons.trending_down : Icons.trending_up,
                color: _showSpending ? AppColors.error : AppColors.success,
              ),
              tooltip: _showSpending ? 'Show Income' : 'Show Spending',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart() {
    final chartData = _generateChartData();
    
    if (chartData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'No transaction data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
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
                  if (index < 0 || index >= chartData.length) {
                    return const Text('');
                  }
                  return Text(
                    chartData[index].dateLabel,
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
            if (_showSpending)
              LineChartBarData(
                spots: chartData
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.spentAmount,
                        ))
                    .toList(),
                isCurved: true,
                color: AppColors.error,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.error,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.error.withOpacity(0.1),
                ),
              )
            else
              LineChartBarData(
                spots: chartData
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(
                          entry.key.toDouble(),
                          entry.value.addedAmount,
                        ))
                    .toList(),
                isCurved: true,
                color: AppColors.success,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.success,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.success.withOpacity(0.1),
                ),
              ),
          ],
          minY: 0,
          maxY: _getMaxValue(chartData) * 1.2,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.darkSurface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.spotIndex;
                  if (index < chartData.length) {
                    final data = chartData[index];
                    final value = _showSpending ? data.spentAmount : data.addedAmount;
                    final label = _showSpending ? 'Spent' : 'Added';
                    return LineTooltipItem(
                      '${data.dateLabel}\n$label: \$${value.toStringAsFixed(2)}',
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
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(
          AppColors.error,
          'Spending',
          _showSpending,
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          AppColors.success,
          'Income',
          !_showSpending,
        ),
        const Spacer(),
        Text(
          'Total ${_getTotalValue().toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  List<ChartData> _generateChartData() {
    final now = DateTime.now();
    final days = _getDaysForTimeRange();
    final data = <ChartData>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayTransactions = widget.provider.transactions.where((transaction) =>
          transaction.timestamp.isAfter(dayStart) &&
          transaction.timestamp.isBefore(dayEnd)
      ).toList();

      final spentAmount = dayTransactions
          .where((t) => t.isDebit)
          .fold(0.0, (sum, t) => sum + t.amount);

      final addedAmount = dayTransactions
          .where((t) => t.isCredit)
          .fold(0.0, (sum, t) => sum + t.amount);

      data.add(ChartData(
        date: date,
        dateLabel: _formatDateLabel(date),
        spentAmount: spentAmount,
        addedAmount: addedAmount,
        transactionCount: dayTransactions.length,
      ));
    }

    return data;
  }

  int _getDaysForTimeRange() {
    switch (_selectedTimeRange) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      default:
        return 7;
    }
  }

  String _getTimeRangeText() {
    switch (_selectedTimeRange) {
      case 0:
        return 'Last 7 days';
      case 1:
        return 'Last 30 days';
      case 2:
        return 'Last 90 days';
      default:
        return 'Last 7 days';
    }
  }

  String _formatDateLabel(DateTime date) {
    switch (_selectedTimeRange) {
      case 0: // 7 days - show day of week
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[date.weekday - 1];
      case 1: // 30 days - show day/month
        return '${date.day}/${date.month}';
      case 2: // 90 days - show month
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[date.month - 1];
      default:
        return '${date.day}';
    }
  }

  double _getMaxValue(List<ChartData> data) {
    if (data.isEmpty) return 100;
    
    final maxSpent = data.map((d) => d.spentAmount).reduce((a, b) => a > b ? a : b);
    final maxAdded = data.map((d) => d.addedAmount).reduce((a, b) => a > b ? a : b);
    
    return _showSpending ? maxSpent : maxAdded;
  }

  double _getTotalValue() {
    final chartData = _generateChartData();
    if (chartData.isEmpty) return 0;

    if (_showSpending) {
      return chartData.fold(0.0, (sum, data) => sum + data.spentAmount);
    } else {
      return chartData.fold(0.0, (sum, data) => sum + data.addedAmount);
    }
  }
}

class ChartData {
  final DateTime date;
  final String dateLabel;
  final double spentAmount;
  final double addedAmount;
  final int transactionCount;

  ChartData({
    required this.date,
    required this.dateLabel,
    required this.spentAmount,
    required this.addedAmount,
    required this.transactionCount,
  });
}