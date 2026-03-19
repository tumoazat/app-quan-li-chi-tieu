import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state changes provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user).value;
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Sign in with email provider
final signInWithEmailProvider = FutureProvider.autoDispose
    .family<UserCredential, Map<String, String>>((ref, credentials) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.signInWithEmail(
    email: credentials['email']!,
    password: credentials['password']!,
  );
});

// Sign up with email provider
final signUpWithEmailProvider = FutureProvider.autoDispose
    .family<UserCredential, Map<String, String>>((ref, credentials) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.signUpWithEmail(
    email: credentials['email']!,
    password: credentials['password']!,
    displayName: credentials['displayName']!,
  );
});

// Sign in with Google provider
final signInWithGoogleProvider = FutureProvider.autoDispose<UserCredential>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.signInWithGoogle();
});

// Sign out provider
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.signOut();
});

// Reset password provider
final resetPasswordProvider = FutureProvider.autoDispose
    .family<void, String>((ref, email) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.resetPassword(email: email);
});
