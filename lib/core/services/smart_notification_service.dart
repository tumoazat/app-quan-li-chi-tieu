import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class SmartNotificationService {
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();

  factory SmartNotificationService() {
    return _instance;
  }

  SmartNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Morning reminder notification
  Future<void> scheduleMorningReminder() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Good Morning! 🌅',
      'How much did you spend today?',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_expense_channel',
          'Smart Expense Notifications',
          channelDescription: 'Notifications for Smart Expense app',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Budget alert notification
  Future<void> showBudgetAlert({
    required String categoryName,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    final message = percentage > 100
        ? 'You exceeded budget for $categoryName by ${(percentage - 100).toStringAsFixed(0)}%'
        : 'You spent ${percentage.toStringAsFixed(0)}% of $categoryName budget';

    await _notificationsPlugin.show(
      1,
      '⚠️ Budget Alert',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Alerts when spending exceeds budget',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF6B6B),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Weekly spending summary
  Future<void> showWeeklySummary({
    required double totalSpent,
    required String topCategory,
    required double topCategoryAmount,
    required double changePercentage,
  }) async {
    final changeText = changePercentage > 0 ? '↑' : '↓';
    final message =
        'Total: ${totalSpent.toStringAsFixed(0)}đ | Top: $topCategory | Change: $changeText${changePercentage.abs().toStringAsFixed(1)}%';

    await _notificationsPlugin.show(
      2,
      '📊 Weekly Summary',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reports',
          'Weekly Reports',
          channelDescription: 'Weekly spending summaries',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF4ECDC4),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Spending insight notification
  Future<void> showInsight({
    required String title,
    required String message,
  }) async {
    await _notificationsPlugin.show(
      3,
      '💡 $title',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'insights',
          'Spending Insights',
          channelDescription: 'Smart spending insights',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFFA8E6CF),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
