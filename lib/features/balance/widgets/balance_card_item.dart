import 'package:flutter/material.dart';
import '../../../core/models/card_balance.dart';
import '../../../app/themes.dart';

class BalanceCardItem extends StatelessWidget {
  final CardBalance balance;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onDelete;

  const BalanceCardItem({
    super.key,
    required this.balance,
    this.onTap,
    this.onRefresh,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getBalanceTypeColor().withOpacity(0.1),
                _getBalanceTypeColor().withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getBalanceTypeColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getBalanceTypeIcon(),
                      color: _getBalanceTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.balanceTypeDisplayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated ${_formatLastUpdated()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Refresh'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance.formattedBalance,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: balance.isLowBalance ? AppColors.error : AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  if (balance.hasBalanceChanged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: balance.balanceChange! > 0 
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            balance.balanceChange! > 0 
                                ? Icons.trending_up 
                                : Icons.trending_down,
                            size: 16,
                            color: balance.balanceChange! > 0 
                                ? AppColors.success 
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            balance.formattedBalanceChange,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: balance.balanceChange! > 0 
                                      ? AppColors.success 
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    'Confidence',
                    balance.confidenceDescription,
                    balance.isReliable ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  if (balance.isLowBalance)
                    _buildInfoChip(
                      'Status',
                      'Low Balance',
                      AppColors.error,
                    ),
                  if (balance.isZeroBalance)
                    _buildInfoChip(
                      'Status',
                      'Empty',
                      AppColors.textSecondary,
                    ),
                ],
              ),
              if (balance.balanceSource != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Source: ${balance.balanceSource}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getBalanceTypeColor() {
    switch (balance.balanceType) {
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

  IconData _getBalanceTypeIcon() {
    switch (balance.balanceType) {
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

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(balance.lastUpdated);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        onRefresh?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}