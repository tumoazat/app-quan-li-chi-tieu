import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/budget_entity.dart';

/// Firestore-backed model for [BudgetEntity].
class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.monthlyLimit,
    required super.month,
    required super.year,
    required super.createdAt,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
      month: (data['month'] as num).toInt(),
      year: (data['year'] as num).toInt(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
