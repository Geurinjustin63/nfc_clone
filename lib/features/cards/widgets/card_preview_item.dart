import 'package:flutter/material.dart';
import '../../../app/themes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/nfc_card.dart';

class CardPreviewItem extends StatelessWidget {
  final NFCCard card;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDetails;
  final bool isSelected;

  const CardPreviewItem({
    super.key,
    required this.card,
    this.onTap,
    this.onLongPress,
    this.showDetails = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: isSelected 
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            gradient: LinearGradient(
              colors: [
                _getCardTypeColor(card.type).withOpacity(0.05),
                _getCardTypeColor(card.type).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Card type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCardTypeColor(card.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCardTypeIcon(card.type),
                      color: _getCardTypeColor(card.type),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.smallPadding),
                  
                  // Card info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 2),
                        
                        Text(
                          _getCardTypeDisplayName(card.type),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCardTypeColor(card.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (card.isCloned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.nfcCloning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CLONED',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.nfcCloning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      if (card.status == CardStatus.favorite) ...[
                        if (card.isCloned) const SizedBox(width: 4),
                        Icon(
                          Icons.favorite,
                          color: AppColors.warning,
                          size: 16,
                        ),
                      ],
                      
                      if (card.hasNDEFData) ...[
                        if (card.isCloned || card.status == CardStatus.favorite) 
                          const SizedBox(width: 4),
                        Icon(
                          Icons.label,
                          color: AppColors.info,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              if (showDetails) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Card details
                Container(
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textHint.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // UID
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'UID:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              card.formattedUID,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Standard & Size
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${card.standard} • ${card.sizeInBytes} bytes',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          
                          // Timestamp
                          Text(
                            _formatDate(card.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      
                      // Description (if available)
                      if (card.description != null && card.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.description,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                card.description!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Tags (if available)
                      if (card.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: card.tags.take(3).map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            
                            if (card.tags.length > 3)
                              Text(
                                '+${card.tags.length - 3}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardTypeColor(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return AppColors.primary;
      case CardType.mifareUltralight:
        return AppColors.info;
      case CardType.ntag:
        return AppColors.success;
      case CardType.desfire:
        return AppColors.nfcCloning;
      case CardType.felica:
        return AppColors.warning;
      case CardType.iso15693:
        return AppColors.secondary;
      case CardType.iso14443A:
        return AppColors.error;
      case CardType.iso14443B:
        return AppColors.textSecondary;
      case CardType.unknown:
        return AppColors.textHint;
    }
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return Icons.credit_card;
      case CardType.mifareUltralight:
        return Icons.contactless;
      case CardType.ntag:
        return Icons.nfc;
      case CardType.desfire:
        return Icons.security;
      case CardType.felica:
        return Icons.account_balance_wallet;
      case CardType.iso15693:
        return Icons.loyalty;
      case CardType.iso14443A:
      case CardType.iso14443B:
        return Icons.payment;
      case CardType.unknown:
        return Icons.help_outline;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}