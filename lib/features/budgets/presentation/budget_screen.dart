import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/category_data.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/statistics_provider.dart';
import '../application/budget_notifier.dart';
import 'widgets/budget_card.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now();
    ref
        .read(budgetNotifierProvider.notifier)
        .getBudgets(user.uid, now.month, now.year);
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final stats = ref.watch(monthlyStatsProvider(monthKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm ngân sách',
            onPressed: user == null ? null : () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: budgetsAsync.when(
        data: (budgets) {
          // Alert if any budget exceeded
          final hasExceeded = budgets.any((b) {
            final spent = stats.categoryBreakdown[b.categoryId] ?? 0;
            return spent > b.monthlyLimit;
          });

          if (budgets.isEmpty) {
            return AppEmptyState(
              icon: '🎯',
              title: 'Chưa có ngân sách',
              subtitle: 'Thiết lập ngân sách để kiểm soát chi tiêu tốt hơn.',
              buttonLabel: 'Thêm ngân sách',
              onButtonPressed:
                  user == null ? null : () => _showAddDialog(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (hasExceeded)
                  const _ExceededAlert()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .shake(hz: 3, offset: const Offset(2, 0), duration: 400.ms),
                if (hasExceeded) const SizedBox(height: 12),
                ...budgets.asMap().entries.map((e) {
                  final budget = e.value;
                  final spent = stats.categoryBreakdown[budget.categoryId] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(
                      budget: budget,
                      spent: spent,
                      index: e.key,
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: AppEmptyState(
            icon: '⚠️',
            title: 'Có lỗi xảy ra',
            subtitle: e.toString(),
            buttonLabel: 'Thử lại',
            onButtonPressed: _load,
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    String? selectedCategoryId;
    final limitController = TextEditingController();
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm ngân sách'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                hint: const Text('Chọn danh mục'),
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: CategoryModel.defaultExpenseCategories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.emoji} ${c.name}'),
                  );
                }).toList(),
                onChanged: (v) => setDialogState(() => selectedCategoryId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hạn mức (VNĐ)',
                  suffixText: '₫',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final limit = double.tryParse(limitController.text);
                final user = ref.read(currentUserProvider);
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn danh mục')),
                  );
                  return;
                }
                if (limit == null || limit <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0)')),
                  );
                  return;
                }
                if (user == null) return;
                await ref.read(budgetNotifierProvider.notifier).setBudget(
                      userId: user.uid,
                      categoryId: selectedCategoryId!,
                      monthlyLimit: limit,
                      month: now.month,
                      year: now.year,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExceededAlert extends StatelessWidget {
  const _ExceededAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Một số danh mục đã vượt ngân sách tháng này!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF44336),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
