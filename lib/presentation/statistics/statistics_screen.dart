import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/animation_helpers.dart';
import '../../providers/statistics_provider.dart';
import '../shared/empty_state.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../features/export/application/export_report_usecase.dart';
import 'widgets/pie_chart_section.dart';
import 'widgets/bar_chart_section.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/insight_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final stats = ref.watch(monthlyStatsProvider(monthKey));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: stats.transactionCount == 0
            ? EmptyState.noData()
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(begin: 0.9, end: 1.0, duration: 500.ms)
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Title row with export button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thống kê',
                          style: AppTypography.headlineLarge(context),
                        ).fadeInSlideUp(index: 0),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          tooltip: 'Xuất PDF',
                          onPressed: () => _exportPdf(context, ref, now.month, now.year),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Summary cards - staggered entry
                    Row(
                      children: [
                        Expanded(
                          child: _AnimatedSummaryCard(
                            title: 'Thu nhập',
                            amount: stats.totalIncome,
                            color: Theme.of(context).colorScheme.primary,
                            icon: '💰',
                            delay: 100,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnimatedSummaryCard(
                            title: 'Chi tiêu',
                            amount: stats.totalExpense,
                            color: Theme.of(context).colorScheme.error,
                            icon: '💸',
                            delay: 200,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnimatedSummaryCard(
                            title: 'Số dư',
                            amount: stats.balance,
                            color: stats.balance >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            icon: '💵',
                            delay: 300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pie Chart Section
                    if (stats.categoryBreakdown.isNotEmpty) ...[
                      PieChartSection(
                        categoryBreakdown: stats.categoryBreakdown,
                        totalExpense: stats.totalExpense,
                      ).scaleIn(index: 5),
                      const SizedBox(height: 24),
                    ],

                    // Bar Chart Section
                    const BarChartSection().fadeInSlideUp(index: 7),
                    const SizedBox(height: 24),

                    // Category Breakdown
                    if (stats.categoryBreakdown.isNotEmpty) ...[                    
                      CategoryBreakdown(monthKey: monthKey).fadeInSlideUp(index: 9),
                      const SizedBox(height: 24),
                    ],

                    // Insight Card
                    InsightCard(stats: stats).scaleIn(index: 11),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, int month, int year) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final useCase = ref.read(exportReportUseCaseProvider);
      await useCase.call(userId: user.uid, month: month, year: year);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AnimatedSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String icon;
  final int delay;

  const _AnimatedSummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
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
              child: AnimatedCounter(
                value: amount,
                formatter: (v) => CurrencyFormatter.formatCompact(v),
                style: AppTypography.titleLarge(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                duration: Duration(milliseconds: 800 + delay),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: Duration(milliseconds: delay), curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
