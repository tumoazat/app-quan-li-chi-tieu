import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/features/budgets/data/models/budget_model.dart';
import 'package:appchitieu/features/budgets/domain/entities/budget_entity.dart';

void main() {
  group('BudgetModel', () {
    final now = DateTime(2026, 2, 1);

    test('toFirestore produces correct map structure', () {
      final model = BudgetModel(
        id: 'test-id',
        userId: 'user-123',
        categoryId: 'expense_food',
        monthlyLimit: 2000000,
        month: 2,
        year: 2026,
        createdAt: now,
      );

      final map = model.toFirestore();

      expect(map['userId'], 'user-123');
      expect(map['categoryId'], 'expense_food');
      expect(map['monthlyLimit'], 2000000.0);
      expect(map['month'], 2);
      expect(map['year'], 2026);
      expect(map.containsKey('createdAt'), isTrue);
    });

    test('BudgetModel extends BudgetEntity', () {
      final model = BudgetModel(
        id: 'test-id',
        userId: 'user-123',
        categoryId: 'expense_food',
        monthlyLimit: 1500000,
        month: 2,
        year: 2026,
        createdAt: now,
      );

      expect(model, isA<BudgetEntity>());
      expect(model.monthlyLimit, 1500000);
    });
  });
}
