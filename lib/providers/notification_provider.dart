import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../core/utils/currency_formatter.dart';

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]);

  void addIncomeNotification(double amount, String categoryName) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Thu nhập mới',
      message:
          'Bạn vừa nhận ${CurrencyFormatter.formatVND(amount)} từ $categoryName',
      createdAt: DateTime.now(),
      type: NotificationType.income,
    );
    state = [notification, ...state];
  }

  void addExpenseNotification(double amount, String categoryName) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Chi tiêu mới',
      message:
          'Bạn vừa chi ${CurrencyFormatter.formatVND(amount)} cho $categoryName',
      createdAt: DateTime.now(),
      type: NotificationType.expense,
    );
    state = [notification, ...state];
  }

  void addBudgetWarningNotification(double spent, double budget) {
    final percentage = (spent / budget * 100).toStringAsFixed(0);
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Cảnh báo ngân sách',
      message:
          'Bạn đã chi $percentage% ngân sách tháng này (${CurrencyFormatter.formatVND(spent)}/${CurrencyFormatter.formatVND(budget)})',
      createdAt: DateTime.now(),
      type: NotificationType.budget,
    );
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

// Notification provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});

// Unread notification count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
