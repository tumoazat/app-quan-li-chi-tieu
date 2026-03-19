import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../data/models/expense.dart';

/// File name: expense_summary_card.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Shared card displaying total and category breakdown.
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({
    super.key,
    required this.total,
    required this.totalsByCategory,
  });

  final double total;
  final Map<ExpenseCategory, double> totalsByCategory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng chi tiêu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(total),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...ExpenseCategory.values.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_categoryLabel(category)),
                    Text(
                      CurrencyFormatter.format(totalsByCategory[category] ?? 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.bills:
        return 'Hóa đơn';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }
}
