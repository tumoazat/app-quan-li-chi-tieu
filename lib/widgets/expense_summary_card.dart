import 'package:flutter/material.dart';

import '../models/expense.dart';

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
              '${total.toStringAsFixed(0)} đ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...ExpenseCategory.values.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_labelForCategory(category)),
                    Text(
                      '${(totalsByCategory[category] ?? 0).toStringAsFixed(0)} đ',
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

  String _labelForCategory(ExpenseCategory category) {
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
