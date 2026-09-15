import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Tests', () {
    test('defaults to ThemeMode.system when no saved preference exists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);

      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.isDarkMode, isFalse);
    });

    test('loads saved theme mode from preferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
    });

    test('setThemeMode updates state and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(notified, isTrue);
      expect(prefs.getString('app_theme_mode'), equals('dark'));
    });

    test('toggleTheme alternates between light and dark', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, equals(ThemeMode.light));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.dark));

      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.light));
    });
  });
}
