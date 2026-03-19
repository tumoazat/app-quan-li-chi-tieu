import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String type; // 'expense' or 'income'
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.type,
    this.sortOrder = 0,
  });

  // Copy with method
  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    Color? color,
    String? type,
    int? sortOrder,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color': color.value,
      'type': type,
      'sortOrder': sortOrder,
    };
  }

  // Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      color: Color(json['color'] as int),
      type: json['type'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, emoji: $emoji, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.emoji == emoji &&
        other.color == color &&
        other.type == type &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        emoji.hashCode ^
        color.hashCode ^
        type.hashCode ^
        sortOrder.hashCode;
  }
}
