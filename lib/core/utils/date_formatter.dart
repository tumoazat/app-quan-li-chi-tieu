import 'package:intl/intl.dart';

class DateFormatter {
  // Vietnamese date formatting
  static String formatVietnamese(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Hôm nay';
    } else if (compareDate == yesterday) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // Format with time
  static String formatWithTime(DateTime date) {
    final dateStr = formatVietnamese(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr, $timeStr';
  }

  // Format for transaction grouping
  static String formatTransactionGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Hôm nay';
    } else if (compareDate == yesterday) {
      return 'Hôm qua';
    } else if (date.year == now.year) {
      return DateFormat('dd/MM').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // Format month/year for selector
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'vi_VN').format(date);
  }

  // Format short month/year (e.g., "Tháng 2, 2026")
  static String formatShortMonthYear(DateTime date) {
    return 'Tháng ${date.month}, ${date.year}';
  }

  // Format for statistics
  static String formatStatsHeader(DateTime date) {
    return DateFormat('MMMM yyyy', 'vi_VN').format(date);
  }

  // Get day name in Vietnamese
  static String getDayName(DateTime date) {
    const dayNames = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    return dayNames[date.weekday % 7];
  }

  // Format relative time (e.g., "2 giờ trước", "3 ngày trước")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Get start of month
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  // Get start of week
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  // Get end of week
  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }
}
