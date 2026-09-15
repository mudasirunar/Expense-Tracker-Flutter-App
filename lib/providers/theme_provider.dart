import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider managing active application theme with local persistence.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  final SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider([this._prefs]) {
    _loadThemeMode();
  }

  /// Active theme mode (System, Light, or Dark).
  ThemeMode get themeMode => _themeMode;

  /// Whether dark mode is explicitly active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadThemeMode() {
    final savedModeString = _prefs?.getString(_prefKey);
    if (savedModeString != null) {
      switch (savedModeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
  }

  /// Updates the theme mode and persists the preference to storage.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_prefKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_prefKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_prefKey, 'system');
        break;
    }
  }

  /// Toggles between Light and Dark mode.
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
