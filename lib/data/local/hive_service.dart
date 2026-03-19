import 'package:hive_flutter/hive_flutter.dart';

/// Dịch vụ quản lý local storage với Hive
class HiveService {
  static const String transactionBoxName = 'transactions_cache';
  static const String settingsBoxName = 'settings';

  /// Khởi tạo Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    // Mở các box cần thiết
    await Hive.openBox(transactionBoxName);
    await Hive.openBox(settingsBoxName);
  }

  /// Lấy box giao dịch cache
  static Box get transactionBox => Hive.box(transactionBoxName);

  /// Lấy box cài đặt
  static Box get settingsBox => Hive.box(settingsBoxName);
}
