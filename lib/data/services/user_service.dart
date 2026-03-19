/// File name: user_service.dart
/// Description: Quản lý user profile & budget

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy thông tin user
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Không thể lấy thông tin user');
    }
  }

  /// Cập nhật budget
  Future<void> updateBudget(String uid, double budget) async {
    try {
      await _firestore.collection('users').doc(uid).update({'budget': budget});
    } catch (e) {
      throw Exception('Cập nhật budget thất bại');
    }
  }

  /// Update profile
  Future<void> updateProfile(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).update({'name': name});
    } catch (e) {
      throw Exception('Cập nhật profile thất bại');
    }
  }
}
