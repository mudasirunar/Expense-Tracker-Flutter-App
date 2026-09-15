import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/services/database_service.dart';
import 'package:expense_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test: renders Dashboard with Expense Tracker title', (WidgetTester tester) async {
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
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });
}
