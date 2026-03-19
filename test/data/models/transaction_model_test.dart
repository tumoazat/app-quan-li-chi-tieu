import 'package:flutter_test/flutter_test.dart';
import 'package:appchitieu/data/models/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    final now = DateTime(2026, 2, 27);

    test('tạo TransactionModel với đầy đủ thông tin', () {
      final transaction = TransactionModel(
        id: 'test-id',
        userId: 'user-123',
        amount: 150000,
        type: TransactionType.expense,
        categoryId: 'food',
        note: 'Ăn trưa',
        date: now,
        createdAt: now,
      );

      expect(transaction.id, 'test-id');
      expect(transaction.userId, 'user-123');
      expect(transaction.amount, 150000);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.categoryId, 'food');
      expect(transaction.note, 'Ăn trưa');
    });

    test('isExpense trả về true khi type là expense', () {
      final transaction = TransactionModel(
        id: 'test-id',
        userId: 'user-123',
        amount: 50000,
        type: TransactionType.expense,
        categoryId: 'food',
        note: '',
        date: now,
        createdAt: now,
      );
      // Kiểm tra getter isExpense
      expect(transaction.isExpense, isTrue);
      expect(transaction.isIncome, isFalse);
    });

    test('isIncome trả về true khi type là income', () {
      final transaction = TransactionModel(
        id: 'test-id',
        userId: 'user-123',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'salary',
        note: 'Lương tháng',
        date: now,
        createdAt: now,
      );
      // Kiểm tra getter isIncome
      expect(transaction.isIncome, isTrue);
      expect(transaction.isExpense, isFalse);
    });

    test('toFirestore tạo map đúng cấu trúc', () {
      final transaction = TransactionModel(
        id: 'test-id',
        userId: 'user-123',
        amount: 100000,
        type: TransactionType.expense,
        categoryId: 'food',
        note: 'Test',
        date: now,
        createdAt: now,
      );

      final map = transaction.toFirestore();
      expect(map['userId'], 'user-123');
      expect(map['amount'], 100000);
      // type được lưu dạng string 'expense' trong Firestore
      expect(map['type'], 'expense');
      expect(map['categoryId'], 'food');
    });
  });
}
