import 'package:flutter/material.dart';

import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  void update(AppSettings value) {
    _settings = value;
    notifyListeners();
  }

  void setFontSizeLevel(int level) {
    update(_settings.copyWith(fontSizeLevel: level.clamp(1, 5)));
  }

  void setThemeId(int id) {
    update(_settings.copyWith(themeId: id.clamp(1, 5)));
  }

  void setAutoScrollEnabled(bool enabled) {
    update(_settings.copyWith(autoScrollEnabled: enabled));
  }

  void setAutoScrollSpeed(double speed) {
    final clamped = speed.clamp(0.5, 2.0);
    update(_settings.copyWith(autoScrollSpeed: clamped));
  }
}


