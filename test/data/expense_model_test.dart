import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    final testDate = DateTime(2026, 9, 15, 10, 30);
    final testCreated = DateTime(2026, 9, 15, 10, 31);

    test('creates valid Expense with accurate paisa and PKR getters', () {
      final expense = Expense(
        id: 'test-123',
        title: 'Lunch',
        amountPaisa: 75050,
        category: ExpenseCategory.food,
        date: testDate,
        notes: 'Burgers and drink',
        createdAt: testCreated,
      );

      expect(expense.id, equals('test-123'));
      expect(expense.title, equals('Lunch'));
      expect(expense.amountPaisa, equals(75050));
      expect(expense.amountPkr, equals(750.50));
      expect(expense.formattedPkr, equals('PKR 750.50'));
      expect(expense.category, equals(ExpenseCategory.food));
      expect(expense.notes, equals('Burgers and drink'));
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      final original = Expense(
        id: 'uuid-1',
        title: 'Train ticket',
        amountPaisa: 25050,
        category: ExpenseCategory.transport,
        date: testDate,
        notes: null,
        createdAt: testCreated,
      );

      final map = original.toMap();
      final reconstructed = Expense.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.amountPaisa, equals(original.amountPaisa));
      expect(reconstructed.amountPkr, equals(250.50));
      expect(reconstructed.formattedPkr, equals('PKR 250.50'));
      expect(reconstructed.category, equals(original.category));
      expect(reconstructed.date, equals(original.date));
      expect(reconstructed.notes, isNull);
      expect(reconstructed.createdAt, equals(original.createdAt));
      expect(reconstructed, equals(original));
    });

    test('copyWith properly overrides specified fields while keeping others intact', () {
      final original = Expense(
        id: 'uuid-2',
        title: 'Groceries',
        amountPaisa: 50000,
        category: ExpenseCategory.shopping,
        date: testDate,
      );

      final updated = original.copyWith(
        title: 'Weekly Groceries',
        amountPaisa: 60000,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Weekly Groceries'));
      expect(updated.amountPaisa, equals(60000));
      expect(updated.amountPkr, equals(600.00));
      expect(updated.formattedPkr, equals('PKR 600.00'));
      expect(updated.category, equals(ExpenseCategory.shopping));
      expect(updated.date, equals(original.date));
    });
  });
}
