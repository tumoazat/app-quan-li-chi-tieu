import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget_entity.dart';
import '../models/budget_model.dart';

/// Firestore-backed budget repository.
class BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('budgets');

  /// Creates or updates a budget document (upsert by userId+categoryId+month+year).
  Future<void> setBudget({
    required String userId,
    required String categoryId,
    required double monthlyLimit,
    required int month,
    required int year,
  }) async {
    final query = await _collection
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await _collection.doc(query.docs.first.id).update({
        'monthlyLimit': monthlyLimit,
      });
    } else {
      final model = BudgetModel(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        month: month,
        year: year,
        createdAt: DateTime.now(),
      );
      await _collection.doc(model.id).set(model.toFirestore());
    }
  }

  /// Fetches all budgets for a given user, month and year.
  Future<List<BudgetEntity>> getBudgets({
    required String userId,
    required int month,
    required int year,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs.map(BudgetModel.fromFirestore).toList();
  }

  /// Deletes a budget by its document id.
  Future<void> deleteBudget(String budgetId) async {
    await _collection.doc(budgetId).delete();
  }
}
