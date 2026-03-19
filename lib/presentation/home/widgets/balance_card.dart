import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/statistics_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/animation_helpers.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(monthKey),
    );

    return transactionsAsync.when(
      data: (transactions) {
        double totalIncome = 0;
        double totalExpense = 0;

        for (var transaction in transactions) {
          if (transaction.isIncome) {
            totalIncome += transaction.amount;
          } else {
            totalExpense += transaction.amount;
          }
        }

        final balance = totalIncome - totalExpense;

        return _buildCard(context, balance, totalIncome, totalExpense);
      },
      loading: () {
        return _buildCard(context, 0, 0, 0, isLoading: true);
      },
      error: (error, stack) {
        final stats = ref.watch(
          monthlyStatsProvider(monthKey),
        );
        return _buildCard(
          context, stats.balance, stats.totalIncome, stats.totalExpense,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    double balance,
    double totalIncome,
    double totalExpense, {
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.cardGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with eye icon
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Số dư hiện tại',
                style: AppTypography.bodySmall(context).copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Balance amount with counter animation
          isLoading
              ? const SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : AnimatedCounter(
                  value: balance,
                  formatter: (v) => CurrencyFormatter.formatVND(v),
                  style: AppTypography.displayLarge(context).copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                  duration: const Duration(milliseconds: 1000),
                ),
          
          const SizedBox(height: 20),
          
          // Income and Expense row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Thu nhập',
                  amount: totalIncome,
                  iconColor: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Chi tiêu',
                  amount: totalExpense,
                  iconColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .shimmer(
          duration: 2000.ms,
          delay: 1500.ms,
          color: Colors.white.withOpacity(0.08),
        );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color iconColor;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.amount,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(context).copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedCounter(
                  value: amount,
                  formatter: (v) => CurrencyFormatter.formatVND(v),
                  style: AppTypography.titleMedium(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  duration: const Duration(milliseconds: 800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
