import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement.dart';
import '../providers/gamification_provider.dart';
import '../widgets/level_progress_widget.dart';

/// Màn hình hiển thị tất cả thành tựu
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Thành tựu')),
      body: progressAsync.when(
        data: (progress) {
          // Đánh dấu thành tựu nào đã mở khóa
          final achievements = Achievement.allAchievements.map((a) {
            return a.copyWith(
              isUnlocked: progress.unlockedAchievementIds.contains(a.id),
            );
          }).toList();

          return CustomScrollView(
            slivers: [
              // Thanh XP progress ở đầu màn hình
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: const LevelProgressWidget(),
                    ),
                  ),
                ),
              ),

              // Tiêu đề số thành tựu đã mở khóa
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${progress.unlockedAchievementIds.length}/${achievements.length} thành tựu đã mở khóa',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              // Lưới thành tựu
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _AchievementCard(achievement: achievements[index]);
                    },
                    childCount: achievements.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Card(
      elevation: isUnlocked ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon thành tựu, mờ nếu chưa mở khóa
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 40,
                    color: isUnlocked ? null : Colors.grey.withOpacity(0.3),
                  ),
                ),
                if (!isUnlocked)
                  const Icon(Icons.lock, color: Colors.grey, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Badge XP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: TextStyle(
                  fontSize: 12,
                  color: isUnlocked ? Colors.amber : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
