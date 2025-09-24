import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  
  // Dark Theme Colors
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1E1E1E);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // NFC Status Colors
  static const Color nfcActive = Color(0xFF00E676);
  static const Color nfcInactive = Color(0xFFFF5252);
  static const Color nfcReading = Color(0xFFFFB74D);
  static const Color nfcCloning = Color(0xFF9C27B0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextHint = Color(0xFF666666);
}

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: AppColors.textOnPrimary,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.roboto(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        headlineLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        headlineSmall: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleSmall: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        labelMedium: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        labelSmall: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.darkCard,
        elevation: 2,
        shadowColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkTextSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 6,
      ),
    );
  }
}