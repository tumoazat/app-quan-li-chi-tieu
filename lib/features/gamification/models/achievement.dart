/// Model cho thành tựu trong hệ thống gamification
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      xpReward: xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Danh sách tất cả thành tựu trong game
  static List<Achievement> get allAchievements => [
        const Achievement(
          id: 'first_step',
          title: 'Bắt đầu!',
          description: 'Đăng ký thành công',
          icon: '🎉',
          xpReward: 10,
        ),
        const Achievement(
          id: 'streak_7',
          title: 'Chăm chỉ',
          description: 'Ghi chép 7 ngày liên tiếp',
          icon: '🔥',
          xpReward: 50,
        ),
        const Achievement(
          id: 'budget_saver',
          title: 'Tiết kiệm giỏi',
          description: 'Chi tiêu dưới 70% ngân sách',
          icon: '💰',
          xpReward: 100,
        ),
        const Achievement(
          id: 'ai_explorer',
          title: 'AI Explorer',
          description: 'Hỏi AI 10 lần',
          icon: '🤖',
          xpReward: 30,
        ),
        const Achievement(
          id: 'super_saver',
          title: 'Siêu tiết kiệm',
          description: 'Tỷ lệ tiết kiệm > 50% trong 1 tháng',
          icon: '⭐',
          xpReward: 200,
        ),
        const Achievement(
          id: 'transaction_10',
          title: 'Ghi chép đều đặn',
          description: 'Thêm 10 giao dịch',
          icon: '📝',
          xpReward: 20,
        ),
        const Achievement(
          id: 'transaction_50',
          title: 'Siêu ghi chép',
          description: 'Thêm 50 giao dịch',
          icon: '📊',
          xpReward: 80,
        ),
      ];
}
