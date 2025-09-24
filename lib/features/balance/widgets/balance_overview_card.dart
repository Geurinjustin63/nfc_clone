import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/balance_provider.dart';
import '../../../app/themes.dart';

class BalanceOverviewCard extends StatelessWidget {
  final BalanceProvider provider;

  const BalanceOverviewCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryVariant,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.textOnPrimary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatTotalBalance(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: AppColors.textOnPrimary.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${provider.totalCards} cards with balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.8),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.statistics.isNotEmpty) _buildStatistics(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final stats = provider.statistics;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            'This Month',
            _formatCurrency(stats['total_spent_this_month']?.toDouble() ?? 0),
            'Spent',
            AppColors.textOnPrimary.withOpacity(0.9),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: AppColors.textOnPrimary.withOpacity(0.3),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            'This Month',
            _formatCurrency(stats['total_added_this_month']?.toDouble() ?? 0),
            'Added',
            AppColors.textOnPrimary.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String sublabel,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          sublabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  String _formatTotalBalance() {
    if (provider.balances.isEmpty) {
      return '\$0.00';
    }

    // Group balances by currency
    final balancesByCurrency = provider.balanceByCurrency;
    
    if (balancesByCurrency.length == 1) {
      final entry = balancesByCurrency.entries.first;
      return NumberFormat.currency(
        locale: 'en_US',
        symbol: entry.key.symbol,
        decimalDigits: entry.key.decimalPlaces,
      ).format(entry.value);
    }

    // Multiple currencies - show USD equivalent (simplified)
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ).format(provider.totalBalance);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ).format(amount);
  }
}