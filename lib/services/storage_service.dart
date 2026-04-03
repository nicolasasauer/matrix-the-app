import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/game_record.dart';

class StorageService {
  static const _historyKey = 'game_history';
  static const _currentGameKey = 'current_game';

  Future<List<GameRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    final records = <GameRecord>[];
    for (final s in raw) {
      try {
        records.add(
            GameRecord.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries
      }
    }
    return records;
  }

  Future<void> saveGame(GameRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_historyKey) ?? [];
    existing.insert(0, jsonEncode(record.toJson()));
    await prefs.setStringList(_historyKey, existing);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> saveCurrentGame(GameRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGameKey, jsonEncode(record.toJson()));
  }

  Future<GameRecord?> loadCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentGameKey);
    if (raw == null) return null;
    try {
      return GameRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGameKey);
  }
}
