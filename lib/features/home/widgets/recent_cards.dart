import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/nfc_card.dart';
import '../../cards/providers/cards_provider.dart';
import '../../nfc/providers/nfc_provider.dart';

class RecentCards extends StatelessWidget {
  const RecentCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CardsProvider>(
      builder: (context, cardsProvider, _) {
        final recentCards = cardsProvider.recentCards.take(3).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Cards',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (cardsProvider.cards.isNotEmpty)
                      TextButton(
                        onPressed: () => AppRoutes.navigateToCardsList(context),
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.smallPadding),
                
                if (recentCards.isEmpty) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.credit_card_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'No cards yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        ElevatedButton.icon(
                          onPressed: () => AppRoutes.navigateToNFCScanner(context),
                          icon: const Icon(Icons.nfc, size: 18),
                          label: const Text('Scan First Card'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                ] else ...[
                  ...recentCards.map((card) => _RecentCardTile(card: card)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentCardTile extends StatelessWidget {
  final NFCCard card;

  const _RecentCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final nfcProvider = context.read<NFCProvider>();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => AppRoutes.navigateToCardDetails(context, arguments: card),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCardTypeColor(card.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getCardTypeColor(card.type).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      _getCardTypeIcon(card.type),
                      color: _getCardTypeColor(card.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (card.status == CardStatus.favorite)
                              const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red,
                              ),
                            if (card.isCloned)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: const Text(
                                  'CLONE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          nfcProvider.getCardTypeDisplayName(card.type),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getCardTypeColor(card.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) => _handleAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility, size: 20),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clone',
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 20),
                          title: Text('Clone Card'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'favorite',
                        child: ListTile(
                          leading: Icon(Icons.favorite, size: 20),
                          title: Text('Toggle Favorite'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    card.formattedUID,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(card.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              if (card.description != null && card.description!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  card.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
        return Icons.nfc;
      case CardType.ntag:
        return Icons.contactless;
      case CardType.desfire:
        return Icons.security;
      case CardType.felica:
        return Icons.payment;
      case CardType.iso15693:
        return Icons.wifi;
      case CardType.iso14443A:
      case CardType.iso14443B:
        return Icons.badge;
      case CardType.unknown:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleAction(BuildContext context, String action) {
    final cardsProvider = context.read<CardsProvider>();
    
    switch (action) {
      case 'view':
        AppRoutes.navigateToCardDetails(context, arguments: card);
        break;
      case 'clone':
        AppRoutes.navigateToNFCScanner(context);
        break;
      case 'favorite':
        cardsProvider.toggleFavorite(card.id);
        break;
    }
  }
}