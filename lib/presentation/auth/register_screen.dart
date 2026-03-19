import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:developer' as developer;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_model.dart';
import '../shared/gradient_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/floating_coins.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên hiển thị';
    }
    if (value.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final userCredential = await authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
        );

        final userRepository = ref.read(userRepositoryProvider);
        await userRepository.createUser(userModel);

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e, stackTrace) {
      developer.log('❌ Register error: $e', stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getVietnameseErrorMessage(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getVietnameseErrorMessage(String error) {
    // Exception messages start with "Exception: "
    String msg = error;
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length);
    }
    
    // If already Vietnamese (from auth_repository), return directly
    if (msg.contains('Không tìm thấy') ||
        msg.contains('Mật khẩu') ||
        msg.contains('Email') ||
        msg.contains('tài khoản') ||
        msg.contains('Quá nhiều') ||
        msg.contains('kết nối') ||
        msg.contains('Lỗi') ||
        msg.contains('Phương thức') ||
        msg.contains('đăng nhập')) {
      return msg;
    }
    
    // Fallback for raw Firebase error codes
    if (msg.contains('email-already-in-use')) {
      return 'Email đã được sử dụng';
    } else if (msg.contains('invalid-email')) {
      return 'Email không hợp lệ';
    } else if (msg.contains('weak-password')) {
      return 'Mật khẩu quá yếu';
    } else if (msg.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng';
    } else if (msg.contains('operation-not-allowed')) {
      return 'Phương thức đăng ký chưa được bật. Vào Firebase Console bật Email/Password';
    } else if (msg.contains('channel-error')) {
      return 'Lỗi kênh liên lạc. Vui lòng thử lại';
    } else {
      return 'Lỗi: $msg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          onPressed: _isLoading
              ? null
              : () {
                  context.go('/login');
                },
        ),
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0A1628),
                        const Color(0xFF121212),
                        const Color(0xFF0D1F12),
                      ]
                    : [
                        const Color(0xFFE3F2FD),
                        const Color(0xFFF8F9FA),
                        const Color(0xFFE8F5E9),
                      ],
              ),
            ),
          ),

          // Floating coins
          const Positioned.fill(
            child: FloatingCoins(),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.info.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('✨', style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingBase),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF3498DB), Color(0xFF2ECC71)],
                              ).createShader(bounds),
                              child: Text(
                                'Tạo tài khoản',
                                style: AppTypography.displayMedium(context)
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingSm),
                            Text(
                              'Đăng ký để bắt đầu quản lý chi tiêu',
                              style:
                                  AppTypography.bodyMedium(context).copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),
                        const SizedBox(height: AppConstants.spacing3xl),

                        // Form card
                        Container(
                          padding:
                              const EdgeInsets.all(AppConstants.spacingLg),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusXl,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white.withOpacity(0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              // Name field
                              AuthTextField(
                                controller: _nameController,
                                hintText: 'Tên hiển thị',
                                icon: Icons.person_outline,
                                validator: _validateName,
                                enabled: !_isLoading,
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 200.ms, duration: 350.ms)
                                  .slideX(
                                      begin: -0.08,
                                      end: 0,
                                      duration: 350.ms),
                              const SizedBox(
                                  height: AppConstants.spacingBase),

                              // Email field
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType:
                                    TextInputType.emailAddress,
                                validator: _validateEmail,
                                enabled: !_isLoading,
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 300.ms, duration: 350.ms)
                                  .slideX(
                                      begin: -0.08,
                                      end: 0,
                                      duration: 350.ms),
                              const SizedBox(
                                  height: AppConstants.spacingBase),

                              // Password field
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'Mật khẩu',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                validator: _validatePassword,
                                enabled: !_isLoading,
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 400.ms, duration: 350.ms)
                                  .slideX(
                                      begin: -0.08,
                                      end: 0,
                                      duration: 350.ms),
                              const SizedBox(
                                  height: AppConstants.spacingBase),

                              // Confirm password
                              AuthTextField(
                                controller:
                                    _confirmPasswordController,
                                hintText: 'Xác nhận mật khẩu',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                validator: _validateConfirmPassword,
                                enabled: !_isLoading,
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 500.ms, duration: 350.ms)
                                  .slideX(
                                      begin: -0.08,
                                      end: 0,
                                      duration: 350.ms),
                              const SizedBox(
                                  height: AppConstants.spacingXl),

                              // Register button
                              GradientButton(
                                label: 'Đăng ký',
                                onPressed: _handleRegister,
                                isLoading: _isLoading,
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: 600.ms, duration: 400.ms)
                                  .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      duration: 400.ms),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 500.ms)
                            .scaleXY(
                                begin: 0.96,
                                end: 1,
                                duration: 500.ms),
                        const SizedBox(height: AppConstants.spacingXl),

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đã có tài khoản? ',
                              style: AppTypography.bodyMedium(context),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      context.go('/login');
                                    },
                              child: Text(
                                'Đăng nhập',
                                style: AppTypography.bodyMedium(context)
                                    .copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
