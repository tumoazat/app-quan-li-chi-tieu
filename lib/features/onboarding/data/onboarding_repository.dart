import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed onboarding.
class OnboardingRepository {
  static const String _key = 'onboarding_complete';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
