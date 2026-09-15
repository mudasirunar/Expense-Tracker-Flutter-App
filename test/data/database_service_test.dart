import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      dbService = DatabaseService();
      await dbService.init(testPrefs: prefs);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('initial state returns empty list', () async {
      final expenses = await dbService.getAllExpenses();
      expect(expenses, isEmpty);
    });

    test('insertExpense stores record and retrieves it properly', () async {
      final expense1 = Expense(
        id: 'exp-1',
        title: 'Lunch',
        amountPaisa: 50000,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 15),
      );

      await dbService.insertExpense(expense1);
      final list = await dbService.getAllExpenses();

      expect(list.length, equals(1));
      expect(list.first.title, equals('Lunch'));
      expect(list.first.amountPaisa, equals(50000));
      expect(list.first.formattedPkr, equals('PKR 500.00'));
    });

    test('insert multiple expenses maintains chronological order (newest first)', () async {
      final oldExpense = Expense(
        id: 'exp-old',
        title: 'Old Expense',
        amountPaisa: 10000,
        category: ExpenseCategory.other,
        date: DateTime(2026, 9, 1),
      );

      final newExpense = Expense(
        id: 'exp-new',
        title: 'New Expense',
        amountPaisa: 20000,
        category: ExpenseCategory.bills,
        date: DateTime(2026, 9, 15),
      );

      await dbService.insertExpense(oldExpense);
      await dbService.insertExpense(newExpense);

      final list = await dbService.getAllExpenses();
      expect(list.length, equals(2));
      expect(list.first.id, equals('exp-new'));
      expect(list.last.id, equals('exp-old'));
    });

    test('updateExpense modifies existing record', () async {
      final original = Expense(
        id: 'exp-edit',
        title: 'Fuel',
        amountPaisa: 50000,
        category: ExpenseCategory.transport,
        date: DateTime(2026, 9, 15),
      );

      await dbService.insertExpense(original);

      final updated = original.copyWith(
        amountPaisa: 60000,
        notes: 'Premium fuel',
      );

      await dbService.updateExpense(updated);

      final list = await dbService.getAllExpenses();
      expect(list.length, equals(1));
      expect(list.first.amountPaisa, equals(60000));
      expect(list.first.formattedPkr, equals('PKR 600.00'));
      expect(list.first.notes, equals('Premium fuel'));
    });

    test('deleteExpense removes specified record', () async {
      final expense = Expense(
        id: 'exp-del',
        title: 'Coffee',
        amountPaisa: 25050,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 15),
      );

      await dbService.insertExpense(expense);
      expect((await dbService.getAllExpenses()).length, equals(1));

      await dbService.deleteExpense('exp-del');
      expect((await dbService.getAllExpenses()), isEmpty);
    });

    test('clearAll removes all records', () async {
      await dbService.insertExpense(Expense(
        title: 'One',
        amountPaisa: 1000,
        category: ExpenseCategory.other,
        date: DateTime.now(),
      ));
      await dbService.insertExpense(Expense(
        title: 'Two',
        amountPaisa: 2000,
        category: ExpenseCategory.bills,
        date: DateTime.now(),
      ));

      expect((await dbService.getAllExpenses()).length, equals(2));

      await dbService.clearAll();
      expect((await dbService.getAllExpenses()), isEmpty);
    });
  });
}
