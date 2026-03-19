/// File name: date_formatter.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Date formatting helpers.
class DateFormatter {
  /// Convert DateTime to dd/MM/yyyy format.
  static String toDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
