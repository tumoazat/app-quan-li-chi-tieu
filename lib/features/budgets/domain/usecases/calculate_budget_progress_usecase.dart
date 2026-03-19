import 'package:flutter/material.dart';

/// Result of budget progress calculation.
class BudgetProgress {
  final String categoryId;
  final double limit;
  final double spent;
  final double percentage;
  final Color statusColor;

  const BudgetProgress({
    required this.categoryId,
    required this.limit,
    required this.spent,
    required this.percentage,
    required this.statusColor,
  });

  bool get isExceeded => percentage > 100;
}

/// Use case: calculate spending progress against a budget limit.
class CalculateBudgetProgressUseCase {
  const CalculateBudgetProgressUseCase();

  /// Returns a [BudgetProgress] for the given [limit] and [spent] values.
  /// Color thresholds:
  ///   - Green  : < 70 %
  ///   - Orange : 70 – 90 %
  ///   - Red    : > 90 %
  BudgetProgress call({
    required String categoryId,
    required double limit,
    required double spent,
  }) {
    final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;
    final Color color;
    if (percentage < 70) {
      color = const Color(0xFF4CAF50); // green
    } else if (percentage <= 90) {
      color = const Color(0xFFFF9800); // orange
    } else {
      color = const Color(0xFFF44336); // red
    }
    return BudgetProgress(
      categoryId: categoryId,
      limit: limit,
      spent: spent,
      percentage: percentage,
      statusColor: color,
    );
  }
}
