import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get user stream
  Stream<UserModel?> getUser(String uid) {
    try {
      return _usersCollection.doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get user once
  Future<UserModel?> getUserOnce(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update budget
  Future<void> updateBudget(String uid, double budget, {String? displayName, String? email}) async {
    try {
      final data = <String, dynamic>{
        'monthlyBudget': budget,
      };
      // Also save basic info to ensure doc has required fields
      if (displayName != null) data['displayName'] = displayName;
      if (email != null) data['email'] = email;
      
      await _usersCollection.doc(uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  // Update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update photo URL
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    try {
      await _usersCollection.doc(uid).set(
        {'photoUrl': photoUrl},
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update photo URL: $e');
    }
  }

  // Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _usersCollection.doc(uid).update({'displayName': displayName});
    } catch (e) {
      throw Exception('Failed to update display name: $e');
    }
  }

  // Delete user data
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document
      await _usersCollection.doc(uid).delete();
      
      // Delete all transactions (subcollection)
      final transactionsSnapshot = await _usersCollection
          .doc(uid)
          .collection('transactions')
          .get();
      
      for (var doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if user exists: $e');
    }
  }
}
