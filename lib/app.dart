import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/navigation/main_navigation_screen.dart';

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
