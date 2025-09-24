import 'package:flutter/material.dart';
import '../providers/balance_provider.dart';
import '../../../core/models/card_transaction.dart';
import '../../../app/themes.dart';

class RecentTransactionsList extends StatelessWidget {
  final BalanceProvider provider;
  final int? limit;
  final bool showAll;
  final VoidCallback? onViewAll;

  const RecentTransactionsList({
    super.key,
    required this.provider,
    this.limit,
    this.showAll = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final transactions = showAll 
        ? provider.transactions 
        : provider.transactions.take(limit ?? 5).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  showAll ? 'All Transactions' : 'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (!showAll && onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map((transaction) => _buildTransactionItem(context, transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, CardTransaction transaction) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getTransactionColor(transaction).withOpacity(0.1),
        ),
        child: Icon(
          _getTransactionIcon(transaction),
          color: _getTransactionColor(transaction),
          size: 20,
        ),
      ),
      title: Text(
        transaction.typeDisplayName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.description != null)
            Text(
              transaction.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                transaction.formattedTimestamp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (transaction.isEstimated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ESTIMATED',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            transaction.formattedAmount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _getTransactionColor(transaction),
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (transaction.balanceAfter != null)
            Text(
              'Balance: ${transaction.formattedBalanceAfter}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
        ],
      ),
      onTap: () => _showTransactionDetails(context, transaction),
    );
  }

  Color _getTransactionColor(CardTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.debit:
      case TransactionType.fee:
      case TransactionType.penalty:
        return AppColors.error;
      case TransactionType.credit:
      case TransactionType.reload:
      case TransactionType.refund:
      case TransactionType.bonus:
        return AppColors.success;
      case TransactionType.transfer:
        return AppColors.info;
      case TransactionType.unknown:
        return AppColors.textSecondary;
    }
  }

  IconData _getTransactionIcon(CardTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.debit:
        return Icons.remove_circle_outline;
      case TransactionType.credit:
        return Icons.add_circle_outline;
      case TransactionType.reload:
        return Icons.refresh;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.fee:
        return Icons.receipt;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.penalty:
        return Icons.warning;
      case TransactionType.bonus:
        return Icons.star;
      case TransactionType.unknown:
        return Icons.help_outline;
    }
  }

  void _showTransactionDetails(BuildContext context, CardTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _getTransactionIcon(transaction),
              color: _getTransactionColor(transaction),
            ),
            const SizedBox(width: 8),
            Text('Transaction Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', transaction.typeDisplayName),
              _buildDetailRow('Amount', transaction.formattedAmount),
              if (transaction.balanceBefore != null)
                _buildDetailRow('Balance Before', transaction.formattedBalanceBefore),
              if (transaction.balanceAfter != null)
                _buildDetailRow('Balance After', transaction.formattedBalanceAfter),
              _buildDetailRow('Date & Time', transaction.formattedTimestamp),
              if (transaction.description != null)
                _buildDetailRow('Description', transaction.description!),
              if (transaction.location != null)
                _buildDetailRow('Location', transaction.location!),
              if (transaction.merchantInfo != null)
                _buildDetailRow('Merchant', transaction.merchantInfo!),
              if (transaction.transactionId != null)
                _buildDetailRow('Transaction ID', transaction.transactionId!),
              if (transaction.source != null)
                _buildDetailRow('Source', transaction.source!),
              if (transaction.isEstimated)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This transaction is estimated based on balance changes',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.warning,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
}