import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../app/themes.dart';
import '../models/card_balance.dart';

class BalanceSettingsScreen extends StatefulWidget {
  const BalanceSettingsScreen({super.key});

  @override
  State<BalanceSettingsScreen> createState() => _BalanceSettingsScreenState();
}

class _BalanceSettingsScreenState extends State<BalanceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Balance Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Consumer2<BalanceProvider, SettingsProvider>(
        builder: (context, balanceProvider, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrencySection(balanceProvider),
              const SizedBox(height: 24),
              _buildRefreshSection(settingsProvider),
              const SizedBox(height: 24),
              _buildNotificationSection(settingsProvider),
              const SizedBox(height: 24),
              _buildDisplaySection(settingsProvider),
              const SizedBox(height: 24),
              _buildPrivacySection(settingsProvider),
              const SizedBox(height: 24),
              _buildDataManagementSection(balanceProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrencySection(BalanceProvider balanceProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.currency_exchange,
                  color: AppColors.primary,
                ),
              ),
              title: const Text('Primary Currency'),
              subtitle: Text(CardBalance.getCurrencyName(balanceProvider.primaryCurrency)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CardBalance.getCurrencySymbol(balanceProvider.primaryCurrency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _showCurrencySelector(balanceProvider),
            ),
            const Divider(),
            SwitchListTile(
              secondary: Icon(
                Icons.autorenew,
                color: AppColors.primary,
              ),
              title: const Text('Auto Currency Conversion'),
              subtitle: const Text('Automatically convert to primary currency'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement auto conversion toggle
              },
            ),
            ListTile(
              leading: Icon(
                Icons.update,
                color: AppColors.primary,
              ),
              title: const Text('Exchange Rate Updates'),
              subtitle: Text(
                balanceProvider.isOnline 
                    ? 'Last updated: ${_formatDateTime(balanceProvider.lastUpdateTime)}'
                    : 'Offline - using cached rates',
              ),
              trailing: TextButton(
                onPressed: _updateExchangeRates,
                child: const Text('Update Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshSection(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refresh Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: Icon(
                Icons.autorenew,
                color: AppColors.primary,
              ),
              title: const Text('Auto Refresh'),
              subtitle: const Text('Automatically refresh balances when opening app'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement auto refresh toggle
              },
            ),
            ListTile(
              leading: Icon(
                Icons.schedule,
                color: AppColors.primary,
              ),
              title: const Text('Refresh Interval'),
              subtitle: const Text('How often to refresh stale balances'),
              trailing: DropdownButton<int>(
                value: 60, // This would come from settings
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 180, child: Text('3 hours')),
                  DropdownMenuItem(value: 360, child: Text('6 hours')),
                  DropdownMenuItem(value: 1440, child: Text('24 hours')),
                ],
                onChanged: (value) {
                  // Implement refresh interval setting
                },
              ),
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.vibration,
                color: AppColors.primary,
              ),
              title: const Text('Vibrate on Balance Update'),
              subtitle: const Text('Haptic feedback when balance changes'),
              value: settingsProvider.hapticFeedback,
              onChanged: settingsProvider.setHapticFeedback,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: Icon(
                Icons.notifications_active,
                color: AppColors.primary,
              ),
              title: const Text('Low Balance Alerts'),
              subtitle: const Text('Notify when card balance is low'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement low balance alerts toggle
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.schedule,
                color: AppColors.primary,
              ),
              title: const Text('Expiry Notifications'),
              subtitle: const Text('Notify when cards are about to expire'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement expiry notifications toggle
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.trending_up,
                color: AppColors.primary,
              ),
              title: const Text('Large Transaction Alerts'),
              subtitle: const Text('Notify for transactions over \$100'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement large transaction alerts toggle
              },
            ),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: AppColors.primary,
              ),
              title: const Text('Daily Summary'),
              subtitle: const Text('Time for daily spending summary'),
              trailing: const Text('8:00 PM'),
              onTap: _selectDailySummaryTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySection(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: Icon(
                Icons.visibility,
                color: AppColors.primary,
              ),
              title: const Text('Show Balance on Cards'),
              subtitle: const Text('Display balance on card list items'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement balance display toggle
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.trending_up,
                color: AppColors.primary,
              ),
              title: const Text('Show Balance Trends'),
              subtitle: const Text('Display balance change indicators'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement trend display toggle
              },
            ),
            ListTile(
              leading: Icon(
                Icons.decimal_decrease,
                color: AppColors.primary,
              ),
              title: const Text('Decimal Places'),
              subtitle: const Text('Number of decimal places to show'),
              trailing: DropdownButton<int>(
                value: 2, // This would come from settings
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0')),
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                ],
                onChanged: (value) {
                  // Implement decimal places setting
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(SettingsProvider settingsProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              secondary: Icon(
                Icons.security,
                color: AppColors.primary,
              ),
              title: const Text('Require Authentication'),
              subtitle: const Text('Require biometric auth to view balances'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement auth requirement toggle
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.visibility_off,
                color: AppColors.primary,
              ),
              title: const Text('Hide Balances in App Switcher'),
              subtitle: const Text('Blur balances when app is backgrounded'),
              value: true, // This would come from settings
              onChanged: (value) {
                // Implement privacy mode toggle
              },
            ),
            SwitchListTile(
              secondary: Icon(
                Icons.analytics,
                color: AppColors.primary,
              ),
              title: const Text('Financial Analytics'),
              subtitle: const Text('Allow spending pattern analysis'),
              value: settingsProvider.analyticsEnabled,
              onChanged: settingsProvider.setAnalyticsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection(BalanceProvider balanceProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.download,
                color: AppColors.primary,
              ),
              title: const Text('Export Financial Data'),
              subtitle: const Text('Download all balance and transaction data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportFinancialData,
            ),
            ListTile(
              leading: Icon(
                Icons.upload,
                color: AppColors.primary,
              ),
              title: const Text('Import Financial Data'),
              subtitle: const Text('Restore from backup file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _importFinancialData,
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: AppColors.error,
              ),
              title: Text(
                'Clear All Financial Data',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text('Permanently delete all balance and transaction data'),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.error,
              ),
              onTap: _clearAllFinancialData,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelector(BalanceProvider balanceProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Primary Currency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All balances will be converted to this currency',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: Currency.values.length,
                itemBuilder: (context, index) {
                  final currency = Currency.values[index];
                  final isSelected = balanceProvider.primaryCurrency == currency;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withOpacity(0.1)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? AppColors.primary 
                            : AppColors.textSecondary.withOpacity(0.1),
                        child: Text(
                          CardBalance.getCurrencySymbol(currency),
                          style: TextStyle(
                            color: isSelected 
                                ? AppColors.textOnPrimary 
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        CardBalance.getCurrencyName(currency),
                        style: TextStyle(
                          fontWeight: isSelected 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(_getCurrencyCode(currency)),
                      trailing: isSelected 
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        balanceProvider.setPrimaryCurrency(currency);
                        _showCurrencyChangeConfirmation(currency);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyChangeConfirmation(Currency newCurrency) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Primary currency changed to ${CardBalance.getCurrencyName(newCurrency)}'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }

  void _selectDailySummaryTime() {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    ).then((time) {
      if (time != null) {
        // Save the selected time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily summary time set to ${time.format(context)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  void _updateExchangeRates() {
    // Implement exchange rate update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updating exchange rates...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportFinancialData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Export Financial Data'),
        content: const Text(
          'This will create a backup file containing all your balance and transaction data. The file will be encrypted for security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performExport();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _importFinancialData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Import Financial Data'),
        content: const Text(
          'This will restore balance and transaction data from a backup file. Existing data will be merged with imported data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performImport();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _clearAllFinancialData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            const Text('Clear All Financial Data'),
          ],
        ),
        content: const Text(
          'This will permanently delete all balance information, transaction history, and financial settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearData();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  void _performExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial data export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _performImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Financial data import functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _performClearData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All financial data cleared'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }

  String _getCurrencyCode(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.gbp:
        return 'GBP';
      case Currency.jpy:
        return 'JPY';
      case Currency.cad:
        return 'CAD';
      case Currency.aud:
        return 'AUD';
      case Currency.chf:
        return 'CHF';
      case Currency.cny:
        return 'CNY';
      case Currency.hkd:
        return 'HKD';
      case Currency.sgd:
        return 'SGD';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}