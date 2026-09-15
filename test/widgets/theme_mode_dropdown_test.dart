import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/widgets/theme_mode_dropdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(ThemeProvider themeProvider) {
    return ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Row(
              children: [
                ThemeModeDropdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('ThemeModeDropdown Widget Tests', () {
    testWidgets('renders default System mode selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      await tester.pumpWidget(buildTestWidget(themeProvider));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.device_phone_portrait), findsOneWidget);
    });

    testWidgets('opens pull-down menu and allows selecting Dark Mode', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      await tester.pumpWidget(buildTestWidget(themeProvider));
      await tester.pumpAndSettle();

      // Tap on the dropdown trigger capsule
      await tester.tap(find.byType(ThemeModeDropdown));
      await tester.pumpAndSettle();

      // Menu items should be visible
      expect(find.textContaining('System Default'), findsOneWidget);
      expect(find.textContaining('Light'), findsOneWidget);
      expect(find.textContaining('Dark'), findsOneWidget);

      // Select Dark Mode
      await tester.tap(find.textContaining('Dark'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(prefs.getString('app_theme_mode'), equals('dark'));
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('allows selecting Light Mode and persists choice', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(prefs);

      await tester.pumpWidget(buildTestWidget(themeProvider));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byType(ThemeModeDropdown));
      await tester.pumpAndSettle();

      // Select Light Mode
      await tester.tap(find.textContaining('Light'));
      await tester.pumpAndSettle();

      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(prefs.getString('app_theme_mode'), equals('light'));
      expect(find.text('Light'), findsOneWidget);
    });
  });
}
