import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service;

  bool _animationsEnabled = true;

  SettingsProvider(this._service);

  bool get animationsEnabled => _animationsEnabled;

  Future<void> load() async {
    _animationsEnabled = await _service.loadAnimationsEnabled();
    notifyListeners();
  }

  void setAnimationsEnabled(bool value) {
    _animationsEnabled = value;
    notifyListeners();
    unawaited(_service.setAnimationsEnabled(value).catchError((_) {}));
  }
}
