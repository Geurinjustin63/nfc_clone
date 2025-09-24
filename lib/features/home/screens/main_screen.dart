import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../nfc/providers/nfc_provider.dart';
import '../../cards/providers/cards_provider.dart';
import '../widgets/dashboard_overview.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_cards.dart';
import '../widgets/nfc_status_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = const [
    _DashboardTab(),
    _CardsTab(),
    _NFCTab(),
    _AnalyticsTab(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.credit_card),
      label: 'Cards',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.nfc),
      label: 'NFC',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final nfcProvider = context.read<NFCProvider>();
    final cardsProvider = context.read<CardsProvider>();
    
    await Future.wait([
      nfcProvider.initialize(),
      cardsProvider.loadCards(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Card Clone Pro'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'security',
                    child: ListTile(
                      leading: Icon(Icons.security),
                      title: Text('Security'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (authProvider.currentSession != null) ...[
                    PopupMenuItem(
                      value: 'session_info',
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Session Info'),
                        subtitle: Text(
                          'Expires in ${authProvider.currentSession!.remainingTime.inMinutes}m',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: AppConstants.shortAnimation,
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    switch (_currentIndex) {
      case 0: // Dashboard
      case 2: // NFC
        return Consumer<NFCProvider>(
          builder: (context, nfcProvider, _) {
            if (nfcProvider.isReading || nfcProvider.isWriting) {
              return FloatingActionButton(
                onPressed: () => nfcProvider.stopCurrentOperation(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop),
              );
            }
            
            return FloatingActionButton(
              onPressed: () => AppRoutes.navigateToNFCScanner(context),
              child: const Icon(Icons.nfc),
            );
          },
        );
      case 1: // Cards
        return FloatingActionButton(
          onPressed: () => AppRoutes.navigateToCardEditor(context),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        AppRoutes.navigateToSettings(context);
        break;
      case 'security':
        Navigator.pushNamed(context, AppRoutes.securitySettings);
        break;
      case 'session_info':
        _showSessionInfo();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showSessionInfo() {
    final authProvider = context.read<AuthProvider>();
    final session = authProvider.currentSession;
    
    if (session == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Session Type', session.type.name),
            _buildInfoRow('Created', _formatDateTime(session.createdAt)),
            _buildInfoRow('Last Access', _formatDateTime(session.lastAccessAt)),
            _buildInfoRow('Expires', _formatDateTime(session.expiresAt)),
            _buildInfoRow('Device', session.deviceInfo),
            _buildInfoRow('Status', session.status.name),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (mounted) {
                AppRoutes.navigateToAuth(context);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NFCStatusCard(),
          SizedBox(height: AppConstants.defaultPadding),
          DashboardOverview(),
          SizedBox(height: AppConstants.defaultPadding),
          QuickActions(),
          SizedBox(height: AppConstants.defaultPadding),
          RecentCards(),
        ],
      ),
    );
  }
}

// Cards Tab
class _CardsTab extends StatelessWidget {
  const _CardsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CardsProvider>(
      builder: (context, cardsProvider, _) {
        if (cardsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cardsProvider.cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.credit_card_off,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No cards found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan your first NFC card to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => AppRoutes.navigateToNFCScanner(context),
                  icon: const Icon(Icons.nfc),
                  label: const Text('Scan Card'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: cardsProvider.cards.length,
          itemBuilder: (context, index) {
            final card = cardsProvider.cards[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.nfc, color: Colors.white),
                ),
                title: Text(card.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.standard),
                    Text(
                      'UID: ${card.formattedUID}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleCardAction(context, card, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Details'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clone',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Clone Card'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'favorite',
                      child: ListTile(
                        leading: Icon(Icons.favorite),
                        title: Text('Add to Favorites'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                onTap: () => AppRoutes.navigateToCardDetails(
                  context,
                  arguments: card,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleCardAction(BuildContext context, card, String action) {
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
      case 'delete':
        _showDeleteDialog(context, card, cardsProvider);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, card, CardsProvider cardsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete "${card.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await cardsProvider.deleteCard(card.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// NFC Tab
class _NFCTab extends StatelessWidget {
  const _NFCTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<NFCProvider>(
      builder: (context, nfcProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NFCStatusCard(),
              const SizedBox(height: AppConstants.largePadding),
              
              // NFC Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: nfcProvider.isAvailable && !nfcProvider.isReading && !nfcProvider.isWriting
                          ? () => _readCard(context, nfcProvider)
                          : null,
                      icon: nfcProvider.isReading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(nfcProvider.isReading ? 'Reading...' : 'Read Card'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: !nfcProvider.isAvailable
                          ? () => _loadDemoCard(context, nfcProvider)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Demo Mode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              if (nfcProvider.isReading || nfcProvider.isWriting) ...[
                LinearProgressIndicator(
                  value: nfcProvider.isReading 
                      ? nfcProvider.readProgress 
                      : nfcProvider.writeProgress,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  nfcProvider.statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: () => nfcProvider.stopCurrentOperation(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cancel Operation'),
                ),
              ],
              
              const SizedBox(height: AppConstants.largePadding),
              
              // Last Read Card
              if (nfcProvider.lastReadCard != null) ...[
                Text(
                  'Last Read Card',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nfcProvider.lastReadCard!.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(nfcProvider.lastReadCard!.standard),
                        Text(
                          'UID: ${nfcProvider.lastReadCard!.formattedUID}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => AppRoutes.navigateToCardDetails(
                                  context,
                                  arguments: nfcProvider.lastReadCard!,
                                ),
                                child: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: AppConstants.smallPadding),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: nfcProvider.isAvailable && !nfcProvider.isWriting
                                    ? () => _cloneCard(context, nfcProvider)
                                    : () => _cloneDemoCard(context, nfcProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Clone Card'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFC Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            'Reads',
                            '${nfcProvider.successfulReads}',
                            Colors.blue,
                          ),
                          _buildStatItem(
                            context,
                            'Writes',
                            '${nfcProvider.successfulWrites}',
                            Colors.green,
                          ),
                          _buildStatItem(
                            context,
                            'Success Rate',
                            '${(nfcProvider.readSuccessRate * 100).toInt()}%',
                            Colors.orange,
                          ),
                        ],
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

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _readCard(BuildContext context, NFCProvider nfcProvider) async {
    final result = await nfcProvider.readCard();
    
    if (!result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to read card'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDemoCard(BuildContext context, NFCProvider nfcProvider) async {
    final result = await nfcProvider.readDemoCard();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Demo card loaded' : 'Failed to load demo card'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _cloneCard(BuildContext context, NFCProvider nfcProvider) async {
    if (nfcProvider.lastReadCard == null) return;
    
    final result = await nfcProvider.writeCard(
      sourceCard: nfcProvider.lastReadCard!,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Card cloned successfully' : result.error ?? 'Failed to clone card'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _cloneDemoCard(BuildContext context, NFCProvider nfcProvider) async {
    if (nfcProvider.lastReadCard == null) return;
    
    final result = await nfcProvider.cloneDemoCard(nfcProvider.lastReadCard!);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Demo card cloned' : 'Failed to clone demo card'),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

// Analytics Tab
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Detailed analytics and statistics\nwill be available here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}