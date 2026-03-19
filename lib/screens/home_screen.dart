import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/expense_item_tile.dart';
import '../widgets/expense_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                    onDelete: (id) => _expenseService.removeExpense(id),
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
        return AddExpenseSheet(
          onSave: (expense) => _expenseService.addExpense(expense),
        );
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
