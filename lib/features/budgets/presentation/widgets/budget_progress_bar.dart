import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/usecases/calculate_budget_progress_usecase.dart';

/// Animated progress bar for a budget item.
class BudgetProgressBar extends StatelessWidget {
  final BudgetProgress progress;

  const BudgetProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final clamped = (progress.percentage / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: progress.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (progress.isExceeded)
              Text(
                'Vượt ngân sách!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: progress.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: progress.statusColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(progress.statusColor),
          ),
        ).animate().fadeIn(
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}
