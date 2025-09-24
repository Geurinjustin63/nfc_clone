import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/themes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/nfc_card.dart';
import '../../cards/providers/cards_provider.dart';
import '../../cards/widgets/card_preview_item.dart';
import '../../cards/screens/cards_list_screen.dart';

class RecentCardsSection extends StatelessWidget {
  const RecentCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CardsProvider>(
      builder: (context, cardsProvider, child) {
        final recentCards = cardsProvider.recentCards.take(5).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Cards',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      'Last ${recentCards.length} scanned cards',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                if (cardsProvider.cards.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CardsListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            if (recentCards.isEmpty)
              _buildEmptyState(context)
            else
              _buildCardsList(context, recentCards),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off,
            size: 48,
            color: AppColors.textHint,
          ),
          
          const SizedBox(height: AppConstants.smallPadding),
          
          Text(
            'No cards found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Scan your first NFC card to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.defaultPadding),
          
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to NFC scanner
            },
            icon: const Icon(Icons.nfc),
            label: const Text('Scan NFC Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(BuildContext context, List<NFCCard> cards) {
    return Column(
      children: [
        // Show first 3 cards as full preview items
        ...cards.take(3).map((card) => Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: CardPreviewItem(
            card: card,
            onTap: () {
              // Navigate to card details
            },
          ),
        )),
        
        // Show remaining cards as compact items
        if (cards.length > 3) ...[
          const SizedBox(height: AppConstants.smallPadding),
          
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: AppColors.textHint.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: cards.skip(3).map((card) => _buildCompactCardItem(
                context,
                card,
                cards.skip(3).toList().indexOf(card) < cards.skip(3).length - 1,
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactCardItem(BuildContext context, NFCCard card, bool showDivider) {
    return InkWell(
      onTap: () {
        // Navigate to card details
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Card type icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getCardTypeColor(card.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCardTypeIcon(card.type),
                    size: 16,
                    color: _getCardTypeColor(card.type),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        card.formattedUID,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Timestamp
                Text(
                  _formatTimestamp(card.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                
                const SizedBox(width: AppConstants.smallPadding),
                
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
            
            if (showDivider) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Divider(
                height: 1,
                color: AppColors.textHint.withOpacity(0.2),
              ),
            ],
          ],
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}