import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/animation_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../features/export/application/export_report_usecase.dart';
import 'widgets/settings_section.dart';
import 'account_deletion_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Get transaction count
    final now = DateTime.now();
    final transactionsAsync = ref.watch(
      transactionsStreamProvider('${now.year}-${now.month}'),
    );
    final transactionCount = transactionsAsync.when(
      data: (transactions) => transactions.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Header section with animated avatar
                userProfileAsync.when(
                  data: (userProfile) {
                    final displayName = userProfile?.displayName ?? 
                                       currentUser?.displayName ?? 
                                       'Người dùng';
                    final email = userProfile?.email ?? 
                                 currentUser?.email ?? 
                                 'user@example.com';
                    final photoUrl = userProfile?.photoUrl ?? 
                                    currentUser?.photoURL;

                    return Column(
                      children: [
                        // Animated avatar with ring
                        _AnimatedAvatar(
                          photoUrl: photoUrl,
                          initials: _getInitials(displayName),
                          primaryColor: Theme.of(context).colorScheme.primary,
                        ).animate()
                            .fadeIn(duration: 500.ms)
                            .scaleXY(begin: 0.7, end: 1.0, duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ).animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ).animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms)
                            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: Text(
                          _getInitials(currentUser?.displayName ?? 'U'),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentUser?.displayName ?? 'Người dùng',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        currentUser?.email ?? 'user@example.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Edit profile button
                TextButton.icon(
                  onPressed: () => _showEditProfileDialog(context, ref),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Chỉnh sửa hồ sơ'),
                ).animate()
                    .fadeIn(duration: 300.ms, delay: 400.ms),
                const SizedBox(height: 24),
                // Quick stats row — staggered cards
                Row(
                  children: [
                    Expanded(
                      child: _AnimatedStatCard(
                        icon: Icons.receipt_long,
                        value: transactionCount,
                        label: 'Giao dịch',
                        delay: 400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedStatCard(
                        icon: Icons.local_fire_department,
                        value: '7',
                        label: 'Liên tiếp',
                        delay: 500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: userProfileAsync.when(
                        data: (userProfile) {
                          final budget = userProfile?.monthlyBudget ?? 0;
                          return _AnimatedStatCard(
                            icon: Icons.savings,
                            value: budget > 0 ? '${(budget / 1000000).toStringAsFixed(1)}M' : '0',
                            label: 'Ngân sách',
                            delay: 600,
                          );
                        },
                        loading: () => const _AnimatedStatCard(
                          icon: Icons.savings,
                          value: '...',
                          label: 'Ngân sách',
                          delay: 600,
                        ),
                        error: (_, __) => const _AnimatedStatCard(
                          icon: Icons.savings,
                          value: '0',
                          label: 'Ngân sách',
                          delay: 600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Settings sections — staggered entry
                SettingsSection(
                  title: 'TÙY CHỌN',
                  items: [
                    SettingsItem(
                      leading: Icons.dark_mode,
                      title: 'Chế độ tối',
                      isToggle: true,
                      toggleValue: isDarkMode,
                      onToggle: (value) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                    SettingsItem(
                      leading: Icons.currency_exchange,
                      title: 'Đơn vị tiền tệ',
                      value: 'VNĐ',
                      onTap: () {},
                    ),
                    SettingsItem(
                      leading: Icons.language,
                      title: 'Ngôn ngữ',
                      value: 'Tiếng Việt',
                      onTap: () {},
                    ),
                  ],
                ).fadeInSlideUp(index: 9),
                SettingsSection(
                  title: 'DỮ LIỆU',
                  items: [
                    SettingsItem(
                      leading: Icons.account_balance_wallet,
                      title: 'Ngân sách',
                      onTap: () => _showBudgetDialog(context, ref),
                    ),
                    SettingsItem(
                      leading: Icons.file_download,
                      title: 'Xuất dữ liệu',
                      onTap: () => _exportData(context, ref),
                    ),
                  ],
                ).fadeInSlideUp(index: 11),
                SettingsSection(
                  title: 'VỀ ỨNG DỤNG',
                  items: [
                    SettingsItem(
                      leading: '⭐',
                      title: 'Đánh giá ứng dụng',
                      onTap: () {},
                    ),
                    SettingsItem(
                      leading: '📧',
                      title: 'Liên hệ',
                      onTap: () {},
                    ),
                    SettingsItem(
                      leading: '🔒',
                      title: 'Chính sách bảo mật',
                      onTap: () {},
                    ),
                    SettingsItem(
                      leading: Icons.info,
                      title: 'Phiên bản',
                      value: '1.0.0',
                      onTap: null,
                    ),
                  ],
                ).fadeInSlideUp(index: 13),
                const SizedBox(height: 24),
                // Logout button
                TextButton(
                  onPressed: () => _showLogoutDialog(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Đăng xuất'),
                ).animate()
                    .fadeIn(duration: 400.ms, delay: 1200.ms),
                // Nút xóa tài khoản (màu đỏ, nguy hiểm)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AccountDeletionDialog(),
                    );
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Xóa tài khoản',
                    style: TextStyle(color: Colors.red),
                  ),
                ).animate()
                    .fadeIn(duration: 400.ms, delay: 1300.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final currentUser = ref.read(currentUserProvider);
    final userProfileAsync = ref.read(userProfileProvider);

    // Pre-fill with current data
    userProfileAsync.whenData((userProfile) {
      nameController.text = userProfile?.displayName ?? 
          currentUser?.displayName ?? '';
    });
    if (nameController.text.isEmpty) {
      nameController.text = currentUser?.displayName ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                hintText: currentUser?.email ?? '',
              ),
              controller: TextEditingController(text: currentUser?.email ?? ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && currentUser != null) {
                try {
                  final repo = ref.read(userRepositoryProvider);
                  await repo.updateProfile(currentUser.uid, {
                    'displayName': newName,
                    'email': currentUser.email ?? '',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  // Also update Firebase Auth display name
                  await currentUser.updateDisplayName(newName);
                  // Force refresh user profile
                  ref.invalidate(userProfileProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật hồ sơ'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final userProfileAsync = ref.read(userProfileProvider);
    
    // Pre-fill with current budget
    userProfileAsync.whenData((userProfile) {
      if (userProfile != null && userProfile.monthlyBudget > 0) {
        controller.text = userProfile.monthlyBudget.toStringAsFixed(0);
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt ngân sách'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền',
            suffixText: 'VNĐ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final budget = double.tryParse(controller.text);
              if (budget != null && budget > 0) {
                try {
                  final user = ref.read(currentUserProvider);
                  final repo = ref.read(userRepositoryProvider);
                  await repo.updateBudget(
                    user!.uid, 
                    budget,
                    displayName: user.displayName ?? 'Người dùng',
                    email: user.email ?? '',
                  );
                  // Force refresh user profile
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật ngân sách'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(signOutProvider.future);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final now = DateTime.now();
    try {
      final useCase = ref.read(exportReportUseCaseProvider);
      await useCase.call(userId: user.uid, month: now.month, year: now.year);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AnimatedAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final Color primaryColor;

  const _AnimatedAvatar({
    required this.photoUrl,
    required this.initials,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outer glow ring
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.3),
                primaryColor.withOpacity(0.1),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 2.5),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? Text(initials, style: const TextStyle(fontSize: 32))
                    : null,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.camera_alt,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final int delay;

  const _AnimatedStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay))
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: Duration(milliseconds: delay), curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.85, end: 1.0, duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
