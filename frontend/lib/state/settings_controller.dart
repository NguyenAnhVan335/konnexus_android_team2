import 'package:flutter/material.dart';

import '../core/storage/preferences_store.dart';
import '../theme/app_colors.dart';
import 'app_change_notifier.dart';

/// Tuỳ chọn giao diện: chế độ sáng/tối và màu nhấn ("Màu theme").
class SettingsController extends AppChangeNotifier {
  SettingsController(this._store);

  final PreferencesStore _store;

  ThemeMode _themeMode = ThemeMode.light;
  int _accentIndex = 0;

  ThemeMode get themeMode => _themeMode;

  int get accentIndex => _accentIndex;

  Color get accent => AppColors.accentOptions[_accentIndex];

  String get accentKey => AppColors.accentKeys[_accentIndex];

  void load() {
    _themeMode = _themeModeFromKey(_store.themeMode);
    _accentIndex = AppColors.accentIndexFromKey(_store.accentKey);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _store.saveThemeMode(_themeModeKey(mode));
  }

  Future<void> setAccentIndex(int index) async {
    if (index < 0 ||
        index >= AppColors.accentOptions.length ||
        _accentIndex == index) {
      return;
    }
    _accentIndex = index;
    notifyListeners();
    await _store.saveAccent(AppColors.accentKeys[index]);
  }

  static String _themeModeKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  static ThemeMode _themeModeFromKey(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
