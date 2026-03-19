/// File name: statistics_screen.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Statistics dashboard with charts
///
/// Responsibilities:
/// - Display statistics overview
/// - Show category pie chart
/// - Show monthly trend line chart
/// - Show recent transactions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/categories.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/transaction_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedPeriod = 'month'; // month, quarter, year

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiêu'),
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              _buildSummaryCards(stats),
              const SizedBox(height: 24),

              // Category pie chart
              _buildCategoryChart(stats),
              const SizedBox(height: 24),

              // Monthly trend
              _buildMonthlyTrendChart(),
              const SizedBox(height: 24),

              // Top categories
              _buildTopCategories(stats),
              const SizedBox(height: 24),

              // Recent transactions
              _buildRecentTransactions(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }

  /// Summary cards (Income, Expense, Balance)
  Widget _buildSummaryCards(StatisticsData stats) {
    return Column(
      children: [
        // Income
        _SummaryCard(
          title: 'Thu nhập',
          amount: stats.totalIncome,
          icon: Icons.arrow_upward,
          color: Colors.green,
        ),
        const SizedBox(height: 12),

        // Expense
        _SummaryCard(
          title: 'Chi tiêu',
          amount: stats.totalExpense,
          icon: Icons.arrow_downward,
          color: Colors.red,
        ),
        const SizedBox(height: 12),

        // Balance
        _SummaryCard(
          title: 'Số dư',
          amount: stats.balance,
          icon: Icons.account_balance_wallet,
          color: stats.balance >= 0 ? Colors.blue : Colors.orange,
        ),
      ],
    );
  }

  /// Category pie chart
  Widget _buildCategoryChart(StatisticsData stats) {
    if (stats.categoryExpenses.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text('Không có dữ liệu'),
        ),
      );
    }

    final entries = stats.categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalExpense = entries.fold(0.0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Chi tiêu theo danh mục',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: entries.map((entry) {
                    final percentage = (entry.value / totalExpense) * 100;
                    return PieChartSectionData(
                      color: CategoryColor.getColor(entry.key),
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: CategoryColor.getColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${entry.key}: ${CurrencyFormatter.format(entry.value)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Monthly trend line chart
  Widget _buildMonthlyTrendChart() {
    final trendAsync = ref.watch(spendingTrendProvider);

    return trendAsync.when(
      data: (trend) {
        if (trend.isEmpty) {
          return Card(
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: const Text('Không có dữ liệu'),
            ),
          );
        }

        final maxY = trend.isEmpty ? 0.0 : trend.reduce((a, b) => a > b ? a : b);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Xu hướng chi tiêu (30 ngày)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index % 5 != 0) return const SizedBox();
                              return Text(
                                '$index',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                CurrencyFormatter.formatCompact(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: trend
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: Colors.red,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true),
                        ),
                      ],
                      maxY: maxY * 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: SizedBox(
          height: 300,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: SizedBox(
          height: 300,
          child: Center(child: Text('Lỗi: $error')),
        ),
      ),
    );
  }

  /// Top categories
  Widget _buildTopCategories(StatisticsData stats) {
    if (stats.topCategories.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh mục chi tiêu nhiều nhất',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...stats.topCategories.map((category) {
              final amount = stats.categoryExpenses[category] ?? 0;
              final percentage = (amount / stats.totalExpense) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${CategoryIcon.getIcon(category)} $category',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            CategoryColor.getColor(category),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}% - ${CurrencyFormatter.format(amount)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Recent transactions
  Widget _buildRecentTransactions() {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return recentAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Không có giao dịch',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...transactions.take(5).map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          CategoryIcon.getIcon(tx.category),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                CurrencyFormatter.formatRelativeDate(tx.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatWithSign(tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: SizedBox(
          height: 100,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }
}

/// Summary Card Widget
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withAlpha(200), color.withAlpha(100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
