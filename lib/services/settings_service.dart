import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _animationsKey = 'animations_enabled';

  Future<bool> loadAnimationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_animationsKey) ?? true;
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, value);
  }
}
