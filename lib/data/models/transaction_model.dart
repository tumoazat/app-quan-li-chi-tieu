/// File name: transaction_model.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Transaction data model with serialization
///
/// Responsibilities:
/// - Define transaction entity structure
/// - Handle JSON serialization/deserialization
/// - Type definitions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Enum định nghĩa loại giao dịch
enum TransactionType {
  income('Thu nhập'),
  expense('Chi tiêu');

  final String label;
  const TransactionType(this.label);
}

/// Transaction Model - Đại diện cho một giao dịch tài chính
class Transaction {
  /// ID duy nhất của giao dịch
  final String id;

  /// ID người dùng sở hữu giao dịch
  final String userId;

  /// Loại giao dịch (thu nhập/chi tiêu)
  final TransactionType type;

  /// Số tiền (dương = thu nhập, âm = chi tiêu)
  final double amount;

  /// Danh mục (ví dụ: 'Ăn uống', 'Giao thông')
  final String category;

  /// Mô tả chi tiết
  final String? description;

  /// Ngày tạo giao dịch
  final DateTime date;

  /// Timestamp tạo record
  final DateTime createdAt;

  /// Timestamp cập nhật lần cuối
  final DateTime updatedAt;

  /// Constructor
  Transaction({
    String? id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Copy with - Tạo copy với các field được thay đổi
  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert từ Firestore JSON
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String?,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert từ Firestore DocumentSnapshot
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() =>
      'Transaction(id: $id, type: ${type.label}, amount: $amount, category: $category, date: $date)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
