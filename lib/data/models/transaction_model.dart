/// File name: transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final TransactionType type;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.type,
    required this.date,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'],
      amount: (map['amount']).toDouble(),
      category: map['category'],
      note: map['note'] ?? '',
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'type': type.name,
      'date': Timestamp.fromDate(date),
    };
  }
}
