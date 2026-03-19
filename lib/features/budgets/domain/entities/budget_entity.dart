/// Domain entity for a monthly category budget.
class BudgetEntity {
  final String id;
  final String userId;
  final String categoryId;
  final double monthlyLimit;
  final int month;
  final int year;
  final DateTime createdAt;

  const BudgetEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
    required this.createdAt,
  });
}
