import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';

class BudgetProgress extends StatelessWidget {
  final double spent;
  final double budget;

  const BudgetProgress({
    super.key,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final percentUsed = budget > 0 ? (spent / budget) * 100 : 0.0;
    final remaining = budget - spent;
    
    Color progressColor;
    if (percentUsed >= 90) {
      progressColor = AppColors.error;
    } else if (percentUsed >= 70) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngân sách tháng này',
              style: AppTypography.headlineMedium(context),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: Duration(milliseconds: AppConstants.animationNormal),
                height: 12,
                child: LinearProgressIndicator(
                  value: percentUsed > 100 ? 1.0 : percentUsed / 100,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingLg),
            
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    context,
                    'Đã chi',
                    CurrencyFormatter.formatVND(spent),
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    'Ngân sách',
                    CurrencyFormatter.formatVND(budget),
                  ),
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    'Còn lại',
                    CurrencyFormatter.formatVND(remaining),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(context),
        ),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          value,
          style: AppTypography.titleMedium(context),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
