import '../entities/budget_entity.dart';
import '../../data/repositories/budget_repository.dart';

/// Use case: fetch all budgets for a given month/year.
class GetMonthlyBudgetUseCase {
  final BudgetRepository repository;

  const GetMonthlyBudgetUseCase(this.repository);

  Future<List<BudgetEntity>> call({
    required String userId,
    required int month,
    required int year,
  }) {
    return repository.getBudgets(userId: userId, month: month, year: year);
  }
}
