import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/validators.dart';

void main() {
  group('InputValidators - Title Validation', () {
    test('rejects empty title or whitespace-only title', () {
      expect(InputValidators.validateTitle(null), isNotNull);
      expect(InputValidators.validateTitle(''), isNotNull);
      expect(InputValidators.validateTitle('   '), isNotNull);
      expect(InputValidators.validateTitle('\t\n'), isNotNull);
    });

    test('accepts valid title', () {
      expect(InputValidators.validateTitle('Grocery'), isNull);
      expect(InputValidators.validateTitle('  Taxi fare  '), isNull);
    });
  });

  group('InputValidators - Amount Validation', () {
    test('rejects null, empty, or non-numeric amount', () {
      expect(InputValidators.validateAmount(null), isNotNull);
      expect(InputValidators.validateAmount(''), isNotNull);
      expect(InputValidators.validateAmount('abc'), isNotNull);
    });

    test('rejects zero and negative amounts', () {
      expect(InputValidators.validateAmount('0'), isNotNull);
      expect(InputValidators.validateAmount('0.00'), isNotNull);
      expect(InputValidators.validateAmount('-10'), isNotNull);
      expect(InputValidators.validateAmount('-0.50'), isNotNull);
    });

    test('rejects amounts with more than 2 decimal places', () {
      expect(InputValidators.validateAmount('10.255'), isNotNull);
      expect(InputValidators.validateAmount('500.123'), isNotNull);
    });

    test('accepts valid amounts', () {
      expect(InputValidators.validateAmount('500'), isNull);
      expect(InputValidators.validateAmount('250.50'), isNull);
      expect(InputValidators.validateAmount('0.75'), isNull);
      expect(InputValidators.validateAmount('1,500.00'), isNull);
    });
  });

  group('InputValidators - Date Validation', () {
    final DateTime mockToday = DateTime(2026, 9, 15, 12, 0, 0);

    test('rejects null date', () {
      expect(InputValidators.validateDate(null, mockToday), isNotNull);
    });

    test('rejects future date', () {
      final futureDate = DateTime(2026, 9, 16);
      expect(InputValidators.validateDate(futureDate, mockToday), isNotNull);
    });

    test('accepts today and past dates', () {
      final todayDate = DateTime(2026, 9, 15, 8, 0, 0);
      final pastDate = DateTime(2026, 9, 1);
      expect(InputValidators.validateDate(todayDate, mockToday), isNull);
      expect(InputValidators.validateDate(pastDate, mockToday), isNull);
    });
  });
}
