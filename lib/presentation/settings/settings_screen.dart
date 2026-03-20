import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../core/l10n/locale_provider.dart';
import '../profile/account_deletion_dialog.dart';
import '../../providers/auth_provider.dart';

/// Màn hình Cài đặt đầy đủ
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _budgetRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _budgetRemindersEnabled = prefs.getBool('budget_reminders_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          // === GIAO DIỆN ===
          _buildSectionHeader('🎨 Giao diện'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Chủ đề'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Hệ thống')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  // Sử dụng setThemeMode thay vì setTheme
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            trailing: DropdownButton<Locale>(
              value: locale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: Locale('vi'), child: Text('Tiếng Việt')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
              onChanged: (loc) {
                if (loc != null) {
                  ref.read(localeProvider.notifier).setLocale(loc);
                }
              },
            ),
          ),
          const Divider(),

          // === THÔNG BÁO ===
          _buildSectionHeader('🔔 Thông báo'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Thông báo đẩy'),
            subtitle: const Text('Nhận thông báo từ ứng dụng'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications_enabled', value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.account_balance_wallet),
            title: const Text('Nhắc nhở ngân sách'),
            subtitle: const Text('Cảnh báo khi gần vượt ngân sách'),
            value: _budgetRemindersEnabled,
            onChanged: (value) {
              setState(() => _budgetRemindersEnabled = value);
              _saveSetting('budget_reminders_enabled', value);
            },
          ),
          const Divider(),

          // === BẢO MẬT ===
          _buildSectionHeader('🔒 Bảo mật'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Xác thực sinh trắc học'),
            subtitle: const Text('Sắp ra mắt'),
            enabled: false,
            trailing: const Chip(label: Text('Soon')),
          ),
          const Divider(),

          // === DỮ LIỆU ===
          _buildSectionHeader('💾 Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Xóa cache'),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Xuất dữ liệu'),
            subtitle: const Text('Xuất báo cáo PDF'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Vui lòng sử dụng tính năng xuất báo cáo trong màn hình thống kê',
                ),
              ),
            ),
          ),
          const Divider(),

          // === THÔNG TIN ===
          _buildSectionHeader('ℹ️ Thông tin'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Phiên bản'),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Chính sách bảo mật'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Điều khoản sử dụng'),
            onTap: () {},
          ),
          const Divider(),

          // === TÀI KHOẢN ===
          _buildSectionHeader('👤 Tài khoản'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            // Sử dụng signOutProvider thay vì authStateProvider.notifier.signOut
            onTap: () => ref.read(signOutProvider.future),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Xóa tất cả dữ liệu và tài khoản'),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const AccountDeletionDialog(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Xóa cache (giữ lại settings cơ bản)
    await prefs.remove('transactions_cache');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cache thành công')),
      );
    }
  }
}
