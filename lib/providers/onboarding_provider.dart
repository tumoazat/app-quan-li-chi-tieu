import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached onboarding state - read once on app startup and cache
final onboardingStateProvider = StateProvider<bool?>((ref) {
  // Initially null, will be set by initializeApp
  return null;
});

/// Initialize onboarding state from SharedPreferences
Future<bool> initializeOnboardingState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  } catch (e) {
    print('Error reading onboarding state: $e');
    return false;
  }
}
