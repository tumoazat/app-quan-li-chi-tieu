import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/statistics_provider.dart';

class InsightCard extends StatelessWidget {
  final MonthlyStats stats;

  const InsightCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final averagePerTransaction = stats.transactionCount > 0
        ? stats.totalExpense / stats.transactionCount
        : 0.0;

    return Card(
      color: primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '💡',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tổng quan',
                  style: AppTypography.titleLarge(context).copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Insights with staggered animation
            _InsightRow(
              label: 'Tổng số giao dịch',
              value: '${stats.transactionCount}',
              primaryColor: primaryColor,
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideX(begin: -0.05, end: 0, duration: 300.ms, delay: 200.ms),
            const SizedBox(height: 12),
            
            _InsightRow(
              label: 'Trung bình mỗi giao dịch',
              value: CurrencyFormatter.formatVND(averagePerTransaction),
              primaryColor: primaryColor,
            ).animate().fadeIn(duration: 300.ms, delay: 350.ms).slideX(begin: -0.05, end: 0, duration: 300.ms, delay: 350.ms),
            const SizedBox(height: 12),
            
            _InsightRow(
              label: 'Tỷ lệ tiết kiệm',
              value: '${stats.savingRate.toStringAsFixed(1)}%',
              primaryColor: primaryColor,
              valueColor: stats.savingRate >= 0
                  ? primaryColor
                  : Theme.of(context).colorScheme.error,
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms).slideX(begin: -0.05, end: 0, duration: 300.ms, delay: 500.ms),
            
            // Additional insight message
            if (stats.savingRate < 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '⚠️',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chi tiêu vượt thu nhập. Hãy cân nhắc giảm chi tiêu!',
                        style: AppTypography.bodySmall(context).copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (stats.savingRate >= 20) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '🎉',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tuyệt vời! Bạn đang tiết kiệm rất tốt!',
                        style: AppTypography.bodySmall(context).copyWith(
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final Color primaryColor;
  final Color? valueColor;

  const _InsightRow({
    required this.label,
    required this.value,
    required this.primaryColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium(context).copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text.rich(
          TextSpan(
            text: value,
            style: AppTypography.titleMedium(context).copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
