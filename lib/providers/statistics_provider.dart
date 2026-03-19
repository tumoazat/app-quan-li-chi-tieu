/// File name: statistics_provider.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Riverpod providers for statistics calculations
///
/// Responsibilities:
/// - Calculate statistics and trends
/// - Monthly/yearly aggregations
/// - Category breakdowns

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';

part 'statistics_provider.g.dart';

// ============ STATISTICS STATE ============

/// StatisticsData - Lưu dữ liệu thống kê
class StatisticsData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryExpenses;
  final Map<String, double> monthlyExpense; // {month -> expense}
  final double averageDailyExpense;
  final double averageMonthlyExpense;
  final List<String> topCategories; // Top 5 categories by expense

  StatisticsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryExpenses,
    required this.monthlyExpense,
    required this.averageDailyExpense,
    required this.averageMonthlyExpense,
    required this.topCategories,
  });

  /// Copy with
  StatisticsData copyWith({
    double? totalIncome,
    double? totalExpense,
    double? balance,
    Map<String, double>? categoryExpenses,
    Map<String, double>? monthlyExpense,
    double? averageDailyExpense,
    double? averageMonthlyExpense,
    List<String>? topCategories,
  }) {
    return StatisticsData(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      averageDailyExpense: averageDailyExpense ?? this.averageDailyExpense,
      averageMonthlyExpense:
          averageMonthlyExpense ?? this.averageMonthlyExpense,
      topCategories: topCategories ?? this.topCategories,
    );
  }
}

// ============ HELPER FUNCTIONS ============

/// Tính tổng category expenses từ transactions
Map<String, double> _calculateCategoryExpenses(List<Transaction> transactions) {
  final expenses = <String, double>{};

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      expenses[tx.category] =
          (expenses[tx.category] ?? 0) + tx.amount.abs();
    }
  }

  return expenses;
}

/// Tính monthly expenses
Map<String, double> _calculateMonthlyExpense(List<Transaction> transactions) {
  final monthly = <String, double>{};

  for (final tx in transactions) {
    if (tx.type == TransactionType.expense) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + tx.amount.abs();
    }
  }

  return monthly;
}

/// Tính average daily expense
double _calculateAverageDailyExpense(List<Transaction> transactions) {
  if (transactions.isEmpty) return 0;

  final expenses =
      transactions.where((tx) => tx.type == TransactionType.expense).toList();

  if (expenses.isEmpty) return 0;

  // Tính số ngày từ transaction cũ nhất đến hôm nay
  final oldestDate = expenses.map((tx) => tx.date).reduce((a, b) {
    return a.isBefore(b) ? a : b;
  });

  final daysDifference = DateTime.now().difference(oldestDate).inDays + 1;
  final totalExpense = expenses.fold(0.0, (sum, tx) => sum + tx.amount.abs());

  return totalExpense / daysDifference;
}

/// Tính top categories
List<String> _calculateTopCategories(Map<String, double> categoryExpenses) {
  final sorted = categoryExpenses.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(5).map((e) => e.key).toList();
}

// ============ PROVIDERS ============

/// Overall statistics provider
@riverpod
Future<StatisticsData> statisticsProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) {
      final totalIncome = txs
          .where((tx) => tx.type == TransactionType.income)
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final totalExpense = txs
          .where((tx) => tx.type == TransactionType.expense)
          .fold(0.0, (sum, tx) => sum + tx.amount.abs());

      final categoryExpenses = _calculateCategoryExpenses(txs);
      final monthlyExpense = _calculateMonthlyExpense(txs);
      final averageDailyExpense = _calculateAverageDailyExpense(txs);

      final averageMonthlyExpense = monthlyExpense.isEmpty
          ? 0
          : monthlyExpense.values.reduce((a, b) => a + b) / monthlyExpense.length;

      final topCategories = _calculateTopCategories(categoryExpenses);

      return StatisticsData(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        categoryExpenses: categoryExpenses,
        monthlyExpense: monthlyExpense,
        averageDailyExpense: averageDailyExpense,
        averageMonthlyExpense: averageMonthlyExpense,
        topCategories: topCategories,
      );
    },
    loading: () => StatisticsData(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      categoryExpenses: {},
      monthlyExpense: {},
      averageDailyExpense: 0,
      averageMonthlyExpense: 0,
      topCategories: [],
    ),
    error: (_, __) => StatisticsData(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      categoryExpenses: {},
      monthlyExpense: {},
      averageDailyExpense: 0,
      averageMonthlyExpense: 0,
      topCategories: [],
    ),
  );
}

/// Monthly comparison data
/// Returns: {month -> (income, expense)}
@riverpod
Future<Map<String, (double, double)>> monthlyComparisonProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) {
      final monthly = <String, (double, double)>{};

      for (final tx in txs) {
        final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';

        if (!monthly.containsKey(key)) {
          monthly[key] = (0, 0);
        }

        if (tx.type == TransactionType.income) {
          final (income, expense) = monthly[key]!;
          monthly[key] = (income + tx.amount, expense);
        } else {
          final (income, expense) = monthly[key]!;
          monthly[key] = (income, expense + tx.amount.abs());
        }
      }

      return monthly;
    },
    loading: () => {},
    error: (_, __) => {},
  );
}

/// Year over year comparison
@riverpod
Future<Map<int, double>> yearComparisonProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) {
      final yearlyExpense = <int, double>{};

      for (final tx in txs) {
        if (tx.type == TransactionType.expense) {
          yearlyExpense[tx.date.year] =
              (yearlyExpense[tx.date.year] ?? 0) + tx.amount.abs();
        }
      }

      return yearlyExpense;
    },
    loading: () => {},
    error: (_, __) => {},
  );
}

/// Category percentage data
/// Returns: {category -> percentage}
@riverpod
Future<Map<String, double>> categoryPercentageProvider(Ref ref) async {
  final stats = ref.watch(statisticsProvider);

  return stats.when(
    data: (data) {
      if (data.totalExpense == 0) return {};

      final percentages = <String, double>{};

      for (final entry in data.categoryExpenses.entries) {
        percentages[entry.key] = (entry.value / data.totalExpense) * 100;
      }

      return percentages;
    },
    loading: () => {},
    error: (_, __) => {},
  );
}

/// Recent transactions (last 10)
@riverpod
Future<List<Transaction>> recentTransactionsProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) => txs.take(10).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// Spending trend (last 30 days)
@riverpod
Future<List<double>> spendingTrendProvider(Ref ref) async {
  final transactions = ref.watch(transactionsStreamProvider);

  return transactions.when(
    data: (txs) {
      final days = <DateTime, double>{};
      final now = DateTime.now();

      // Initialize last 30 days
      for (int i = 0; i < 30; i++) {
        final day = now.subtract(Duration(days: i));
        final dateOnly = DateTime(day.year, day.month, day.day);
        days[dateOnly] = 0;
      }

      // Calculate expenses per day
      for (final tx in txs) {
        if (tx.type == TransactionType.expense) {
          final dateOnly =
              DateTime(tx.date.year, tx.date.month, tx.date.day);
          if (days.containsKey(dateOnly)) {
            days[dateOnly] = (days[dateOnly] ?? 0) + tx.amount.abs();
          }
        }
      }

      // Return sorted by date (oldest first)
      final sorted = days.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return sorted.map((e) => e.value).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
}

/// Budget vs Actual (cần budget data từ Person 1)
/// For now, returning expense only
@riverpod
Future<double> budgetProgressProvider(Ref ref) async {
  final stats = ref.watch(statisticsProvider);

  return stats.when(
    data: (data) => data.totalExpense,
    loading: () => 0,
    error: (_, __) => 0,
  );
}
