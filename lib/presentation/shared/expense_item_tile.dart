import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../core/theme/app_theme.dart';

/// File name: expense_item_tile.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Shared expense list tile.
class ExpenseItemTile extends StatelessWidget {
  const ExpenseItemTile({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(expense.title),
        subtitle: Text(
          '${DateFormatter.toDisplay(expense.date)} • '
          '${_categoryLabel(expense.category)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(expense.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.expenseRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
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
