import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement.dart';
import '../models/user_progress.dart';

/// Dịch vụ quản lý gamification: tính điểm, cập nhật streak, mở khóa thành tựu
class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _gamificationCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('gamification');

  /// Lấy tiến trình người dùng
  Future<UserProgress> getUserProgress(String userId) async {
    try {
      final doc = await _gamificationCollection(userId).doc('progress').get();
      if (!doc.exists) return const UserProgress();
      return UserProgress.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) {
      return const UserProgress();
    }
  }

  /// Lưu tiến trình người dùng
  Future<void> saveUserProgress(String userId, UserProgress progress) async {
    await _gamificationCollection(userId).doc('progress').set(progress.toMap());
  }

  /// Thêm XP cho người dùng
  Future<UserProgress> addXp(String userId, int xpAmount) async {
    final progress = await getUserProgress(userId);
    final newXp = progress.xp + xpAmount;
    final newLevel = UserProgress.calculateLevel(newXp);
    final newProgress = progress.copyWith(xp: newXp, level: newLevel);
    await saveUserProgress(userId, newProgress);
    return newProgress;
  }

  /// Cập nhật streak khi ghi giao dịch
  Future<UserProgress> updateStreak(String userId) async {
    final progress = await getUserProgress(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = progress.streak;
    if (progress.lastRecordDate == null) {
      newStreak = 1;
    } else {
      final lastDate = DateTime(
        progress.lastRecordDate!.year,
        progress.lastRecordDate!.month,
        progress.lastRecordDate!.day,
      );
      final diff = today.difference(lastDate).inDays;

      if (diff == 1) {
        // Ghi liên tiếp ngày hôm nay → tăng streak
        newStreak = progress.streak + 1;
      } else if (diff == 0) {
        // Đã ghi hôm nay rồi, không thay đổi
        return progress;
      } else {
        // Bị đứt streak → reset
        newStreak = 1;
      }
    }

    final newProgress = progress.copyWith(
      streak: newStreak,
      lastRecordDate: now,
    );
    await saveUserProgress(userId, newProgress);
    return newProgress;
  }

  /// Kiểm tra và mở khóa thành tựu dựa trên tiến trình hiện tại
  Future<List<Achievement>> checkAndUnlockAchievements(
    String userId,
    UserProgress progress, {
    int? transactionCount,
    int? aiChatCount,
    double? savingsRate,
  }) async {
    final newlyUnlocked = <Achievement>[];

    for (final achievement in Achievement.allAchievements) {
      if (progress.unlockedAchievementIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_step':
          shouldUnlock = true; // Mở khóa ngay khi có progress
          break;
        case 'streak_7':
          shouldUnlock = progress.streak >= 7;
          break;
        case 'ai_explorer':
          shouldUnlock = (aiChatCount ?? 0) >= 10;
          break;
        case 'transaction_10':
          shouldUnlock = (transactionCount ?? 0) >= 10;
          break;
        case 'transaction_50':
          shouldUnlock = (transactionCount ?? 0) >= 50;
          break;
        case 'super_saver':
          shouldUnlock = (savingsRate ?? 0) >= 0.5;
          break;
        case 'budget_saver':
          shouldUnlock = (savingsRate ?? 0) >= 0.3;
          break;
      }

      if (shouldUnlock) {
        newlyUnlocked.add(achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));
        // Thêm XP cho người dùng
        await addXp(userId, achievement.xpReward);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      // Cập nhật danh sách thành tựu đã mở khóa
      final updatedProgress = await getUserProgress(userId);
      final updatedIds = [
        ...updatedProgress.unlockedAchievementIds,
        ...newlyUnlocked.map((a) => a.id),
      ];
      await saveUserProgress(
        userId,
        updatedProgress.copyWith(unlockedAchievementIds: updatedIds),
      );
    }

    return newlyUnlocked;
  }
}
