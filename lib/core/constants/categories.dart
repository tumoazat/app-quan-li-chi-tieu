/// File name: categories.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Category definitions and utilities
///
/// Responsibilities:
/// - Define all expense/income categories
/// - Category icons and colors
/// - Category utilities

import 'package:flutter/material.dart';

/// Category Icon mapping
class CategoryIcon {
  static const Map<String, String> icons = {
    // Chi tiêu
    'Ăn uống': '🍔',
    'Giao thông': '🚗',
    'Nhà ở': '🏠',
    'Quần áo': '👕',
    'Giáo dục': '📚',
    'Y tế': '🏥',
    'Giải trí': '🎮',
    'Điện thoại': '📱',
    'Cơm hộp': '📦',
    'Khác': '❓',
    // Thu nhập
    'Lương': '💰',
    'Thưởng': '🎁',
    'Đầu tư': '📈',
  };

  static String getIcon(String category) {
    return icons[category] ?? '❓';
  }
}

/// Category Color mapping
class CategoryColor {
  static const Map<String, Color> colors = {
    // Chi tiêu
    'Ăn uống': Color(0xFFFF6B6B),
    'Giao thông': Color(0xFF4ECDC4),
    'Nhà ở': Color(0xFF95E1D3),
    'Quần áo': Color(0xFFFFA07A),
    'Giáo dục': Color(0xFF6C5CE7),
    'Y tế': Color(0xFFE17055),
    'Giải trí': Color(0xFFA29BFE),
    'Điện thoại': Color(0xFF00B894),
    'Cơm hộp': Color(0xFFFDCB6E),
    'Khác': Color(0xFFB2BEB5),
    // Thu nhập
    'Lương': Color(0xFF2ECC71),
    'Thưởng': Color(0xFF27AE60),
    'Đầu tư': Color(0xFF1E8449),
  };

  static Color getColor(String category) {
    return colors[category] ?? const Color(0xFFB2BEB5);
  }
}

/// ExpenseCategory - Danh sách hạng mục chi tiêu
class ExpenseCategory {
  static const List<String> categories = [
    'Ăn uống',
    'Giao thông',
    'Nhà ở',
    'Quần áo',
    'Giáo dục',
    'Y tế',
    'Giải trí',
    'Điện thoại',
    'Cơm hộp',
    'Khác',
  ];

  static const List<String> incomeCategories = [
    'Lương',
    'Thưởng',
    'Đầu tư',
  ];

  static List<String> getCategories({required bool isIncome}) {
    return isIncome ? incomeCategories : categories;
  }
}

/// Transaction Filters
class TransactionFilters {
  /// Bộ lọc theo tháng
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Bộ lọc theo quý
  static (DateTime, DateTime) getQuarterRange(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;
    final startMonth = (quarter - 1) * 3 + 1;
    final start = DateTime(date.year, startMonth, 1);
    final end = DateTime(date.year, startMonth + 3, 0, 23, 59, 59);
    return (start, end);
  }

  /// Bộ lọc theo năm
  static (DateTime, DateTime) getYearRange(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final end = DateTime(date.year, 12, 31, 23, 59, 59);
    return (start, end);
  }
}
