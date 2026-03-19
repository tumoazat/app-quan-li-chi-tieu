/// File name: currency_formatter.dart
/// Author: Nguyễn Văn An
/// Created: 2026-03-20
/// Description: Utilities for formatting currency and numbers
///
/// Responsibilities:
/// - Format numbers as VND currency
/// - Format dates
/// - Format time

import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format số tiền thành VNĐ (1.500.000đ)
  static String format(double value) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    return '${formatter.format(value.abs())}đ';
  }

  /// Format ngắn gọn (1.5tr, 500k)
  static String formatCompact(double value) {
    final absValue = value.abs();

    if (absValue >= 1e6) {
      return '${(absValue / 1e6).toStringAsFixed(1)}tr';
    } else if (absValue >= 1e3) {
      return '${(absValue / 1e3).toStringAsFixed(0)}k';
    }
    return absValue.toStringAsFixed(0);
  }

  /// Format với dấu +/- (Thu nhập: +1.500.000đ, Chi tiêu: -500.000đ)
  static String formatWithSign(double value, {bool showCurrency = true}) {
    final formatted = format(value);
    final sign = value >= 0 ? '+' : '-';
    return '$sign${formatted.replaceFirst(RegExp(r'^[+-]'), '')}';
  }

  /// Format ngày (20/03/2026)
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'vi_VN');
    return formatter.format(date);
  }

  /// Format ngày chi tiết (Thứ ba, 20 tháng 3 năm 2026)
  static String formatDateFull(DateTime date) {
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'vi_VN');
    return formatter.format(date);
  }

  /// Format tháng (Tháng 3, 2026)
  static String formatMonth(DateTime date) {
    final formatter = DateFormat('MMMM yyyy', 'vi_VN');
    return formatter.format(date);
  }

  /// Format giờ (14:30)
  static String formatTime(DateTime date) {
    final formatter = DateFormat('HH:mm', 'vi_VN');
    return formatter.format(date);
  }

  /// Format ngày giờ (20/03/2026 14:30)
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  /// Tính số ngày trước đó humanize (2 ngày trước, Hôm qua)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua';
    }

    final difference = today.difference(dateOnly).inDays;
    if (difference < 7) {
      return '$difference ngày trước';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks tuần trước';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months tháng trước';
    } else {
      return formatDate(date);
    }
  }
}
