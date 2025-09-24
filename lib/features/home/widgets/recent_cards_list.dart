import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/nfc_card.dart';
import '../../../app/routes.dart';
import '../../cards/providers/cards_provider.dart';
import '../../settings/providers/settings_provider.dart';

class RecentCardsList extends StatelessWidget {
  const RecentCardsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CardsProvider>(
      builder: (context, cards, child) {
        if (cards.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.largePadding),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (cards.recentCards.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: cards.recentCards.take(5).map((card) {
            return _buildCardItem(context, card);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No cards yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Scan your first NFC card to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: () => AppRoutes.navigateToNFCScanner(context),
              icon: const Icon(Icons.nfc),
              label: const Text('Scan NFC Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, NFCCard card) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          settings.performHapticFeedback();
          AppRoutes.navigateToCardDetails(context, arguments: card);
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // Card Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCardTypeColor(card.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCardTypeIcon(card.type),
                  color: _getCardTypeColor(card.type),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: AppConstants.defaultPadding),
              
              // Card Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (card.isCloned)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CLONE',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (card.status == CardStatus.favorite)
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Text(
                          _getCardTypeDisplayName(card.type),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCardTypeColor(card.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          'UID: ${card.formattedUID}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(card.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (card.readCount > 1) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${card.readCount} reads',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Button
              IconButton(
                onPressed: () => _showCardActions(context, card),
                icon: const Icon(Icons.more_vert),
                iconSize: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardActions(BuildContext context, NFCCard card) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.performHapticFeedback();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Card info header
            Row(
              children: [
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getCardTypeDisplayName(card.type),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getCardTypeColor(card.type),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateToCardDetails(context, arguments: card);
              },
            ),
            
            ListTile(
              leading: Icon(
                card.status == CardStatus.favorite ? Icons.favorite : Icons.favorite_border,
                color: card.status == CardStatus.favorite ? Colors.red : null,
              ),
              title: Text(card.status == CardStatus.favorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () async {
                Navigator.pop(context);
                final cardsProvider = Provider.of<CardsProvider>(context, listen: false);
                await cardsProvider.toggleFavorite(card);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        card.status == CardStatus.favorite 
                            ? 'Added to favorites' 
                            : 'Removed from favorites',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Card'),
              onTap: () async {
                Navigator.pop(context);
                final cardsProvider = Provider.of<CardsProvider>(context, listen: false);
                try {
                  await cardsProvider.shareCard(card);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to share card: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
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
      case CardType.iso14443B:
        return Colors.indigo;
      case CardType.unknown:
        return Colors.grey;
    }
  }

  IconData _getCardTypeIcon(CardType type) {
    switch (type) {
      case CardType.mifareClassic:
        return Icons.credit_card;
      case CardType.mifareUltralight:
        return Icons.card_membership;
      case CardType.ntag:
        return Icons.nfc;
      case CardType.desfire:
        return Icons.security;
      case CardType.felica:
        return Icons.contactless;
      case CardType.iso15693:
        return Icons.radio;
      case CardType.iso14443A:
      case CardType.iso14443B:
        return Icons.badge;
      case CardType.unknown:
        return Icons.help;
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}