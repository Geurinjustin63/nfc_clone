import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/authentication/providers/auth_provider.dart';
import '../features/nfc/providers/nfc_provider.dart';
import '../features/cards/providers/cards_provider.dart';
import '../features/settings/providers/settings_provider.dart';
import 'routes.dart';
import 'themes.dart';

class NFCCloneApp extends StatelessWidget {
  const NFCCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NFCProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'NFC Card Clone Pro',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: settingsProvider.themeMode,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    settingsProvider.textScaleFactor,
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}