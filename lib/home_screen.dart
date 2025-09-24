import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/home/screens/main_screen.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/authentication/screens/auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
