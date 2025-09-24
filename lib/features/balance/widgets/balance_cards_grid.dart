import 'package:flutter/material.dart';
import '../providers/balance_provider.dart';
import '../../../core/models/card_balance.dart';
import '../../../app/themes.dart';
import 'balance_card_item.dart';

class BalanceCardsGrid extends StatelessWidget {
  final BalanceProvider provider;

  const BalanceCardsGrid({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final balances = provider.balances;

    if (balances.isEmpty) {
      return _buildEmptyView(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: balances.length,
      itemBuilder: (context, index) {
        final balance = balances[index];
        return BalanceCardItem(
          balance: balance,
          onTap: () => _showBalanceDetails(context, balance),
          onRefresh: () => _refreshBalance(context, balance),
          onDelete: () => _deleteBalance(context, balance),
        );
      },
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No Balance Data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan NFC cards to check balances',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showBalanceDetails(BuildContext context, CardBalance balance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getBalanceTypeColor(balance.balanceType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getBalanceTypeIcon(balance.balanceType),
                        color: _getBalanceTypeColor(balance.balanceType),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            balance.balanceTypeDisplayName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            balance.formattedBalance,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: _getBalanceTypeColor(balance.balanceType),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                          context,
                          'Balance Information',
                          [
                            _buildDetailRow('Current Balance', balance.formattedBalance),
                            if (balance.previousBalance != null)
                              _buildDetailRow('Previous Balance', 
                                NumberFormat.currency(
                                  symbol: balance.currency.symbol,
                                  decimalDigits: balance.currency.decimalPlaces,
                                ).format(balance.previousBalance!)),
                            if (balance.hasBalanceChanged)
                              _buildDetailRow('Change', balance.formattedBalanceChange),
                            _buildDetailRow('Currency', balance.currency.code),
                            _buildDetailRow('Type', balance.balanceTypeDisplayName),
                            _buildDetailRow('Last Updated', balance.lastUpdated.toString()),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildDetailSection(
                          context,
                          'Technical Information',
                          [
                            _buildDetailRow('Confidence', balance.confidenceDescription),
                            if (balance.balanceSource != null)
                              _buildDetailRow('Data Source', balance.balanceSource!),
                            _buildDetailRow('Encrypted', balance.isEncrypted ? 'Yes' : 'No'),
                            if (balance.lastTransactionId != null)
                              _buildDetailRow('Last Transaction', balance.lastTransactionId!),
                          ],
                        ),
                        
                        if (balance.isLowBalance) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Low Balance Warning',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        'This card has a low balance. Consider topping up.',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppColors.warning,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _refreshBalance(context, balance);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textHint.withOpacity(0.3)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBalanceTypeColor(BalanceType type) {
    switch (type) {
      case BalanceType.transit:
        return Colors.blue;
      case BalanceType.payment:
        return Colors.green;
      case BalanceType.gift:
        return Colors.orange;
      case BalanceType.loyalty:
        return Colors.purple;
      case BalanceType.parking:
        return Colors.indigo;
      case BalanceType.campus:
        return Colors.teal;
      case BalanceType.healthcare:
        return Colors.red;
      case BalanceType.prepaid:
        return Colors.amber;
      case BalanceType.unknown:
        return Colors.grey;
    }
  }

  IconData _getBalanceTypeIcon(BalanceType type) {
    switch (type) {
      case BalanceType.transit:
        return Icons.train;
      case BalanceType.payment:
        return Icons.payment;
      case BalanceType.gift:
        return Icons.card_giftcard;
      case BalanceType.loyalty:
        return Icons.stars;
      case BalanceType.parking:
        return Icons.local_parking;
      case BalanceType.campus:
        return Icons.school;
      case BalanceType.healthcare:
        return Icons.medical_services;
      case BalanceType.prepaid:
        return Icons.prepaid;
      case BalanceType.unknown:
        return Icons.help_outline;
    }
  }

  Future<void> _refreshBalance(BuildContext context, CardBalance balance) async {
    try {
      await provider.refreshBalance(balance.cardId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Balance refreshed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh balance: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}