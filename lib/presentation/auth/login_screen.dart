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
import 'widgets/social_login_button.dart';
import 'widgets/floating_coins.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final credential = await authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Ensure user document exists in Firestore
      if (credential.user != null) {
        final userRepo = ref.read(userRepositoryProvider);
        final exists = await userRepo.userExists(credential.user!.uid);
        if (!exists) {
          await userRepo.createUser(UserModel(
            uid: credential.user!.uid,
            displayName: credential.user!.displayName ?? 'Người dùng',
            email: credential.user!.email ?? '',
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Login error: $e', stackTrace: stackTrace);
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final credential = await authRepository.signInWithGoogle();

      // Ensure user document exists in Firestore
      if (credential.user != null) {
        final userRepo = ref.read(userRepositoryProvider);
        final exists = await userRepo.userExists(credential.user!.uid);
        if (!exists) {
          await userRepo.createUser(UserModel(
            uid: credential.user!.uid,
            displayName: credential.user!.displayName ?? 'Người dùng',
            email: credential.user!.email ?? '',
            photoUrl: credential.user!.photoURL,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Google sign-in error: $e', stackTrace: stackTrace);
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
    if (msg.contains('user-not-found')) {
      return 'Không tìm thấy tài khoản';
    } else if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Email hoặc mật khẩu không đúng';
    } else if (msg.contains('invalid-email')) {
      return 'Email không hợp lệ';
    } else if (msg.contains('user-disabled')) {
      return 'Tài khoản đã bị vô hiệu hóa';
    } else if (msg.contains('too-many-requests')) {
      return 'Quá nhiều lần thử. Vui lòng thử lại sau';
    } else if (msg.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng';
    } else if (msg.contains('operation-not-allowed')) {
      return 'Phương thức đăng nhập chưa được bật. Vào Firebase Console bật Email/Password';
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
      body: Stack(
        children: [
          // === GRADIENT BACKGROUND ===
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
                        const Color(0xFFE8F5E9),
                        const Color(0xFFF8F9FA),
                        const Color(0xFFE3F2FD),
                      ],
              ),
            ),
          ),

          // === FLOATING COINS BACKGROUND ===
          const Positioned.fill(
            child: FloatingCoins(),
          ),

          // === MAIN CONTENT ===
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
                        // === LOGO & TITLE (animated) ===
                        Column(
                          children: [
                            // Pulsing glow behind logo
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale = 1.0 + _pulseController.value * 0.08;
                                final glowOpacity = 0.2 + _pulseController.value * 0.15;
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(glowOpacity),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusXl,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '💰',
                                    style: TextStyle(fontSize: 44),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingBase),
                            // Title with gradient text
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.primaryGradient
                                      .createShader(bounds),
                              child: Text(
                                'Smart Expense',
                                style: AppTypography.displayMedium(context)
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingSm),
                            Text(
                              'Quản lý chi tiêu thông minh',
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
                            .fadeIn(
                                duration: 600.ms,
                                curve: Curves.easeOut)
                            .slideY(begin: -0.3, end: 0, duration: 600.ms),
                        const SizedBox(height: AppConstants.spacing3xl),

                        // === FORM CARD (glassmorphism) ===
                        Container(
                          padding: const EdgeInsets.all(AppConstants.spacingLg),
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
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                enabled: !_isLoading,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms, duration: 400.ms)
                                  .slideX(begin: -0.1, end: 0, duration: 400.ms),
                              const SizedBox(height: AppConstants.spacingBase),

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
                                  .fadeIn(delay: 350.ms, duration: 400.ms)
                                  .slideX(begin: -0.1, end: 0, duration: 400.ms),
                              const SizedBox(height: AppConstants.spacingMd),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Tính năng sẽ được cập nhật sớm',
                                              ),
                                            ),
                                          );
                                        },
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: AppTypography.bodyMedium(context)
                                        .copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingBase),

                              // Login button
                              GradientButton(
                                label: 'Đăng nhập',
                                onPressed: _handleLogin,
                                isLoading: _isLoading,
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 400.ms)
                                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 500.ms)
                            .scaleXY(begin: 0.95, end: 1, duration: 500.ms),
                        const SizedBox(height: AppConstants.spacingLg),

                        // === DIVIDER ===
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingBase,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HOẶC',
                                  style: AppTypography.bodySmall(context)
                                      .copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 400.ms),
                        const SizedBox(height: AppConstants.spacingLg),

                        // === GOOGLE SIGN IN ===
                        SocialLoginButton(
                          icon: Icons.g_mobiledata,
                          text: 'Đăng nhập với Google',
                          onPressed:
                              _isLoading ? null : _handleGoogleSignIn,
                          iconColor: const Color(0xFF4285F4),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0, duration: 400.ms),
                        const SizedBox(height: AppConstants.spacingXl),

                        // === REGISTER LINK ===
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chưa có tài khoản? ',
                              style: AppTypography.bodyMedium(context),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      context.go('/register');
                                    },
                              child: Text(
                                'Đăng ký',
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
                            .fadeIn(delay: 800.ms, duration: 400.ms),
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
