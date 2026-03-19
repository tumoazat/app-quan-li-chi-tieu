import '../../data/repositories/budget_repository.dart';

/// Use case: create or update a category budget for a given month/year.
class CreateBudgetUseCase {
  final BudgetRepository repository;

  const CreateBudgetUseCase(this.repository);

  /// Validates [monthlyLimit] > 0 before persisting.
  Future<void> call({
    required String userId,
    required String categoryId,
    required double monthlyLimit,
    required int month,
    required int year,
  }) async {
    if (monthlyLimit <= 0) {
      throw ArgumentError('monthlyLimit must be greater than zero');
    }
    await repository.setBudget(
      userId: userId,
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
      month: month,
      year: year,
    );
  }
}
