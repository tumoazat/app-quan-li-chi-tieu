import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/statistics_provider.dart';
import '../shared/empty_state.dart';
import '../../core/utils/currency_formatter.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final statsAsync = ref.watch(simpleStatsProvider(monthKey));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: statsAsync.when(
          data: (stats) => stats.totalIncome == 0 && stats.totalExpense == 0
              ? EmptyState.noData()
              : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Thống kê',
                        style: AppTypography.headlineLarge(context),
                      ),
                      const SizedBox(height: 20),
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Thu nhập',
                              amount: stats.totalIncome,
                              color: Theme.of(context).colorScheme.primary,
                              icon: '💰',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Khoản này',
                              amount: stats.totalExpense,
                              color: Theme.of(context).colorScheme.error,
                              icon: '💸',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Số dư',
                              amount: stats.balance,
                              color: stats.balance >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              icon: '💵',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Pie chart with categories
                      _PieChartWithCategories(
                        categoryExpense: stats.categoryExpense,
                      ),
                      const SizedBox(height: 32),
                      // Category analysis
                      _CategoryAnalysis(
                        categoryExpense: stats.categoryExpense,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Lỗi: $error'),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMedium(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatCompact(amount),
                style: AppTypography.titleLarge(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartWithCategories extends StatelessWidget {
  final Map<String, double> categoryExpense;

  const _PieChartWithCategories({
    required this.categoryExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryExpense.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiêu theo danh mục',
                style: AppTypography.headlineMedium(context),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Chưa có dữ liệu',
                  style: AppTypography.bodyMedium(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = categoryExpense.values.fold<double>(0, (a, b) => a + b);
    final sorted = categoryExpense.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFF004E89),
      const Color(0xFF1B9CFC),
      const Color(0xFFF97306),
      const Color(0xFF6C757D),
      const Color(0xFF28A745),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu theo danh mục',
              style: AppTypography.headlineMedium(context),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 140,
                width: 140,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    data: sorted,
                    total: total,
                    colors: colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Category list
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sorted.length.clamp(0, 3),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = sorted[index];
                final categoryId = entry.key;
                final amount = entry.value;

                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        categoryId,
                        style: AppTypography.labelSmall(context),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatCompact(amount),
                      style: AppTypography.labelSmall(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAnalysis extends StatelessWidget {
  final Map<String, double> categoryExpense;

  const _CategoryAnalysis({
    required this.categoryExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryExpense.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = categoryExpense.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phân tích chi tiêu',
              style: AppTypography.headlineMedium(context),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = sorted[index];
                final categoryId = entry.key;
                final amount = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryId,
                          style: AppTypography.labelMedium(context),
                        ),
                        Text(
                          CurrencyFormatter.formatCompact(amount),
                          style: AppTypography.labelMedium(context)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: 0.5,
                        backgroundColor:
                            Theme.of(context).colorScheme.error.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;
  final List<Color> colors;

  _DonutChartPainter({
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;

    double startAngle = -3.14159 / 2;

    for (var i = 0; i < data.length; i++) {
      final entry = data[i];
      final amount = entry.value;
      final sweepAngle = (amount / total) * 2 * 3.14159;

      // Draw outer arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()..color = colors[i % colors.length],
      );

      // Erase inner part to create donut
      canvas.drawCircle(
        center,
        innerRadius,
        Paint()..color = Colors.white,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
