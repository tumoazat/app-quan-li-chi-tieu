extension DateTimeExtensions on DateTime {
  /// Returns true if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns a Vietnamese-formatted date string, e.g. "Hôm nay", "Hôm qua", or "21/02/2026".
  String get formatVN {
    if (isToday) return 'Hôm nay';
    if (isYesterday) return 'Hôm qua';
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return '$d/$m/$year';
  }

  /// Returns "Tháng M, YYYY" format.
  String get monthYearVN => 'Tháng $month, $year';

  /// Returns a key string in "year-month" format used by providers.
  String get monthKey => '$year-$month';
}
