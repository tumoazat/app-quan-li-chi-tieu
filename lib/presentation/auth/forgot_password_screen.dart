import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final emailController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quên mật khẩu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Nhập email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _authService.resetPassword(emailController.text);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã gửi email reset mật khẩu")),
                );
              },
              child: const Text("Gửi yêu cầu"),
            ),
          ],
        ),
      ),
    );
  }
}
