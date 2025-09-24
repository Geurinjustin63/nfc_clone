import 'package:flutter/material.dart';
import '../features/authentication/screens/splash_screen.dart';
import '../features/authentication/screens/auth_screen.dart';
import '../features/authentication/screens/biometric_setup_screen.dart';
import '../features/home/screens/main_screen.dart';
import '../features/nfc/screens/nfc_scanner_screen.dart';
import '../features/nfc/screens/card_details_screen.dart';
import '../features/cards/screens/cards_list_screen.dart';
import '../features/cards/screens/card_editor_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/security_settings_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/balance/screens/balance_dashboard_screen.dart';
import '../features/balance/screens/transaction_history_screen.dart';
import '../features/balance/screens/balance_settings_screen.dart';
import '../features/balance/screens/balance_dashboard_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String auth = '/auth';
  static const String biometricSetup = '/biometric-setup';
  static const String main = '/main';
  static const String nfcScanner = '/nfc-scanner';
  static const String cardDetails = '/card-details';
  static const String cardsList = '/cards-list';
  static const String cardEditor = '/card-editor';
  static const String settings = '/settings';
  static const String securitySettings = '/security-settings';
  static const String analytics = '/analytics';
  static const String balanceDashboard = '/balance-dashboard';
  static const String transactionHistory = '/transaction-history';
  static const String balanceSettings = '/balance-settings';
  static const String balanceDashboard = '/balance-dashboard';

  // Routes map
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      auth: (context) => const AuthScreen(),
      biometricSetup: (context) => const BiometricSetupScreen(),
      main: (context) => const MainScreen(),
      nfcScanner: (context) => const NFCScannerScreen(),
      cardDetails: (context) => const CardDetailsScreen(),
      cardsList: (context) => const CardsListScreen(),
      cardEditor: (context) => const CardEditorScreen(),
      settings: (context) => const SettingsScreen(),
      securitySettings: (context) => const SecuritySettingsScreen(),
      analytics: (context) => const AnalyticsScreen(),
      balanceDashboard: (context) => const BalanceDashboardScreen(),
      transactionHistory: (context) => const TransactionHistoryScreen(),
      balanceSettings: (context) => const BalanceSettingsScreen(),
      balanceDashboard: (context) => const BalanceDashboardScreen(),
    };
  }

  // Navigation helpers
  static void navigateToAuth(BuildContext context) {
    Navigator.pushReplacementNamed(context, auth);
  }

  static void navigateToMain(BuildContext context) {
    Navigator.pushReplacementNamed(context, main);
  }

  static void navigateToNFCScanner(BuildContext context) {
    Navigator.pushNamed(context, nfcScanner);
  }

  static void navigateToCardDetails(BuildContext context, {Object? arguments}) {
    Navigator.pushNamed(context, cardDetails, arguments: arguments);
  }

  static void navigateToCardsList(BuildContext context) {
    Navigator.pushNamed(context, cardsList);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settings);
  }

  static void navigateToAnalytics(BuildContext context) {
    Navigator.pushNamed(context, analytics);
  }

  static void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  static void navigateBackToMain(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      main,
      (route) => false,
    );
  }
}