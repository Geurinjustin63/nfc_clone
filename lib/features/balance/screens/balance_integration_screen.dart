import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../../nfc/providers/nfc_provider.dart';
import '../utils/demo_balance_generator.dart';
import '../../../core/models/nfc_card.dart';
import '../../../core/models/card_balance.dart';
import '../../../app/themes.dart';
import '../../../app/routes.dart';

class BalanceIntegrationScreen extends StatefulWidget {
  const BalanceIntegrationScreen({super.key});

  @override
  State<BalanceIntegrationScreen> createState() => _BalanceIntegrationScreenState();
}

class _BalanceIntegrationScreenState extends State<BalanceIntegrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingDemo = false;

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
        title: const Text('Balance Integration'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scanner', icon: Icon(Icons.nfc)),
            Tab(text: 'Demo', icon: Icon(Icons.play_circle)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
          ],
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppColors.secondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildDemoTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Consumer2<NFCProvider, BalanceProvider>(
      builder: (context, nfcProvider, balanceProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Balance Scanner',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan NFC cards to automatically detect and extract balance information.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: nfcProvider.isNFCAvailable 
                                  ? () => _scanForBalance(nfcProvider, balanceProvider)
                                  : null,
                              icon: const Icon(Icons.nfc),
                              label: const Text('Scan Card'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => AppRoutes.navigateToBalanceDashboard(context),
                              icon: const Icon(Icons.dashboard),
                              label: const Text('Dashboard'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSupportedCardsInfo(),
              const SizedBox(height: 24),
              _buildRecentBalances(balanceProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoTab() {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle,
                            color: AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Demo Balance Cards',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generate demo cards with realistic balance data for testing the balance features.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingDemo ? null : () => _generateDemoData(balanceProvider),
                          icon: _isGeneratingDemo 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isGeneratingDemo ? 'Generating...' : 'Generate Demo Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDemoCardTypes(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisTab() {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: AppColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Balance Analysis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (balanceProvider.isLoadingStatistics)
                        const Center(child: CircularProgressIndicator())
                      else if (balanceProvider.statistics.isNotEmpty)
                        _buildStatisticsView(balanceProvider.statistics)
                      else
                        Text(
                          'No balance data available for analysis. Scan some cards or generate demo data first.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportedCardsInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Card Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSupportedCardItem(
              'Transit Cards',
              'Metro, bus, subway cards with stored value',
              Icons.train,
              Colors.blue,
            ),
            _buildSupportedCardItem(
              'Gift Cards',
              'Store gift cards with remaining balance',
              Icons.card_giftcard,
              Colors.orange,
            ),
            _buildSupportedCardItem(
              'Campus Cards',
              'University ID cards with dining credits',
              Icons.school,
              Colors.teal,
            ),
            _buildSupportedCardItem(
              'Loyalty Cards',
              'Reward cards with points balance',
              Icons.stars,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedCardItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBalances(BalanceProvider balanceProvider) {
    final recentBalances = balanceProvider.balances.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Balances',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (recentBalances.isNotEmpty)
                  TextButton(
                    onPressed: () => AppRoutes.navigateToBalanceDashboard(context),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentBalances.isEmpty)
              Center(
                child: Text(
                  'No recent balance data',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ...recentBalances.map((balance) => _buildRecentBalanceItem(balance)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBalanceItem(CardBalance balance) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getBalanceTypeColor(balance.balanceType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getBalanceTypeIcon(balance.balanceType),
          color: _getBalanceTypeColor(balance.balanceType),
          size: 20,
        ),
      ),
      title: Text(balance.balanceTypeDisplayName),
      subtitle: Text('Updated ${_formatRelativeTime(balance.lastUpdated)}'),
      trailing: Text(
        balance.formattedBalance,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: balance.isLowBalance ? AppColors.error : AppColors.textPrimary,
            ),
      ),
    );
  }

  Widget _buildDemoCardTypes() {
    final demoTypes = [
      ('Transit Card', BalanceType.transit, Icons.train, Colors.blue),
      ('Gift Card', BalanceType.gift, Icons.card_giftcard, Colors.orange),
      ('Campus Card', BalanceType.campus, Icons.school, Colors.teal),
      ('Loyalty Card', BalanceType.loyalty, Icons.stars, Colors.purple),
      ('Parking Card', BalanceType.parking, Icons.local_parking, Colors.indigo),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demo Card Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...demoTypes.map((demo) => _buildDemoTypeItem(
              demo.$1, // title
              demo.$2, // balance type
              demo.$3, // icon
              demo.$4, // color
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoTypeItem(String title, BalanceType type, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            '${DemoBalanceGenerator.generateRealisticBalance(type).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView(Map<String, dynamic> statistics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Balance',
                '\$${(statistics['total_balance'] ?? 0.0).toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Cards',
                (statistics['total_cards_with_balance'] ?? 0).toString(),
                Icons.credit_card,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month Spent',
                '\$${(statistics['total_spent_this_month'] ?? 0.0).toStringAsFixed(2)}',
                Icons.trending_down,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'This Month Added',
                '\$${(statistics['total_added_this_month'] ?? 0.0).toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _scanForBalance(NFCProvider nfcProvider, BalanceProvider balanceProvider) async {
    try {
      final result = await nfcProvider.startReading();
      if (result?.success == true && result?.card != null) {
        final card = result!.card!;
        
        // Extract balance from the scanned card
        final balance = await balanceProvider.extractBalanceFromCard(card);
        
        if (balance != null) {
          _showBalanceDetectedDialog(balance);
        } else {
          _showNoBalanceDialog(card);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to scan for balance: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _generateDemoData(BalanceProvider balanceProvider) async {
    setState(() {
      _isGeneratingDemo = true;
    });

    try {
      // Generate demo cards with balance data
      final demoCards = DemoBalanceGenerator.createDemoBalanceCards();
      
      // Process each demo card to extract balance
      for (final card in demoCards) {
        await balanceProvider.extractBalanceFromCard(card);
        // Small delay for visual effect
        await Future.delayed(const Duration(milliseconds: 300));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated ${demoCards.length} demo cards with balance data'),
          backgroundColor: AppColors.success,
        ),
      );

      // Switch to balance dashboard
      _tabController.animateTo(0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate demo data: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingDemo = false;
      });
    }
  }

  void _showBalanceDetectedDialog(CardBalance balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            const Text('Balance Detected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Successfully extracted balance information:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Balance:'),
                      Text(
                        balance.formattedBalance,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Type:'),
                      Text(balance.balanceTypeDisplayName),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Confidence:'),
                      Text(balance.confidenceDescription),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRoutes.navigateToBalanceDashboard(context);
            },
            child: const Text('View Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showNoBalanceDialog(NFCCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info,
              color: AppColors.info,
            ),
            const SizedBox(width: 8),
            const Text('No Balance Found'),
          ],
        ),
        content: Text(
          'Could not detect balance information in "${card.name}". This card may not contain balance data or uses an unsupported format.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}