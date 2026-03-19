/// Model tiến trình của người dùng trong gamification
class UserProgress {
  final int xp;
  final int level;
  final int streak;
  final DateTime? lastRecordDate;
  final List<String> unlockedAchievementIds;

  const UserProgress({
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastRecordDate,
    this.unlockedAchievementIds = const [],
  });

  /// Tính level dựa trên XP
  static int calculateLevel(int xp) {
    // Công thức: mỗi level cần 100 * level XP
    int level = 1;
    int requiredXp = 100;
    int remainingXp = xp;

    while (remainingXp >= requiredXp) {
      remainingXp -= requiredXp;
      level++;
      requiredXp = 100 * level;
    }
    return level;
  }

  /// XP cần để lên level tiếp theo
  int get xpToNextLevel {
    int totalXpForCurrentLevel = 0;
    for (int i = 1; i < level; i++) {
      totalXpForCurrentLevel += 100 * i;
    }
    return 100 * level - (xp - totalXpForCurrentLevel);
  }

  /// XP trong level hiện tại
  int get xpInCurrentLevel {
    int totalXpForPreviousLevels = 0;
    for (int i = 1; i < level; i++) {
      totalXpForPreviousLevels += 100 * i;
    }
    return xp - totalXpForPreviousLevels;
  }

  /// Tổng XP cần cho level hiện tại
  int get totalXpForCurrentLevel => 100 * level;

  UserProgress copyWith({
    int? xp,
    int? level,
    int? streak,
    DateTime? lastRecordDate,
    List<String>? unlockedAchievementIds,
  }) {
    return UserProgress(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastRecordDate: lastRecordDate ?? this.lastRecordDate,
      unlockedAchievementIds: unlockedAchievementIds ?? this.unlockedAchievementIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'xp': xp,
      'level': level,
      'streak': streak,
      'lastRecordDate': lastRecordDate?.toIso8601String(),
      'unlockedAchievementIds': unlockedAchievementIds,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      lastRecordDate: map['lastRecordDate'] != null
          ? DateTime.tryParse(map['lastRecordDate'] as String)
          : null,
      unlockedAchievementIds: List<String>.from(map['unlockedAchievementIds'] ?? []),
    );
  }
}
