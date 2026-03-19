/// File name: expense.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Expense entity model.
enum ExpenseCategory { food, transport, shopping, bills, entertainment, other }

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
}
