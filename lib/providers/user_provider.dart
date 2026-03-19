import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import 'auth_provider.dart';

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// User profile stream provider
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(userRepositoryProvider);
  
  // Auto-create Firestore doc if it doesn't exist
  repository.userExists(user.uid).then((exists) async {
    if (!exists) {
      await repository.createUser(UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Người dùng',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      ));
    }
  });

  ref.keepAlive();
  return repository.getUser(user.uid);
});

// User profile once provider (for one-time fetch)
final userProfileOnceProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return null;
  }

  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserOnce(user.uid);
});

// Update budget provider
final updateBudgetProvider = FutureProvider.autoDispose
    .family<void, double>((ref, budget) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(userRepositoryProvider);
  return repository.updateBudget(user.uid, budget);
});

// Update profile provider
final updateProfileProvider = FutureProvider.autoDispose
    .family<void, Map<String, dynamic>>((ref, data) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(userRepositoryProvider);
  return repository.updateProfile(user.uid, data);
});

// Create user provider (for first-time setup)
final createUserProvider = FutureProvider.autoDispose
    .family<void, UserModel>((ref, userModel) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.createUser(userModel);
});

// Monthly budget provider (convenience)
final monthlyBudgetProvider = Provider.autoDispose<double>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  
  return userProfile.when(
    data: (user) => user?.monthlyBudget ?? 10000000,
    loading: () => 10000000,
    error: (_, __) => 10000000,
  );
});

// User display name provider
final userDisplayNameProvider = Provider.autoDispose<String>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  
  return userProfile.when(
    data: (user) => user?.displayName ?? 'User',
    loading: () => 'Loading...',
    error: (_, __) => 'User',
  );
});

// User initials provider
final userInitialsProvider = Provider.autoDispose<String>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  
  return userProfile.when(
    data: (user) => user?.initials ?? '?',
    loading: () => '?',
    error: (_, __) => '?',
  );
});
