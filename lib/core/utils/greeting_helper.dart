class GreetingHelper {
  // Get time-based greeting in Vietnamese
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'Chào buổi sáng ☀️';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều 🌤️';
    } else if (hour >= 18 && hour < 22) {
      return 'Chào buổi tối 🌆';
    } else {
      return 'Chúc ngủ ngon 🌙';
    }
  }

  // Get motivational message based on time
  static String getMotivationalMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return 'Hãy bắt đầu một ngày mới tuyệt vời!';
    } else if (hour >= 12 && hour < 18) {
      return 'Tiếp tục phát huy nhé!';
    } else if (hour >= 18 && hour < 22) {
      return 'Bạn đã làm việc chăm chỉ cả ngày!';
    } else {
      return 'Nghỉ ngơi thật tốt để ngày mai năng động hơn!';
    }
  }

  // Get financial tip based on day of week
  static String getFinancialTip() {
    final dayOfWeek = DateTime.now().weekday;

    switch (dayOfWeek) {
      case 1: // Monday
        return '💡 Mẹo: Lập kế hoạch chi tiêu cho tuần này';
      case 2: // Tuesday
        return '💡 Mẹo: Ghi chép mọi khoản chi tiêu, dù nhỏ';
      case 3: // Wednesday
        return '💡 Mẹo: Kiểm tra xem bạn đã chi bao nhiêu rồi';
      case 4: // Thursday
        return '💡 Mẹo: Hạn chế mua sắm không cần thiết';
      case 5: // Friday
        return '💡 Mẹo: Cuối tuần đến rồi, hãy chi tiêu có ý thức';
      case 6: // Saturday
        return '💡 Mẹo: Tận hưởng cuối tuần không tốn kém';
      case 7: // Sunday
        return '💡 Mẹo: Chuẩn bị cho tuần mới tích cực';
      default:
        return '💡 Mẹo: Quản lý tài chính thông minh mỗi ngày';
    }
  }

  // Get greeting with user name
  static String getGreetingWithName(String name) {
    final greeting = getGreeting();
    return '$greeting, $name';
  }
}
