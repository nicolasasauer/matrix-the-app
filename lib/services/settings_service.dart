import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _animationsKey = 'animations_enabled';
  static const _streakKey = 'streak_multiplier_enabled';
  static const _probabilitiesKey = 'show_probabilities';

  Future<bool> loadAnimationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_animationsKey) ?? true;
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, value);
  }

  Future<bool> loadStreakMultiplierEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_streakKey) ?? false;
  }

  Future<void> setStreakMultiplierEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_streakKey, value);
  }

  Future<bool> loadShowProbabilities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_probabilitiesKey) ?? false;
  }

  Future<void> setShowProbabilities(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_probabilitiesKey, value);
  }
}
