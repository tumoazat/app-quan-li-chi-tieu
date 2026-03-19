import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? note;
  final String? imageUrl;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    this.imageUrl,
    required this.createdAt,
  });

  // Factory constructor from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] == 'income' 
          ? TransactionType.income 
          : TransactionType.expense,
      categoryId: data['categoryId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'categoryId': categoryId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? note,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Formatted amount getter
  String get formattedAmount {
    return amount.toStringAsFixed(0);
  }

  // Is expense
  bool get isExpense => type == TransactionType.expense;

  // Is income
  bool get isIncome => type == TransactionType.income;

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, type: $type, categoryId: $categoryId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TransactionModel &&
        other.id == id &&
        other.userId == userId &&
        other.amount == amount &&
        other.type == type &&
        other.categoryId == categoryId &&
        other.date == date &&
        other.note == note &&
        other.imageUrl == imageUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        amount.hashCode ^
        type.hashCode ^
        categoryId.hashCode ^
        date.hashCode ^
        note.hashCode ^
        imageUrl.hashCode ^
        createdAt.hashCode;
  }
}
