import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/services/database_service.dart';
import 'package:expense_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test: renders clean onboarding state on fresh install with 0 expenses', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dbService = DatabaseService();
    await dbService.init(testPrefs: prefs);

    await tester.pumpWidget(
      MyApp(
        databaseService: dbService,
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('No Expenses Yet'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    // Verified: No Floating Action Button when 0 expenses
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('App smoke test: renders active Dashboard and FAB when expenses exist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dbService = DatabaseService();
    await dbService.init(testPrefs: prefs);

    // Insert an initial expense
    await dbService.insertExpense(
      Expense(
        id: 'test-1',
        title: 'Lunch',
        amountPaisa: 50000,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MyApp(
        databaseService: dbService,
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('Category Breakdown'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
  });
}
