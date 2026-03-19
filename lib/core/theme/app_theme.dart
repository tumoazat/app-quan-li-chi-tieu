import 'package:flutter/material.dart';

/// File name: app_theme.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Centralized theme configuration for brand consistency.
class AppTheme {
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color expenseRed = Color(0xFFE74C3C);
  static const Color incomeGreen = Color(0xFF2ECC71);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
    ),
  );
}
