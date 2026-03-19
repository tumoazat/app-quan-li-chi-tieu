import 'package:flutter/material.dart';

import 'settings_screen.dart';

/// File name: profile_screen.dart
/// Author: Lê Duy Khánh
/// Created: 2026-03-19
/// Description: User profile and settings overview.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: Column(
        children: const [
          _ProfileHeader(),
          Expanded(child: SettingsScreen()),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
          title: const Text('Lê Duy Khánh'),
          subtitle: const Text('UI/UX & Profile Owner'),
          trailing: TextButton(onPressed: () {}, child: const Text('Sửa')),
        ),
      ),
    );
  }
}
