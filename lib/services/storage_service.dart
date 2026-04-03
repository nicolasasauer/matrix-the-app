import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/game_record.dart';

class StorageService {
  static const _historyKey = 'game_history';

  Future<List<GameRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((s) => GameRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
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
}
