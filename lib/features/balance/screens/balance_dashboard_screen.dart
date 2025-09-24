import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../../cards/providers/cards_provider.dart';
import '../../../app/themes.dart';
import '../../../app/routes.dart';
import '../widgets/total_balance_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/balance_card_tile.dart';
import '../widgets/recent_transactions_section.dart';
import '../widgets/balance_charts_section.dart';

class BalanceDashboardScreen extends StatefulWidget {
  const BalanceDashboardScreen({super.key});

  @override
  State<BalanceDashboardScreen> createState() => _BalanceDashboardScreenState();
}

class _BalanceDashboardScreenState extends State<BalanceDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final cardsProvider = Provider.of<CardsProvider>(context, listen: false);
    
    // Initialize if not already done
    if (balanceProvider.cardBalances.isEmpty) {
      await balanceProvider.initialize();
    }
    
    // Load cards if not already loaded
    if (cardsProvider.cards.isEmpty) {
      await cardsProvider.loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<BalanceProvider, CardsProvider>(
        builder: (context, balanceProvider, cardsProvider, child) {
          if (balanceProvider.isLoadingBalances && balanceProvider.cardBalances.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading balances...'),
                ],
              ),
            );
          }

          if (balanceProvider.error != null) {
            return _buildErrorView(balanceProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: () => _refreshAllBalances(balanceProvider, cardsProvider),
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Financial Overview',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryVariant,
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _refreshAllBalances(balanceProvider, cardsProvider),
                      icon: balanceProvider.isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      tooltip: 'Refresh all balances',
                    ),
                    IconButton(
                      onPressed: _showBalanceSettings,
                      icon: const Icon(Icons.settings),
                      tooltip: 'Balance settings',
                    ),
                  ],
                ),

                // Total Balance Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TotalBalanceCard(
                      totalBalance: balanceProvider.totalBalance,
                      currency: balanceProvider.primaryCurrency,
                      lastUpdated: balanceProvider.lastUpdateTime,
                      isLoading: balanceProvider.isRefreshing,
                    ),
                  ),
                ),

                // Quick Stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuickStatsRow(
                      todaySpending: balanceProvider.todaySpending,
                      weekSpending: balanceProvider.weekSpending,
                      monthSpending: balanceProvider.monthSpending,
                      currency: balanceProvider.primaryCurrency,
                    ),
                  ),
                ),

                // Balance Charts Section
                if (balanceProvider.cardBalances.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BalanceChartsSection(
                        balanceProvider: balanceProvider,
                      ),
                    ),
                  ),

                // Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Card Balances',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _viewAllCards,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Card Balances List
                if (cardsProvider.cards.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildNoCardsView(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = cardsProvider.cards[index];
                        final balance = balanceProvider.getCardBalance(card.id);
                        final isRefreshing = balanceProvider.isCardRefreshing(card.id);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: BalanceCardTile(
                            card: card,
                            balance: balance,
                            isRefreshing: isRefreshing,
                            onTap: () => _openCardDetails(card),
                            onRefresh: () => _refreshCardBalance(balanceProvider, card),
                          ),
                        );
                      },
                      childCount: cardsProvider.cards.length,
                    ),
                  ),

                // Recent Transactions Section
                if (balanceProvider.recentTransactions.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: RecentTransactionsSection(
                        transactions: balanceProvider.recentTransactions.take(5).toList(),
                        onViewAll: _viewAllTransactions,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNewCard,
        icon: const Icon(Icons.nfc),
        label: const Text('Scan Card'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Balances',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
                final cardsProvider = Provider.of<CardsProvider>(context, listen: false);
                _refreshAllBalances(balanceProvider, cardsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'No Cards Added',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start by scanning your first NFC card to view its balance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _scanNewCard,
            icon: const Icon(Icons.nfc),
            label: const Text('Scan First Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllBalances(BalanceProvider balanceProvider, CardsProvider cardsProvider) async {
    await balanceProvider.refreshAllBalances(cardsProvider.cards);
  }

  Future<void> _refreshCardBalance(BalanceProvider balanceProvider, card) async {
    await balanceProvider.refreshCardBalance(card.id, card);
  }

  void _openCardDetails(card) {
    AppRoutes.navigateToCardDetails(context, arguments: {'card': card});
  }

  void _viewAllCards() {
    AppRoutes.navigateToCardsList(context);
  }

  void _viewAllTransactions() {
    Navigator.pushNamed(context, '/transaction-history');
  }

  void _scanNewCard() {
    AppRoutes.navigateToNFCScanner(context);
  }

  void _showBalanceSettings() {
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
        expand: false,
        builder: (context, scrollController) {
          return _buildBalanceSettingsSheet(scrollController);
        },
      ),
    );
  }

  Widget _buildBalanceSettingsSheet(ScrollController scrollController) {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Balance Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Primary Currency Setting
                    _buildSettingTile(
                      'Primary Currency',
                      CardBalance.getCurrencyName(balanceProvider.primaryCurrency),
                      Icons.attach_money,
                      () => _showCurrencySelector(balanceProvider),
                    ),
                    
                    // Auto Refresh Setting
                    SwitchListTile(
                      title: const Text('Auto Refresh'),
                      subtitle: const Text('Automatically refresh balances'),
                      value: balanceProvider.autoRefreshEnabled,
                      onChanged: (value) => balanceProvider.setAutoRefreshEnabled(value),
                      secondary: const Icon(Icons.auto_mode),
                    ),
                    
                    // Low Balance Notifications
                    SwitchListTile(
                      title: const Text('Low Balance Alerts'),
                      subtitle: const Text('Get notified when balances are low'),
                      value: balanceProvider.lowBalanceNotificationsEnabled,
                      onChanged: (value) => balanceProvider.setLowBalanceNotificationsEnabled(value),
                      secondary: const Icon(Icons.notifications),
                    ),
                    
                    const Divider(),
                    
                    // Statistics
                    _buildStatisticsTile(
                      'Success Rate',
                      '${(balanceProvider.readSuccessRate * 100).toStringAsFixed(1)}%',
                      Icons.analytics,
                    ),
                    
                    _buildStatisticsTile(
                      'Total Reads',
                      '${balanceProvider.successfulReads + balanceProvider.failedReads}',
                      Icons.nfc,
                    ),
                    
                    _buildStatisticsTile(
                      'Last Update',
                      balanceProvider.lastUpdateTime != null
                          ? _formatLastUpdate(balanceProvider.lastUpdateTime!)
                          : 'Never',
                      Icons.update,
                    ),
                    
                    const Divider(),
                    
                    // Actions
                    ListTile(
                      leading: const Icon(Icons.download, color: AppColors.primary),
                      title: const Text('Export Balance Data'),
                      subtitle: const Text('Export all balances and transactions'),
                      onTap: _exportBalanceData,
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.refresh, color: AppColors.success),
                      title: const Text('Reset Statistics'),
                      subtitle: const Text('Clear success rate and read counts'),
                      onTap: () {
                        balanceProvider.resetStatistics();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildStatisticsTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Future<void> _refreshAllBalances(BalanceProvider balanceProvider, CardsProvider cardsProvider) async {
    await balanceProvider.refreshAllBalances(cardsProvider.cards);
  }

  void _showCurrencySelector(BalanceProvider balanceProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Primary Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: Currency.values.map((currency) {
              return RadioListTile<Currency>(
                title: Text(CardBalance.getCurrencyName(currency)),
                subtitle: Text(CardBalance.getCurrencySymbol(currency)),
                value: currency,
                groupValue: balanceProvider.primaryCurrency,
                onChanged: (value) {
                  if (value != null) {
                    balanceProvider.setPrimaryCurrency(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBalanceSettings() {
    Navigator.pushNamed(context, '/balance-settings');
  }

  void _exportBalanceData() {
    Navigator.of(context).pop();
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}