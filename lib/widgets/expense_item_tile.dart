import 'package:flutter/material.dart';

import '../models/expense.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: ListTile(
        title: Text(expense.title),
        subtitle: Text(
          '${_formatDate(expense.date)} • ${_labelForCategory(expense.category)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatCurrency(expense.amount), style: textTheme.titleMedium),
            TextButton(onPressed: onDelete, child: const Text('Xóa')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
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

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} đ';
  }
}
