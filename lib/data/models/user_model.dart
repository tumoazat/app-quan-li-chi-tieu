import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final double monthlyBudget;
  final String currency;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.monthlyBudget = 10000000, // Default 10 million VND
    this.currency = 'VND',
    required this.createdAt,
  });

  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? 'Người dùng',
      email: (data['email'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      monthlyBudget: (data['monthlyBudget'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] as String?) ?? 'VND',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'monthlyBudget': monthlyBudget,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    double? monthlyBudget,
    String? currency,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get user initials
  String get initials {
    final names = displayName.split(' ');
    if (names.isEmpty) return '?';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.monthlyBudget == monthlyBudget &&
        other.currency == currency &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        photoUrl.hashCode ^
        monthlyBudget.hashCode ^
        currency.hashCode ^
        createdAt.hashCode;
  }
}
