/// File name: auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    state = _authService.getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    final userCredential = await _authService.signInWithEmail(email, password);
    state = userCredential.user;
  }

  Future<void> register(String email, String password, String name) async {
    final userCredential = await _authService.signUpWithEmail(
      email,
      password,
      name,
    );
    state = userCredential.user;
  }

  Future<void> logout() async {
    await _authService.signOut();
    state = null;
  }
}
