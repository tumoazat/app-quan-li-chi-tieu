import 'package:flutter/material.dart';

class AppColors {
  // Primary color - Fintech green
  static const Color primary = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFF58D68D);

  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Transaction colors
  static const Color expenseLight = Color(0xFFE74C3C);
  static const Color expenseDark = Color(0xFFFF6B6B);
  
  static const Color incomeLight = Color(0xFF2ECC71);
  static const Color incomeDark = Color(0xFF4ADE80);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF3498DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF3498DB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Category colors
  static const Color categoryFood = Color(0xFFFF6B35);
  static const Color categoryTransport = Color(0xFF4A90D9);
  static const Color categoryShopping = Color(0xFFE91E63);
  static const Color categoryEntertainment = Color(0xFF9C27B0);
  static const Color categoryEducation = Color(0xFF3F51B5);
  static const Color categoryBills = Color(0xFFFF5722);
  static const Color categoryHealth = Color(0xFF00BCD4);
  static const Color categoryCoffee = Color(0xFF795548);
  static const Color categoryOthers = Color(0xFF607D8B);

  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);

  // Shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.3);
}
