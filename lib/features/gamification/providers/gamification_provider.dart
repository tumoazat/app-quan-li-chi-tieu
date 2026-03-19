import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_progress.dart';
import '../services/gamification_service.dart';
import '../../../providers/auth_provider.dart';

/// Provider cho GamificationService
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

/// Provider theo dõi tiến trình người dùng
final userProgressProvider = FutureProvider<UserProgress>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const UserProgress();

  final service = ref.read(gamificationServiceProvider);
  return service.getUserProgress(user.uid);
});
