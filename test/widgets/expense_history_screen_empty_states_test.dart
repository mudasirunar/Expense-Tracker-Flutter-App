import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/services/database_service.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/history/expense_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseHistoryScreen Empty State Tests', () {
    late DatabaseService dbService;
    late ExpenseProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      dbService = DatabaseService();
      await dbService.init(testPrefs: prefs);
      provider = ExpenseProvider(dbService);
      await provider.loadExpenses();
    });

    tearDown(() async {
      await dbService.close();
    });

    Widget createWidget() {
      return ChangeNotifierProvider<ExpenseProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: ExpenseHistoryScreen(),
        ),
      );
    }

    testWidgets('shows "No Expenses Yet" when there are 0 expenses in app', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Expenses Yet'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('shows "No Results Found" when search does not match', (tester) async {
      await provider.addExpense(
        title: 'Lunch',
        amountPaisa: 50000,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query that doesn't match
      await tester.enterText(find.byType(TextField), 'Gym Membership');
      await tester.pumpAndSettle();

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('shows category-specific empty state when selected category has no expenses', (tester) async {
      await provider.addExpense(
        title: 'Burger',
        amountPaisa: 45000,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Select 'Transport' category
      provider.setCategoryFilter(ExpenseCategory.transport);
      await tester.pumpAndSettle();

      expect(find.text('No Transport Expenses'), findsOneWidget);
      expect(find.text('Show All Categories'), findsOneWidget);

      // Tap Show All Categories
      await tester.tap(find.text('Show All Categories'));
      await tester.pumpAndSettle();

      expect(provider.selectedCategory, isNull);
      expect(find.text('Burger'), findsOneWidget);
    });

    testWidgets('shows month-specific empty state when selected month has no expenses', (tester) async {
      await provider.addExpense(
        title: 'Movie Ticket',
        amountPaisa: 120000,
        category: ExpenseCategory.other,
        date: DateTime(2025, 5, 10),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Select a different month (e.g., January 2024)
      provider.setSelectedMonth(DateTime(2024, 1));
      await tester.pumpAndSettle();

      expect(find.textContaining('No Expenses in January 2024'), findsOneWidget);
      expect(find.text('Show All Months'), findsOneWidget);

      // Tap Show All Months
      await tester.tap(find.text('Show All Months'));
      await tester.pumpAndSettle();

      expect(provider.selectedMonth, isNull);
      expect(find.text('Movie Ticket'), findsOneWidget);
    });
  });
}
