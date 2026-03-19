import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/expense.dart';

/// File name: expense_service.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Expense business logic and in-memory state.
class ExpenseService extends ChangeNotifier {
  final List<Expense> _expenses = [
    Expense(
      id: '1',
      title: 'Bữa trưa',
      amount: 50000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.food,
    ),
    Expense(
      id: '2',
      title: 'Gửi xe',
      amount: 10000,
      date: DateTime.now(),
      category: ExpenseCategory.transport,
    ),
    Expense(
      id: '3',
      title: 'Internet',
      amount: 250000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.bills,
    ),
  ];

  UnmodifiableListView<Expense> get expenses => UnmodifiableListView(_expenses);

  double get totalAmount {
    return _expenses.fold(0, (total, expense) => total + expense.amount);
  }

  Map<ExpenseCategory, double> get totalsByCategory {
    final totals = {
      for (final category in ExpenseCategory.values) category: 0.0,
    };

    for (final expense in _expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  /// Add new expense and notify listeners.
  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  /// Remove expense by id and notify listeners.
  void removeExpense(String id) {
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
  }
}
