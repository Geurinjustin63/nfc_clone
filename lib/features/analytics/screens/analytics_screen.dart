import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/models/nfc_card.dart';
import '../../cards/providers/cards_provider.dart';
import '../../../app/themes.dart';
import '../widgets/card_type_chart.dart';
import '../widgets/monthly_activity_chart.dart';
import '../widgets/statistics_grid.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Cards', icon: Icon(Icons.credit_card)),
            Tab(text: 'Activity', icon: Icon(Icons.trending_up)),
          ],
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppColors.secondary,
        ),
      ),
      body: Consumer<CardsProvider>(
        builder: (context, cardsProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(cardsProvider),
              _buildCardsTab(cardsProvider),
              _buildActivityTab(cardsProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(CardsProvider cardsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatisticsGrid(cardsProvider: cardsProvider),
          const SizedBox(height: 24),
          _buildQuickStats(cardsProvider),
          const SizedBox(height: 24),
          _buildRecentActivity(cardsProvider),
        ],
      ),
    );
  }

  Widget _buildCardsTab(CardsProvider cardsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTypeDistribution(cardsProvider),
          const SizedBox(height: 24),
          _buildCardStatusBreakdown(cardsProvider),
          const SizedBox(height: 24),
          _buildTopCards(cardsProvider),
        ],
      ),
    );
  }

  Widget _buildActivityTab(CardsProvider cardsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthlyActivityChart(cardsProvider: cardsProvider),
          const SizedBox(height: 24),
          _buildReadingTrends(cardsProvider),
          const SizedBox(height: 24),
          _buildUsageStats(cardsProvider),
        ],
      ),
    );
  }

  Widget _buildQuickStats(CardsProvider cardsProvider) {
    final totalCards = cardsProvider.totalCards;
    final favoriteCards = cardsProvider.getFavoriteCards().length;
    final recentCards = cardsProvider.getRecentCards(limit: 7).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    'Total Cards',
                    totalCards.toString(),
                    Icons.credit_card,
                    AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    'Favorites',
                    favoriteCards.toString(),
                    Icons.favorite,
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    'This Week',
                    recentCards.toString(),
                    Icons.schedule,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardTypeDistribution(CardsProvider cardsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Types Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CardTypeChart(cardsProvider: cardsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStatusBreakdown(CardsProvider cardsProvider) {
    final statusDistribution = cardsProvider.getCardStatusDistribution();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Status Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...statusDistribution.entries.map((entry) {
              final percentage = cardsProvider.totalCards > 0
                  ? (entry.value / cardsProvider.totalCards * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusDisplayName(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCards(CardsProvider cardsProvider) {
    final mostReadCards = cardsProvider.getMostReadCards(limit: 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Read Cards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (mostReadCards.isEmpty)
              Center(
                child: Text(
                  'No cards available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ...mostReadCards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(card.name),
                  subtitle: Text('${card.readCount} reads'),
                  trailing: Chip(
                    label: Text(_getCardTypeDisplayName(card.type)),
                    backgroundColor: _getCardTypeColor(card.type).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _getCardTypeColor(card.type),
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(CardsProvider cardsProvider) {
    final recentCards = cardsProvider.getRecentCards(limit: 5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (recentCards.isEmpty)
              Center(
                child: Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ...recentCards.map((card) {
                return ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: _getCardTypeColor(card.type),
                  ),
                  title: Text(card.name),
                  subtitle: Text(
                    'Added ${_formatRelativeTime(card.createdAt)}',
                  ),
                  trailing: Text(
                    _formatDate(card.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingTrends(CardsProvider cardsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Center(
                child: Text(
                  'Reading trends chart would go here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats(CardsProvider cardsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildUsageStatRow('Average reads per card', '0.0'),
            _buildUsageStatRow('Most active day', 'Not available'),
            _buildUsageStatRow('Total reading time', '0 minutes'),
            _buildUsageStatRow('Success rate', '100%'),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CardStatus status) {
    switch (status) {
      case CardStatus.active:
        return AppColors.success;
      case CardStatus.favorite:
        return AppColors.error;
      case CardStatus.archived:
        return AppColors.textSecondary;
      case CardStatus.corrupted:
        return AppColors.warning;
    }
  }

  String _getStatusDisplayName(CardStatus status) {
    switch (status) {
      case CardStatus.active:
        return 'Active';
      case CardStatus.favorite:
        return 'Favorites';
      case CardStatus.archived:
        return 'Archived';
      case CardStatus.corrupted:
        return 'Corrupted';
    }
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
        return Colors.indigo;
      case CardType.iso14443B:
        return Colors.amber;
      case CardType.unknown:
        return Colors.grey;
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
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
}