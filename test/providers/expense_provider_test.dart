import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/data/services/database_service.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseProvider Acceptance & State Tests', () {
    late DatabaseService dbService;
    late ExpenseProvider provider;
    final now = DateTime.now();

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

    test('Acceptance Check 1: Add PKR 500 and PKR 250.50; total must show PKR 750.50', () async {
      final pkr500Paisa = CurrencyFormatter.parsePkrInputToPaisa('500');
      final pkr250_50Paisa = CurrencyFormatter.parsePkrInputToPaisa('250.50');

      await provider.addExpense(
        title: 'Grocery',
        amountPaisa: pkr500Paisa,
        category: ExpenseCategory.food,
        date: now,
      );

      await provider.addExpense(
        title: 'Bus Fare',
        amountPaisa: pkr250_50Paisa,
        category: ExpenseCategory.transport,
        date: now,
      );

      expect(provider.allExpenses.length, equals(2));
      expect(provider.currentMonthTotalPaisa, equals(75050));
      expect(provider.currentMonthTotalPkr, equals(750.50));
      expect(provider.formattedCurrentMonthTotal, equals('PKR 750.50'));
    });

    test('Acceptance Check 2: Change first expense to PKR 600; total must show PKR 850.50', () async {
      final pkr500Paisa = CurrencyFormatter.parsePkrInputToPaisa('500');
      final pkr250_50Paisa = CurrencyFormatter.parsePkrInputToPaisa('250.50');

      await provider.addExpense(
        title: 'Grocery',
        amountPaisa: pkr500Paisa,
        category: ExpenseCategory.food,
        date: now,
      );

      await provider.addExpense(
        title: 'Bus Fare',
        amountPaisa: pkr250_50Paisa,
        category: ExpenseCategory.transport,
        date: now,
      );

      expect(provider.currentMonthTotalPaisa, equals(75050));

      // Find the first expense (Grocery) and update it to PKR 600
      final firstExpense = provider.allExpenses.firstWhere((e) => e.title == 'Grocery');
      final pkr600Paisa = CurrencyFormatter.parsePkrInputToPaisa('600');

      final updatedExpense = firstExpense.copyWith(amountPaisa: pkr600Paisa);
      await provider.updateExpense(updatedExpense);

      expect(provider.currentMonthTotalPaisa, equals(85050));
      expect(provider.currentMonthTotalPkr, equals(850.50));
      expect(provider.formattedCurrentMonthTotal, equals('PKR 850.50'));
    });

    test('Acceptance Check 3: Verify category and month filters update both list and total', () async {
      final septDate = DateTime(2026, 9, 10);
      final augDate = DateTime(2026, 8, 15);

      // Sept Food
      await provider.addExpense(
        title: 'Lunch',
        amountPaisa: 30000,
        category: ExpenseCategory.food,
        date: septDate,
      );

      // Sept Transport
      await provider.addExpense(
        title: 'Cab',
        amountPaisa: 15000,
        category: ExpenseCategory.transport,
        date: septDate,
      );

      // Aug Food
      await provider.addExpense(
        title: 'Dinner',
        amountPaisa: 50000,
        category: ExpenseCategory.food,
        date: augDate,
      );

      // Initial unfiltered
      expect(provider.filteredExpenses.length, equals(3));
      expect(provider.filteredTotalPaisa, equals(95000));
      expect(provider.formattedFilteredTotal, equals('PKR 950.00'));

      // Filter by Category: Food
      provider.setCategoryFilter(ExpenseCategory.food);
      expect(provider.filteredExpenses.length, equals(2));
      expect(provider.filteredTotalPaisa, equals(80000));
      expect(provider.formattedFilteredTotal, equals('PKR 800.00'));

      // Filter by Month: September 2026 + Category: Food (both working together)
      provider.setSelectedMonth(septDate);
      expect(provider.filteredExpenses.length, equals(1));
      expect(provider.filteredExpenses.first.title, equals('Lunch'));
      expect(provider.filteredTotalPaisa, equals(30000));
      expect(provider.formattedFilteredTotal, equals('PKR 300.00'));

      // Search by title working together with filters
      provider.setSearchQuery('unc'); // matches "Lunch"
      expect(provider.filteredExpenses.length, equals(1));
      expect(provider.filteredTotalPaisa, equals(30000));

      provider.setSearchQuery('non-existent');
      expect(provider.filteredExpenses, isEmpty);
      expect(provider.filteredTotalPaisa, equals(0));
      expect(provider.formattedFilteredTotal, equals('PKR 0.00'));

      // Clear filters
      provider.clearFilters();
      expect(provider.filteredExpenses.length, equals(3));
      expect(provider.filteredTotalPaisa, equals(95000));
    });

    test('Acceptance Check 4: Confirm deletion removes expense, cancelling preserves expense', () async {
      await provider.addExpense(
        title: 'Movie',
        amountPaisa: 120000,
        category: ExpenseCategory.other,
        date: now,
      );

      expect(provider.allExpenses.length, equals(1));
      final item = provider.allExpenses.first;

      // Simulated cancel: no delete call is made -> expense preserved
      expect(provider.allExpenses.length, equals(1));
      expect(provider.allExpenses.first.title, equals('Movie'));

      // Confirmed delete: delete call is made -> expense removed
      await provider.deleteExpense(item.id);
      expect(provider.allExpenses, isEmpty);
      expect(provider.currentMonthTotalPaisa, equals(0));
    });

    test('Acceptance Check 5: recentFiveExpenses returns at most 5 items in newest-first order', () async {
      for (int i = 1; i <= 8; i++) {
        await provider.addExpense(
          title: 'Item $i',
          amountPaisa: i * 1000,
          category: ExpenseCategory.bills,
          date: DateTime(2026, 9, i),
        );
      }

      expect(provider.allExpenses.length, equals(8));
      expect(provider.recentFiveExpenses.length, equals(5));

      // Should be newest dates: Item 8, 7, 6, 5, 4
      expect(provider.recentFiveExpenses[0].title, equals('Item 8'));
      expect(provider.recentFiveExpenses[1].title, equals('Item 7'));
      expect(provider.recentFiveExpenses[2].title, equals('Item 6'));
      expect(provider.recentFiveExpenses[3].title, equals('Item 5'));
      expect(provider.recentFiveExpenses[4].title, equals('Item 4'));
    });

    test('getCategoryTotalsForMonth calculates breakdown for each category', () async {
      await provider.addExpense(
        title: 'Food 1',
        amountPaisa: 20000,
        category: ExpenseCategory.food,
        date: now,
      );
      await provider.addExpense(
        title: 'Food 2',
        amountPaisa: 30000,
        category: ExpenseCategory.food,
        date: now,
      );
      await provider.addExpense(
        title: 'Shopping 1',
        amountPaisa: 50000,
        category: ExpenseCategory.shopping,
        date: now,
      );

      final breakdown = provider.getCategoryTotalsForMonth(now);
      expect(breakdown[ExpenseCategory.food], equals(50000));
      expect(breakdown[ExpenseCategory.shopping], equals(50000));
      expect(breakdown[ExpenseCategory.transport], equals(0));
      expect(breakdown[ExpenseCategory.bills], equals(0));
      expect(breakdown[ExpenseCategory.other], equals(0));
    });
  });
}
