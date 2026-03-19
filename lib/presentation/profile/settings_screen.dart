import 'package:flutter/material.dart';

/// File name: settings_screen.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: User settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SettingsTile(
          icon: Icons.language,
          title: 'Ngôn ngữ',
          subtitle: 'Tiếng Việt',
        ),
        _SettingsTile(
          icon: Icons.notifications,
          title: 'Thông báo',
          subtitle: 'Bật nhắc nhở chi tiêu',
        ),
        _SettingsTile(
          icon: Icons.security,
          title: 'Bảo mật',
          subtitle: 'PIN / Sinh trắc học',
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
