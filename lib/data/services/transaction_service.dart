/// File name: transaction_service.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Transaction service with Firestore integration
///
/// Responsibilities:
/// - CRUD operations for transactions
/// - Firestore integration
/// - Query optimization

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

/// Exception class cho transaction service
class TransactionException implements Exception {
  final String message;
  TransactionException(this.message);

  @override
  String toString() => 'TransactionException: $message';
}

/// Transaction Service - Xử lý tất cả database operations
class TransactionService {
  /// Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name
  static const String _collectionName = 'transactions';

  /// ✅ CREATE - Tạo giao dịch mới
  ///
  /// @param transaction: Transaction object
  /// @return ID của transaction vừa tạo
  /// @throws TransactionException nếu thất bại
  Future<String> createTransaction(Transaction transaction) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(transaction.toMap());

      debugPrint('✅ Transaction created: ${transaction.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to create transaction: $e');
    }
  }

  /// ✅ READ - Lấy một giao dịch theo ID
  ///
  /// @param transactionId: ID của transaction
  /// @return Transaction object hoặc null nếu không tìm thấy
  /// @throws TransactionException nếu thất bại
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(transactionId).get();

      if (!doc.exists) {
        return null;
      }

      return Transaction.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to get transaction: $e');
    }
  }

  /// ✅ READ - Lấy tất cả giao dịch của user
  ///
  /// @param userId: ID của user
  /// @return List<Transaction> sắp xếp theo date (mới nhất trước)
  /// @throws TransactionException nếu thất bại
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to get transactions: $e');
    }
  }

  /// ✅ READ - Lấy giao dịch trong khoảng thời gian
  ///
  /// @param userId: ID của user
  /// @param startDate: Ngày bắt đầu (mặc định: đầu tháng)
  /// @param endDate: Ngày kết thúc (mặc định: hiện tại)
  /// @return List<Transaction> sắp xếp theo date
  Future<List<Transaction>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to get transactions by date: $e');
    }
  }

  /// ✅ READ - Lấy giao dịch theo category
  ///
  /// @param userId: ID của user
  /// @param category: Tên category
  /// @return List<Transaction>
  Future<List<Transaction>> getTransactionsByCategory({
    required String userId,
    required String category,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to get transactions by category: $e');
    }
  }

  /// ✅ READ - Stream giao dịch real-time
  ///
  /// @param userId: ID của user
  /// @return Stream<List<Transaction>>
  Stream<List<Transaction>> streamUserTransactions(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
    } catch (e) {
      throw TransactionException('Failed to stream transactions: $e');
    }
  }

  /// ✅ UPDATE - Cập nhật giao dịch
  ///
  /// @param transaction: Transaction object (phải có id)
  /// @throws TransactionException nếu thất bại
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(transaction.id)
          .update({
        ...transaction.toMap(),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Transaction updated: ${transaction.id}');
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to update transaction: $e');
    }
  }

  /// ✅ DELETE - Xóa giao dịch
  ///
  /// @param transactionId: ID của transaction
  /// @throws TransactionException nếu thất bại
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection(_collectionName).doc(transactionId).delete();

      debugPrint('✅ Transaction deleted: $transactionId');
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to delete transaction: $e');
    }
  }

  /// ✅ Batch delete - Xóa nhiều giao dịch cùng lúc
  ///
  /// @param transactionIds: List ID của transactions
  Future<void> deleteMultipleTransactions(List<String> transactionIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in transactionIds) {
        batch.delete(_firestore.collection(_collectionName).doc(id));
      }

      await batch.commit();
      debugPrint('✅ ${transactionIds.length} transactions deleted');
    } on FirebaseException catch (e) {
      throw TransactionException('Firebase error: ${e.message}');
    } catch (e) {
      throw TransactionException('Failed to delete transactions: $e');
    }
  }
}

/// Debug print mặc định
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
