import 'package:intl/intl.dart';

/// File name: currency_formatter.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: Currency formatting utility for Vietnamese locale.
class CurrencyFormatter {
  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'vi_VN');

  /// Format numeric amount to standard Vietnamese currency.
  static String format(double value) {
    return '${_numberFormat.format(value)}đ';
  }

  /// Format amount in compact unit for large values.
  static String formatCompact(double value) {
    if (value >= 1000000) {
      final millionValue = value / 1000000;
      return '${millionValue.toStringAsFixed(1)}tr';
    }

    return format(value);
  }
}
