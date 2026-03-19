/// File name: user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/user_model.dart';
import 'auth_provider.dart';

final userProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authProvider);

  if (user == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;

  return UserModel.fromMap(doc.data()!, doc.id);
});
