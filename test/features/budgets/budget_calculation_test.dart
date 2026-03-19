import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/features/budgets/domain/usecases/calculate_budget_progress_usecase.dart';

void main() {
  const useCase = CalculateBudgetProgressUseCase();

  group('CalculateBudgetProgressUseCase', () {
    test('returns 0% when there is no spending', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 0,
      );
      expect(result.percentage, 0);
    });

    test('calculates correct percentage', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 500000,
      );
      expect(result.percentage, closeTo(50.0, 0.01));
    });

    test('returns green color when under 70%', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 600000,
      );
      expect(result.statusColor.value, const Color(0xFF4CAF50).value);
    });

    test('returns orange color when between 70% and 90%', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 800000,
      );
      expect(result.statusColor.value, const Color(0xFFFF9800).value);
    });

    test('returns red color when over 90%', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 950000,
      );
      expect(result.statusColor.value, const Color(0xFFF44336).value);
    });

    test('handles overspend (> 100%) correctly', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 1000000,
        spent: 1500000,
      );
      expect(result.percentage, closeTo(150.0, 0.01));
      expect(result.isExceeded, isTrue);
      expect(result.statusColor.value, const Color(0xFFF44336).value);
    });

    test('handles zero limit gracefully', () {
      final result = useCase.call(
        categoryId: 'expense_food',
        limit: 0,
        spent: 100000,
      );
      expect(result.percentage, 0.0);
    });
  });
}
