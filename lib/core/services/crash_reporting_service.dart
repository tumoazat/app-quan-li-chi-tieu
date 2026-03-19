import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ báo cáo lỗi sử dụng Firebase Crashlytics
class CrashReportingService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Khởi tạo Crashlytics - ghi lại lỗi Flutter và async errors
  static Future<void> initialize() async {
    // Ghi lại tất cả Flutter errors
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordFlutterFatalError(errorDetails);
    };

    // Ghi lại async errors ngoài Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Ghi lại lỗi tùy chỉnh
  static Future<void> recordError(dynamic error, StackTrace? stack, {String? reason}) async {
    await _crashlytics.recordError(error, stack, reason: reason);
  }

  /// Ghi lại thông điệp log
  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Đặt ID người dùng cho Crashlytics
  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }
}
