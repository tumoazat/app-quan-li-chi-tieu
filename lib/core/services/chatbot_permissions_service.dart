import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum để định nghĩa các quyền truy cập của chatbot
enum ChatbotPermission {
  // Dữ liệu giao dịch
  viewAllTransactions,
  viewTransactionDetails,
  viewTransactionHistory,
  viewTransactionNotes,
  
  // Dữ liệu ngân sách
  viewBudgetInfo,
  viewBudgetLimits,
  
  // Dữ liệu danh mục
  viewCategoryBreakdown,
  viewCategoryTrends,
  
  // Phân tích nâng cao
  performFinancialAnalysis,
  generateForecasts,
  provideSavingRecommendations,
  
  // Dữ liệu người dùng
  viewUserProfile,
  viewUserPreferences,
}

/// Lớp quản lý các quyền của chatbot
class ChatbotPermissionsService {
  // Tất cả quyền mặc định được kích hoạt (FULL ACCESS)
  static const allPermissions = ChatbotPermission.values;
  
  // Quyền được cấp cho chatbot hiện tại
  static final Set<ChatbotPermission> _grantedPermissions = 
    Set<ChatbotPermission>.from(allPermissions);

  /// Kiểm tra chatbot có quyền không
  bool hasPermission(ChatbotPermission permission) {
    return _grantedPermissions.contains(permission);
  }

  /// Cấp quyền cho chatbot
  void grantPermission(ChatbotPermission permission) {
    _grantedPermissions.add(permission);
  }

  /// Thu hồi quyền từ chatbot
  void revokePermission(ChatbotPermission permission) {
    _grantedPermissions.remove(permission);
  }

  /// Cấp tất cả quyền (FULL ACCESS)
  void grantFullAccess() {
    _grantedPermissions.clear();
    _grantedPermissions.addAll(allPermissions);
  }

  /// Thu hồi tất cả quyền (NO ACCESS)
  void revokeAllAccess() {
    _grantedPermissions.clear();
  }

  /// Lấy danh sách các quyền được cấp
  List<ChatbotPermission> getGrantedPermissions() {
    return _grantedPermissions.toList();
  }

  /// Lấy danh sách các quyền bị từ chối
  List<ChatbotPermission> getDeniedPermissions() {
    return allPermissions
        .where((p) => !_grantedPermissions.contains(p))
        .toList();
  }

  /// Kiểm tra có FULL ACCESS không
  bool hasFullAccess() {
    return _grantedPermissions.length == allPermissions.length;
  }

  /// Lấy mô tả text cho quyền
  String getPermissionDescription(ChatbotPermission permission) {
    switch (permission) {
      case ChatbotPermission.viewAllTransactions:
        return 'Xem tất cả giao dịch';
      case ChatbotPermission.viewTransactionDetails:
        return 'Xem chi tiết giao dịch';
      case ChatbotPermission.viewTransactionHistory:
        return 'Xem lịch sử giao dịch';
      case ChatbotPermission.viewTransactionNotes:
        return 'Xem ghi chú giao dịch';
      case ChatbotPermission.viewBudgetInfo:
        return 'Xem thông tin ngân sách';
      case ChatbotPermission.viewBudgetLimits:
        return 'Xem giới hạn ngân sách';
      case ChatbotPermission.viewCategoryBreakdown:
        return 'Xem chi tiêu theo danh mục';
      case ChatbotPermission.viewCategoryTrends:
        return 'Xem xu hướng danh mục';
      case ChatbotPermission.performFinancialAnalysis:
        return 'Phân tích tài chính';
      case ChatbotPermission.generateForecasts:
        return 'Dự báo tài chính';
      case ChatbotPermission.provideSavingRecommendations:
        return 'Gợi ý tiết kiệm';
      case ChatbotPermission.viewUserProfile:
        return 'Xem hồ sơ người dùng';
      case ChatbotPermission.viewUserPreferences:
        return 'Xem tùy chọn người dùng';
    }
  }

  /// Lấy icon emoji cho quyền
  String getPermissionEmoji(ChatbotPermission permission) {
    switch (permission) {
      case ChatbotPermission.viewAllTransactions:
      case ChatbotPermission.viewTransactionDetails:
      case ChatbotPermission.viewTransactionHistory:
        return '📋';
      case ChatbotPermission.viewTransactionNotes:
        return '📝';
      case ChatbotPermission.viewBudgetInfo:
      case ChatbotPermission.viewBudgetLimits:
        return '💰';
      case ChatbotPermission.viewCategoryBreakdown:
      case ChatbotPermission.viewCategoryTrends:
        return '📊';
      case ChatbotPermission.performFinancialAnalysis:
        return '📈';
      case ChatbotPermission.generateForecasts:
        return '🔮';
      case ChatbotPermission.provideSavingRecommendations:
        return '💡';
      case ChatbotPermission.viewUserProfile:
        return '👤';
      case ChatbotPermission.viewUserPreferences:
        return '⚙️';
    }
  }
}

/// Provider cho dịch vụ quyền chatbot
final chatbotPermissionsProvider = Provider<ChatbotPermissionsService>((ref) {
  final service = ChatbotPermissionsService();
  // Mặc định cấp FULL ACCESS
  service.grantFullAccess();
  return service;
});

/// Provider cho trạng thái full access
final chatbotFullAccessProvider = Provider<bool>((ref) {
  final permissions = ref.read(chatbotPermissionsProvider);
  return permissions.hasFullAccess();
});

/// Provider cho danh sách quyền được cấp
final grantedPermissionsProvider = Provider<List<ChatbotPermission>>((ref) {
  final permissions = ref.read(chatbotPermissionsProvider);
  return permissions.getGrantedPermissions();
});
