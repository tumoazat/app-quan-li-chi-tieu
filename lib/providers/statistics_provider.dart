import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_provider.dart';

// Simple stats model - income, expense, balance, and category breakdown
class SimpleStats {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryExpense; // categoryId -> amount

  SimpleStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryExpense,
  });
}

// Simple stats provider - calculate totals and category breakdown
// Key format: "year-month" e.g. "2026-2"
final simpleStatsProvider = StreamProvider.autoDispose
    .family<SimpleStats, String>((ref, monthKey) async* {
  final transactionsStream = ref.watch(transactionsStreamProvider(monthKey));
  
  await for (final transactions in transactionsStream.when(
    data: (t) async* { yield t; },
    loading: () async* { yield []; },
    error: (_, __) async* { yield []; },
  )) {
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryExpense = {};

    for (var transaction in transactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
        // Add to category breakdown for expenses only
        categoryExpense[transaction.categoryId] = 
            (categoryExpense[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }

    yield SimpleStats(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      categoryExpense: categoryExpense,
    );
  }
});
