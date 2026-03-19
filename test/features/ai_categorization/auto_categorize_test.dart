import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/features/ai_categorization/data/auto_category_service.dart';

void main() {
  late AutoCategoryService service;

  setUp(() {
    service = AutoCategoryService();
  });

  group('AutoCategoryService', () {
    test('returns correct category for known food keyword', () {
      final result = service.categorize('ăn phở bò');
      expect(result.categoryId, 'expense_food');
      expect(result.confidence, greaterThan(0));
    });

    test('returns correct category for transport keyword', () {
      final result = service.categorize('đổ xăng xe máy');
      expect(result.categoryId, 'expense_transport');
    });

    test('returns correct category for coffee keyword', () {
      final result = service.categorize('uống cafe sáng');
      expect(result.categoryId, 'expense_coffee');
    });

    test('returns fallback for unknown text', () {
      final result = service.categorize('xyz_unknown_text_12345');
      expect(result.categoryId, 'expense_others');
      expect(result.confidence, 0.0);
    });

    test('is case-insensitive', () {
      final result1 = service.categorize('PHỞ bò');
      final result2 = service.categorize('phở bò');
      expect(result1.categoryId, result2.categoryId);
    });

    test('returns empty result for empty input', () {
      final result = service.categorize('');
      expect(result.categoryId, 'expense_others');
      expect(result.confidence, 0);
    });

    test('matches longer keyword with higher score', () {
      // 'cà phê' (7 chars) should win over 'ăn' (2 chars) when both present
      final result = service.categorize('cà phê buổi sáng');
      expect(result.categoryId, 'expense_coffee');
    });

    test('returns salary category for lương keyword', () {
      final result = service.categorize('nhận lương tháng 2');
      expect(result.categoryId, 'income_salary');
    });
  });
}
