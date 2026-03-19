import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme mode state notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  // Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // If there's an error, keep the default system theme
      state = ThemeMode.system;
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  // Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // Set light theme
  Future<void> setLight() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set dark theme
  Future<void> setDark() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Set system theme
  Future<void> setSystem() async {
    await setThemeMode(ThemeMode.system);
  }

  // Check if dark mode
  bool get isDark => state == ThemeMode.dark;

  // Check if light mode
  bool get isLight => state == ThemeMode.light;

  // Check if system mode
  bool get isSystem => state == ThemeMode.system;
}

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Is dark mode provider (convenience)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  if (themeMode == ThemeMode.dark) {
    return true;
  } else if (themeMode == ThemeMode.light) {
    return false;
  }
  
  // System mode - check platform brightness
  // This would need to be implemented with MediaQuery in the UI
  return false;
});
