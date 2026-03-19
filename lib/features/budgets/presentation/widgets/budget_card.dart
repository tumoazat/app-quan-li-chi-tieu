import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/category_data.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/calculate_budget_progress_usecase.dart';
import 'budget_progress_bar.dart';

/// Card displaying a single category budget with progress.
class BudgetCard extends StatelessWidget {
  final BudgetEntity budget;
  final double spent;
  final int index;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const calculator = CalculateBudgetProgressUseCase();
    final progress = calculator.call(
      categoryId: budget.categoryId,
      limit: budget.monthlyLimit,
      spent: spent,
    );
    final category = CategoryModel.findById(budget.categoryId);

    return Card(
      elevation: 2,
      shadowColor: progress.statusColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category?.emoji ?? '📦',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category?.name ?? 'Danh mục',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatCompact(spent),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: progress.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '/ ${CurrencyFormatter.formatCompact(budget.monthlyLimit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetProgressBar(progress: progress),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 80))
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: index * 80),
          curve: Curves.easeOutCubic,
        );
  }
}
