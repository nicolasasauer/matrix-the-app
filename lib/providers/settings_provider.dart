import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;

  bool _animationsEnabled = true;
  bool _streakMultiplierEnabled = false;

  SettingsProvider(this._service);

  bool get animationsEnabled => _animationsEnabled;

  /// Optional house rule: every turn that is passed on without a mistake
  /// raises the multiplier by one (2x, 3x, 4x, ...) until someone fails.
  bool get streakMultiplierEnabled => _streakMultiplierEnabled;

  Future<void> load() async {
    _animationsEnabled = await _service.loadAnimationsEnabled();
    _streakMultiplierEnabled = await _service.loadStreakMultiplierEnabled();
    notifyListeners();
  }

  void setAnimationsEnabled(bool value) {
    _animationsEnabled = value;
    notifyListeners();
    unawaited(_service.setAnimationsEnabled(value).catchError((_) {}));
  }

  void setStreakMultiplierEnabled(bool value) {
    _streakMultiplierEnabled = value;
    notifyListeners();
    unawaited(_service.setStreakMultiplierEnabled(value).catchError((_) {}));
  }
}
