import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/category_data.dart';
import '../../../providers/statistics_provider.dart';

class CategoryBreakdown extends ConsumerWidget {
  final String monthKey;

  const CategoryBreakdown({
    super.key,
    required this.monthKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(monthlyStatsProvider(monthKey));
    final percentagesAsync = ref.watch(categorySpendingPercentageProvider(monthKey));

    return statsAsync.when(
      data: (stats) {
        if (stats.categoryBreakdown.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort categories by amount descending
        final sortedCategories = stats.categoryBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return percentagesAsync.when(
          data: (percentages) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân tích chi tiêu',
                      style: AppTypography.headlineMedium(context),
                    ),
                    const SizedBox(height: 16),
                    
                    ...sortedCategories.map((entry) {
                      final categoryId = entry.key;
                      final amount = entry.value;
                      final category = CategoryModel.findById(categoryId);
                      final percentage = percentages[categoryId] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CategoryItem(
                          emoji: category?.emoji ?? '📦',
                          name: category?.name ?? 'Khác',
                          amount: amount,
                          percentage: percentage,
                          color: category?.color ?? Colors.grey,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String emoji;
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const _CategoryItem({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: AppTypography.titleMedium(context),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatVND(amount),
                  style: AppTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall(context).copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Static progress bar for better performance
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            width: double.infinity,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}
