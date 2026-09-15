import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider managing active application theme with local persistence.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  final SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider([this._prefs]) {
    if (_prefs != null) {
      _applySavedTheme(_prefs.getString(_prefKey));
    } else {
      _loadThemeModeAsync();
    }
  }

  /// Active theme mode (System, Light, or Dark).
  ThemeMode get themeMode => _themeMode;

  /// Whether the app is currently in dark mode (accounting for system setting).
  bool isCurrentlyDark([BuildContext? context]) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    if (context != null) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  /// Whether dark mode is explicitly active.
  bool get isDarkMode => isCurrentlyDark();

  void _applySavedTheme(String? savedModeString) {
    if (savedModeString != null) {
      _themeMode = switch (savedModeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
  }

  Future<void> _loadThemeModeAsync() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModeString = prefs.getString(_prefKey);
    if (savedModeString != null) {
      final loadedMode = switch (savedModeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (_themeMode != loadedMode) {
        _themeMode = loadedMode;
        notifyListeners();
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

  /// Toggles between Light and Dark mode, persisting the new choice.
  Future<void> toggleTheme([BuildContext? context]) async {
    final currentlyDark = isCurrentlyDark(context);
    final newMode = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
