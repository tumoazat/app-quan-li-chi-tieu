import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Show notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Schedule daily reminder at 9 PM
  Future<void> scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule for 9 PM daily
    await _notifications.zonedSchedule(
      0, // notification id
      '💰 Nhắc nhở ghi chép chi tiêu',
      'Bạn đã ghi chép chi tiêu hôm nay chưa? Hãy cập nhật ngay!',
      _nextInstanceOf9PM(),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Get next instance of 9 PM
  tz.TZDateTime _nextInstanceOf9PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Show budget alert
  Future<void> showBudgetAlert({
    required double percentUsed,
    required double totalExpense,
    required double budget,
  }) async {
    String title;
    String body;

    if (percentUsed >= 90) {
      title = '🚨 Cảnh báo ngân sách!';
      body = 'Bạn đã chi ${percentUsed.toStringAsFixed(1)}% ngân sách tháng này!';
    } else if (percentUsed >= 80) {
      title = '⚠️ Chú ý ngân sách';
      body = 'Bạn đã sử dụng ${percentUsed.toStringAsFixed(1)}% ngân sách. Hãy cẩn thận!';
    } else {
      return; // No alert needed
    }

    await showNotification(
      id: 1,
      title: title,
      body: body,
      payload: 'budget_alert',
    );
  }

  // Show saving achievement
  Future<void> showSavingAchievement({
    required String message,
  }) async {
    await showNotification(
      id: 2,
      title: '🎉 Chúc mừng!',
      body: message,
      payload: 'achievement',
    );
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    // This could navigate to specific screens
    final payload = response.payload;
    if (payload != null) {
      // Navigate based on payload
      // You would use GoRouter to navigate here
      // For now, just print
      print('Notification tapped with payload: $payload');
    }
  }
}
