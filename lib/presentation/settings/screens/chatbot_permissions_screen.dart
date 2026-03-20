import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chatbot_permissions_service.dart';
import '../../../core/services/chatbot_permissions_service.dart' show
  ChatbotPermission,
  chatbotPermissionsProvider,
  chatbotFullAccessProvider,
  grantedPermissionsProvider;

class ChatbotPermissionsScreen extends ConsumerWidget {
  const ChatbotPermissionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(chatbotPermissionsProvider);
    final hasFullAccess = ref.watch(chatbotFullAccessProvider);
    final grantedList = ref.watch(grantedPermissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Quyền Truy Cập Chatbot'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với trạng thái
            Container(
              color: hasFullAccess ? Colors.green[50] : Colors.orange[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasFullAccess ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFullAccess ? Icons.lock_open : Icons.lock,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasFullAccess ? '✅ TOÀN QUYỀN' : '⚠️ CẬP HẠN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: hasFullAccess ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFullAccess
                        ? 'Chatbot có toàn quyền truy cập tất cả dữ liệu tài chính'
                        : 'Chatbot chỉ có quyền hạn chế',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${grantedList.length}/${ChatbotPermission.values.length} quyền được cấp',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),

            // Nút toggle full access
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        permissions.grantFullAccess();
                        // ignore: unused_result
                        ref.refresh(chatbotFullAccessProvider);
                        // ignore: unused_result
                        ref.refresh(grantedPermissionsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Đã cấp TOÀN QUYỀN cho chatbot'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Cấp Toàn Quyền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        permissions.revokeAllAccess();
                        // ignore: unused_result
                        ref.refresh(chatbotFullAccessProvider);
                        // ignore: unused_result
                        ref.refresh(grantedPermissionsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Đã thu hồi tất cả quyền'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.lock),
                      label: const Text('Thu Hồi'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 2, height: 24),

            // Danh sách các quyền
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Chi Tiết Quyền Truy Cập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    MapEntry('Giao Dịch', [
                      ChatbotPermission.viewAllTransactions,
                      ChatbotPermission.viewTransactionDetails,
                      ChatbotPermission.viewTransactionHistory,
                      ChatbotPermission.viewTransactionNotes,
                    ]),
                    MapEntry('Ngân Sách', [
                      ChatbotPermission.viewBudgetInfo,
                      ChatbotPermission.viewBudgetLimits,
                    ]),
                    MapEntry('Danh Mục', [
                      ChatbotPermission.viewCategoryBreakdown,
                      ChatbotPermission.viewCategoryTrends,
                    ]),
                    MapEntry('Phân Tích', [
                      ChatbotPermission.performFinancialAnalysis,
                      ChatbotPermission.generateForecasts,
                      ChatbotPermission.provideSavingRecommendations,
                    ]),
                    MapEntry('Hồ Sơ', [
                      ChatbotPermission.viewUserProfile,
                      ChatbotPermission.viewUserPreferences,
                    ]),
                  ].map((group) {
                    final groupName = group.key;
                    final groupPermissions = group.value;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...groupPermissions.map((perm) {
                            final isGranted = grantedList.contains(perm);
                            return _PermissionTile(
                              permission: perm,
                              isGranted: isGranted,
                              onToggle: () {
                                if (isGranted) {
                                  permissions.revokePermission(perm);
                                } else {
                                  permissions.grantPermission(perm);
                                }
                                // ignore: unused_result
                                ref.refresh(chatbotFullAccessProvider);
                                // ignore: unused_result
                                ref.refresh(grantedPermissionsProvider);
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Footer info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Thông Tin',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khi chatbot có TOÀN QUYỀN, nó sẽ:\n'
                    '✓ Xem tất cả giao dịch của bạn\n'
                    '✓ Phân tích chi tiêu chi tiết\n'
                    '✓ Tạo dự báo chính xác\n'
                    '✓ Gợi ý tiết kiệm tối ưu\n'
                    '✓ Đưa ra lời khuyên tài chính toàn diện',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends ConsumerWidget {
  final ChatbotPermission permission;
  final bool isGranted;
  final VoidCallback onToggle;

  const _PermissionTile({
    Key? key,
    required this.permission,
    required this.isGranted,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permService = ref.read(chatbotPermissionsProvider);
    final description = permService.getPermissionDescription(permission);
    final emoji = permService.getPermissionEmoji(permission);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green[50] : Colors.grey[100],
        border: Border.all(
          color: isGranted ? Colors.green[300]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        title: Text(
          description,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isGranted ? Colors.green[900] : Colors.grey[700],
          ),
        ),
        trailing: Switch(
          value: isGranted,
          onChanged: (_) => onToggle(),
          activeColor: Colors.green,
        ),
        onTap: onToggle,
      ),
    );
  }
}
