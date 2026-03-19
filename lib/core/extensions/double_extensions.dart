import 'package:intl/intl.dart';

extension DoubleExtensions on double {
  /// Formats as Vietnamese Dong, e.g. "1.500.000 ₫".
  String get toVND {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  /// Compact format: 1.5M, 500K, etc.
  String get toCompact {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}K';
    }
    return toStringAsFixed(0);
  }
}
