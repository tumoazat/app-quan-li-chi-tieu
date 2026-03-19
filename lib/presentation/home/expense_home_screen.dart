import 'package:flutter/material.dart';

import '../../data/models/expense.dart';
import '../../data/services/expense_service.dart';
import '../shared/add_expense_sheet.dart';
import '../shared/expense_item_tile.dart';
import '../shared/expense_summary_card.dart';

/// File name: expense_home_screen.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Expense overview screen.
class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  final ExpenseService _expenseService = ExpenseService();

  @override
  void dispose() {
    _expenseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expenseService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Quản lý chi tiêu')),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddExpenseSheet,
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ExpenseSummaryCard(
                  total: _expenseService.totalAmount,
                  totalsByCategory: _expenseService.totalsByCategory,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ExpenseList(
                    expenses: _expenseService.expenses,
                    onDelete: _expenseService.removeExpense,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddExpenseSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddExpenseSheet(onSave: _expenseService.addExpense);
      },
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses, required this.onDelete});

  final List<Expense> expenses;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('Chưa có khoản chi nào. Nhấn + để thêm mới.'),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseItemTile(
          expense: expense,
          onDelete: () => onDelete(expense.id),
        );
      },
    );
  }
}
