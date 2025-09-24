import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/card_balance.dart';
import '../../../app/themes.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool showCardName;
  final bool showDate;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.showCardName = false,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTransactionIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTransactionInfo(context),
                  ),
                  _buildAmountDisplay(context),
                ],
              ),
              if (showCardName || _hasAdditionalInfo()) ...[
                const SizedBox(height: 12),
                _buildAdditionalInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getTransactionTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTransactionTypeIcon(),
        color: _getTransactionTypeColor(),
        size: 20,
      ),
    );
  }

  Widget _buildTransactionInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTransactionTitle(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _getTransactionSubtitle(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showDate) ...[
          const SizedBox(height: 2),
          Text(
            _formatTransactionDate(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildAmountDisplay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          transaction.formattedAmount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getTransactionTypeColor(),
                fontWeight: FontWeight.bold,
              ),
        ),
        if (transaction.status != TransactionStatus.completed) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              transaction.statusDisplayName,
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    return Row(
      children: [
        if (transaction.category != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  transaction.categoryDisplayName,
                  style: TextStyle(
                    color: _getCategoryColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (transaction.location != null) ...[
          Icon(
            Icons.location_on,
            color: AppColors.textSecondary,
            size: 12,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              transaction.location!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (transaction.isRecent) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'NEW',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasAdditionalInfo() {
    return transaction.category != null || 
           transaction.location != null || 
           transaction.isRecent;
  }

  String _getTransactionTitle() {
    if (transaction.merchantName != null) {
      return transaction.merchantName!;
    }
    
    if (transaction.description != null) {
      return transaction.description!;
    }
    
    return transaction.typeDisplayName;
  }

  String _getTransactionSubtitle() {
    if (transaction.merchantName != null && transaction.description != null) {
      return transaction.description!;
    }
    
    if (transaction.location != null) {
      return transaction.location!;
    }
    
    return transaction.typeDisplayName;
  }

  String _formatTransactionDate() {
    final now = DateTime.now();
    final transactionDate = transaction.timestamp;
    final difference = now.difference(transactionDate);

    if (difference.inDays == 0) {
      return 'Today at ${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';
    }
  }

  Color _getTransactionTypeColor() {
    switch (transaction.type) {
      case TransactionType.debit:
        return AppColors.error;
      case TransactionType.credit:
      case TransactionType.refund:
      case TransactionType.bonus:
        return AppColors.success;
      case TransactionType.fee:
        return AppColors.warning;
      case TransactionType.transfer:
      case TransactionType.topup:
        return AppColors.info;
      case TransactionType.unknown:
        return AppColors.textSecondary;
    }
  }

  IconData _getTransactionTypeIcon() {
    switch (transaction.type) {
      case TransactionType.debit:
        return Icons.remove_circle_outline;
      case TransactionType.credit:
      case TransactionType.refund:
      case TransactionType.bonus:
        return Icons.add_circle_outline;
      case TransactionType.fee:
        return Icons.warning_amber;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      case TransactionType.topup:
        return Icons.add_circle;
      case TransactionType.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return AppColors.error;
      case TransactionStatus.disputed:
        return AppColors.info;
    }
  }

  Color _getCategoryColor() {
    if (transaction.category == null) return AppColors.textSecondary;
    
    switch (transaction.category!) {
      case TransactionCategory.transport:
        return Colors.blue;
      case TransactionCategory.food:
      case TransactionCategory.restaurants:
      case TransactionCategory.coffee:
        return Colors.orange;
      case TransactionCategory.shopping:
      case TransactionCategory.groceries:
        return Colors.green;
      case TransactionCategory.entertainment:
        return Colors.purple;
      case TransactionCategory.healthcare:
        return Colors.red;
      case TransactionCategory.education:
        return Colors.indigo;
      case TransactionCategory.utilities:
        return Colors.teal;
      case TransactionCategory.fuel:
        return Colors.amber;
      case TransactionCategory.parking:
        return Colors.grey;
      case TransactionCategory.other:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon() {
    if (transaction.category == null) return Icons.category;
    
    switch (transaction.category!) {
      case TransactionCategory.transport:
        return Icons.directions_bus;
      case TransactionCategory.food:
      case TransactionCategory.restaurants:
        return Icons.restaurant;
      case TransactionCategory.coffee:
        return Icons.local_cafe;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.groceries:
        return Icons.shopping_cart;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.healthcare:
        return Icons.medical_services;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.utilities:
        return Icons.home;
      case TransactionCategory.fuel:
        return Icons.local_gas_station;
      case TransactionCategory.parking:
        return Icons.local_parking;
      case TransactionCategory.other:
        return Icons.category;
    }
  }
}