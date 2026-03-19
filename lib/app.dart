import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

class SmartExpenseApp extends ConsumerWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);
    
    // Watch auth state
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        print('🟢 App: User = ${user?.email ?? 'null'}');
        
        final router = AppRouter.createRouter(
          isAuthenticated: user != null,
        );

        return MaterialApp.router(
          title: 'Smart Expense',
          debugShowCheckedModeBanner: false,
          
          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          
          // Router configuration
          routerConfig: router,
        );
      },
      loading: () {
        // Show loading screen while checking auth state
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '💰',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Smart Expense',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, stack) {
        // Show error screen
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đã xảy ra lỗi',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
