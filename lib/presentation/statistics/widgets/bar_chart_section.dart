import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/statistics_provider.dart';

class BarChartSection extends ConsumerWidget {
  const BarChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barChartData = ref.watch(barChartDataProvider);

    if (barChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleData = barChartData.length > 7
        ? barChartData.sublist(barChartData.length - 7)
        : barChartData;

    final maxValue =
      visibleData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final safeInterval = safeMaxY / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu hàng ngày',
              style: AppTypography.headlineMedium(context),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: safeMaxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: AppTypography.labelSmall(context),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: safeInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            CurrencyFormatter.formatCompact(value),
                            style: AppTypography.labelSmall(context),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: visibleData.asMap().entries.map((entry) {
                    final dataPoint = entry.value;
                    final day = int.parse(dataPoint.label);
                    
                    return BarChartGroupData(
                      x: day,
                      barRods: [
                        BarChartRodData(
                          toY: dataPoint.value,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.5),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: Duration.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
