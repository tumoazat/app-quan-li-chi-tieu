import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class FinancialSummaryHeader extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double budget;

  const FinancialSummaryHeader({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetPercent = budget > 0 ? (totalExpense / budget * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D3A)]
              : [const Color(0xFFF8F9FF), const Color(0xFFEEF1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildItem(
                  context,
                  '📈',
                  'Thu nhập',
                  CurrencyFormatter.formatCompact(totalIncome),
                  isDark ? AppColors.incomeDark : AppColors.incomeLight,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              Expanded(
                child: _buildItem(
                  context,
                  '📉',
                  'Chi tiêu',
                  CurrencyFormatter.formatCompact(totalExpense),
                  isDark ? AppColors.expenseDark : AppColors.expenseLight,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              Expanded(
                child: _buildItem(
                  context,
                  '💰',
                  'Số dư',
                  CurrencyFormatter.formatCompact(balance),
                  balance >= 0
                      ? (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                      : (isDark ? AppColors.expenseDark : AppColors.expenseLight),
                ),
              ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 8),
            // Budget progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budgetPercent > 100 ? 1.0 : budgetPercent / 100,
                minHeight: 4,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  budgetPercent >= 90
                      ? AppColors.error
                      : budgetPercent >= 70
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ngân sách: ${budgetPercent.toStringAsFixed(0)}% đã dùng',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
