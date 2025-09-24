import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/secure_storage_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  await _initializeServices();
  
  runApp(const NFCCloneApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Initialize secure storage
    final secureStorage = SecureStorageService();
    await secureStorage.initialize();
    
  } catch (e) {
    debugPrint('Failed to initialize services: $e');
    // Continue with limited functionality
  }
}
