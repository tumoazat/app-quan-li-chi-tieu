import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_provider.dart';
import '../../core/constants/category_data.dart';

// Monthly statistics model
class MonthlyStats {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryBreakdown;
  final Map<String, int> categoryCount;
  final int transactionCount;

  MonthlyStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryBreakdown,
    required this.categoryCount,
    required this.transactionCount,
  });

  double get savingRate {
    if (totalIncome == 0) return 0;
    return ((totalIncome - totalExpense) / totalIncome) * 100;
  }
}

// Chart data point
class ChartDataPoint {
  final String label;
  final double value;
  final String categoryId;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.categoryId,
  });
}

// Monthly stats provider
// Key format: "year-month" e.g. "2026-2"
final monthlyStatsProvider = Provider.autoDispose
    .family<MonthlyStats, String>((ref, monthKey) {
  final transactionsAsync = ref.watch(
    transactionsStreamProvider(monthKey),
  );

  return transactionsAsync.when(
    data: (transactions) {
      double totalIncome = 0;
      double totalExpense = 0;
      final Map<String, double> categoryBreakdown = {};
      final Map<String, int> categoryCount = {};

      for (var transaction in transactions) {
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }

        // Category breakdown (only for expenses)
        if (transaction.isExpense) {
          categoryBreakdown[transaction.categoryId] =
              (categoryBreakdown[transaction.categoryId] ?? 0) + 
              transaction.amount;
          categoryCount[transaction.categoryId] =
              (categoryCount[transaction.categoryId] ?? 0) + 1;
        }
      }

      return MonthlyStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        categoryBreakdown: categoryBreakdown,
        categoryCount: categoryCount,
        transactionCount: transactions.length,
      );
    },
    loading: () => MonthlyStats(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      categoryBreakdown: {},
      categoryCount: {},
      transactionCount: 0,
    ),
    error: (error, stack) => MonthlyStats(
      totalIncome: 0,
      totalExpense: 0,
      balance: 0,
      categoryBreakdown: {},
      categoryCount: {},
      transactionCount: 0,
    ),
  );
});

// Pie chart data provider
final pieChartDataProvider = Provider.autoDispose
    .family<List<ChartDataPoint>, String>((ref, monthKey) {
  final stats = ref.watch(monthlyStatsProvider(monthKey));
  final List<ChartDataPoint> dataPoints = [];

  stats.categoryBreakdown.forEach((categoryId, amount) {
    final category = CategoryModel.findById(categoryId);
    dataPoints.add(ChartDataPoint(
      label: category?.name ?? 'Khác',
      value: amount,
      categoryId: categoryId,
    ));
  });

  // Sort by value descending
  dataPoints.sort((a, b) => b.value.compareTo(a.value));

  return dataPoints;
});

// Bar chart data provider (daily spending for current month)
final barChartDataProvider = Provider.autoDispose<List<ChartDataPoint>>((ref) {
  final now = DateTime.now();
  final transactionsAsync = ref.watch(
    transactionsStreamProvider('${now.year}-${now.month}'),
  );

  return transactionsAsync.when(
    data: (transactions) {
      // Group expenses by day
      final Map<int, double> dailyExpenses = {};

      for (var transaction in transactions) {
        if (transaction.isExpense) {
          final day = transaction.date.day;
          dailyExpenses[day] = (dailyExpenses[day] ?? 0) + transaction.amount;
        }
      }

      // Convert to chart data points
      final List<ChartDataPoint> dataPoints = [];
      dailyExpenses.forEach((day, amount) {
        dataPoints.add(ChartDataPoint(
          label: day.toString(),
          value: amount,
          categoryId: '',
        ));
      });

      // Sort by day
      dataPoints.sort((a, b) => 
          int.parse(a.label).compareTo(int.parse(b.label)));

      return dataPoints;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Top spending category provider
final topSpendingCategoryProvider = Provider.autoDispose
    .family<String?, String>((ref, monthKey) {
  final stats = ref.watch(monthlyStatsProvider(monthKey));

  if (stats.categoryBreakdown.isEmpty) return null;

  // Find category with highest spending
  String topCategory = '';
  double maxAmount = 0;

  stats.categoryBreakdown.forEach((categoryId, amount) {
    if (amount > maxAmount) {
      maxAmount = amount;
      topCategory = categoryId;
    }
  });

  return topCategory;
});

// Category spending percentage provider
final categorySpendingPercentageProvider = Provider.autoDispose
    .family<Map<String, double>, String>((ref, monthKey) {
  final stats = ref.watch(monthlyStatsProvider(monthKey));
  final Map<String, double> percentages = {};

  if (stats.totalExpense == 0) return percentages;

  stats.categoryBreakdown.forEach((categoryId, amount) {
    percentages[categoryId] = (amount / stats.totalExpense) * 100;
  });

  return percentages;
});
