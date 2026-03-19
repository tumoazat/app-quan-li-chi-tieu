import 'package:firebase_analytics/firebase_analytics.dart';

/// Dịch vụ theo dõi hành vi người dùng với Firebase Analytics
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Theo dõi màn hình được xem
  static Future<void> trackScreen(String screenName) async {
    await _analytics.setCurrentScreen(screenName: screenName);
  }

  /// Theo dõi sự kiện tùy chỉnh
  static Future<void> trackEvent(String eventName, {Map<String, dynamic>? params}) async {
    await _analytics.logEvent(name: eventName, parameters: params);
  }

  /// Theo dõi đăng nhập
  static Future<void> trackLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Theo dõi đăng ký
  static Future<void> trackSignup(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Theo dõi thêm giao dịch
  static Future<void> trackTransaction(String type, double amount, String category) async {
    await _analytics.logEvent(
      name: 'add_transaction',
      parameters: {
        'type': type,
        'amount': amount,
        'category': category,
      },
    );
  }

  /// Theo dõi sử dụng AI chat
  static Future<void> trackAIChat() async {
    await _analytics.logEvent(name: 'ai_chat_used');
  }

  /// Theo dõi tìm kiếm
  static Future<void> trackSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  /// Đặt ID người dùng
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
