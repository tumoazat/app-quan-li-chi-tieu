import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  // Format VND currency with Vietnamese style (dot separator for thousands)
  static String formatVND(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    final formatted = formatter.format(amount.abs());
    
    if (showSymbol) {
      return '${AppConstants.currencySymbol}$formatted';
    }
    return formatted;
  }

  // Format with +/- prefix for income/expense
  static String formatWithSign(double amount, {bool isIncome = false}) {
    final prefix = isIncome ? '+' : '-';
    final formatted = formatVND(amount.abs());
    return '$prefix$formatted';
  }

  // Format for expense (negative, red)
  static String formatExpense(double amount) {
    return formatWithSign(amount, isIncome: false);
  }

  // Format for income (positive, green)
  static String formatIncome(double amount) {
    return formatWithSign(amount, isIncome: true);
  }

  // Compact format for large numbers
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      // Billions
      return '${AppConstants.currencySymbol}${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      // Millions
      return '${AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      // Thousands
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatVND(amount);
  }

  // Parse currency string to double
  static double parse(String value) {
    // Remove currency symbol and spaces
    String cleaned = value.replaceAll(AppConstants.currencySymbol, '');
    cleaned = cleaned.replaceAll(' ', '');
    // Replace dots with empty string (thousand separators in Vietnamese)
    cleaned = cleaned.replaceAll('.', '');
    // Replace comma with dot (decimal separator)
    cleaned = cleaned.replaceAll(',', '.');
    
    try {
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  // Format input for display (while user is typing)
  static String formatInput(String value) {
    if (value.isEmpty) return '0';
    
    // Remove non-digit characters except dot
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.isEmpty) return '0';
    
    // Parse to double and format
    final amount = double.tryParse(cleaned) ?? 0;
    return formatVND(amount);
  }
}
