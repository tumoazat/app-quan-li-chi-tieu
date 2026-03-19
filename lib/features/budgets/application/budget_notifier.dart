import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/budget_entity.dart';
import '../domain/usecases/create_budget_usecase.dart';
import '../domain/usecases/get_monthly_budget_usecase.dart';
import '../domain/usecases/calculate_budget_progress_usecase.dart';
import '../data/repositories/budget_repository.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>((ref) {
  return CreateBudgetUseCase(ref.read(budgetRepositoryProvider));
});

final getMonthlyBudgetUseCaseProvider = Provider<GetMonthlyBudgetUseCase>((ref) {
  return GetMonthlyBudgetUseCase(ref.read(budgetRepositoryProvider));
});

final calculateBudgetProgressUseCaseProvider =
    Provider<CalculateBudgetProgressUseCase>((ref) {
  return const CalculateBudgetProgressUseCase();
});

/// State: list of budgets for the currently viewed month.
final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<BudgetEntity>>>(
  (ref) => BudgetNotifier(ref),
);

// ── StateNotifier ─────────────────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetEntity>>> {
  final Ref _ref;

  BudgetNotifier(this._ref) : super(const AsyncValue.data([]));

  Future<void> getBudgets(String userId, int month, int year) async {
    state = const AsyncValue.loading();
    try {
      final useCase = _ref.read(getMonthlyBudgetUseCaseProvider);
      final budgets =
          await useCase.call(userId: userId, month: month, year: year);
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setBudget({
    required String userId,
    required String categoryId,
    required double monthlyLimit,
    required int month,
    required int year,
  }) async {
    try {
      final useCase = _ref.read(createBudgetUseCaseProvider);
      await useCase.call(
        userId: userId,
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        month: month,
        year: year,
      );
      // Reload budgets after change
      await getBudgets(userId, month, year);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
