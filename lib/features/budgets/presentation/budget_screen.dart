import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/category_data.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../providers/auth_provider.dart';
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
                ...budgets.asMap().entries.map((e) {
                  final budget = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BudgetCard(
                      budget: budget,
                      spent: 0, // Simplified - category breakdown not available
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
