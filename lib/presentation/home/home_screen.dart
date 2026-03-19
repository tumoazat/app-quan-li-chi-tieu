import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/animation_helpers.dart';
import '../shared/empty_state.dart';
import '../transactions/add_transaction_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/transaction_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransactionsAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentTransactionsProvider);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Header with avatar and greeting — slide in from left
                  const HomeHeader().fadeInSlideLeft(index: 0),
                  const SizedBox(height: 24),
                  
                  // Balance card — scale in with slight delay
                  const BalanceCard().scaleIn(index: 2),
                  const SizedBox(height: 24),
                  
                  // Quick actions — staggered scale in
                  const QuickActionsRow().fadeInSlideUp(index: 4),
                  const SizedBox(height: 24),
                  
                  // Recent transactions title — fade in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giao dịch gần đây',
                        style: AppTypography.headlineMedium(context),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ).fadeInSlideUp(index: 6),
                  const SizedBox(height: 16),
                  
                  // Recent transactions list with staggered entry
                  recentTransactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return EmptyState.noTransactions()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms);
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return TransactionItem(
                            transaction: transaction,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AddTransactionSheet(
                                  editTransaction: transaction,
                                ),
                              );
                            },
                            onDelete: () async {
                              final user = ref.read(currentUserProvider);
                              if (user != null) {
                                try {
                                  await ref.read(transactionRepositoryProvider).deleteTransaction(
                                    user.uid,
                                    transaction.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã xóa giao dịch'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 600 + (index * 80)),
                          ).slideX(
                            begin: -0.06,
                            end: 0,
                            duration: 300.ms,
                            delay: Duration(milliseconds: 600 + (index * 80)),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      );
                    },
                    loading: () => Column(
                      children: List.generate(3, (index) =>
                        Container(
                          height: 72,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).animate(
                          onPlay: (controller) => controller.repeat(),
                        ).shimmer(
                          duration: 1200.ms,
                          delay: Duration(milliseconds: index * 200),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        ),
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: EmptyState.error(
                          message: 'Không thể tải giao dịch',
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).shake(delay: 400.ms, hz: 2, offset: const Offset(2, 0)),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
