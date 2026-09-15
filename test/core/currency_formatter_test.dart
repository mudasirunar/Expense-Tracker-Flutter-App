import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter - Integer Paisa Precision', () {
    test('formats paisa to formatted PKR string', () {
      expect(CurrencyFormatter.formatPaisa(50000), equals('PKR 500.00'));
      expect(CurrencyFormatter.formatPaisa(25050), equals('PKR 250.50'));
      expect(CurrencyFormatter.formatPaisa(75050), equals('PKR 750.50'));
      expect(CurrencyFormatter.formatPaisa(85050), equals('PKR 850.50'));
      expect(CurrencyFormatter.formatPaisa(0), equals('PKR 0.00'));
    });

    test('formats large paisa with thousands comma separator', () {
      expect(CurrencyFormatter.formatPaisa(12500000), equals('PKR 125,000.00'));
      expect(CurrencyFormatter.formatPaisa(12345678), equals('PKR 123,456.78'));
    });

    test('converts without currency symbol when specified', () {
      expect(CurrencyFormatter.formatPaisa(25050, includeSymbol: false), equals('250.50'));
      expect(CurrencyFormatter.formatPaisa(50000, includeSymbol: false), equals('500.00'));
    });

    test('Acceptance Check 1: 500 PKR + 250.50 PKR = 750.50 PKR without rounding errors', () {
      final int expense1Paisa = CurrencyFormatter.parsePkrInputToPaisa('500');
      final int expense2Paisa = CurrencyFormatter.parsePkrInputToPaisa('250.50');
      final int totalPaisa = expense1Paisa + expense2Paisa;

      expect(expense1Paisa, equals(50000));
      expect(expense2Paisa, equals(25050));
      expect(totalPaisa, equals(75050));
      expect(CurrencyFormatter.formatPaisa(totalPaisa), equals('PKR 750.50'));
    });

    test('Acceptance Check 2: 600 PKR + 250.50 PKR = 850.50 PKR', () {
      final int updatedExpense1Paisa = CurrencyFormatter.parsePkrInputToPaisa('600');
      final int expense2Paisa = CurrencyFormatter.parsePkrInputToPaisa('250.50');
      final int totalPaisa = updatedExpense1Paisa + expense2Paisa;

      expect(totalPaisa, equals(85050));
      expect(CurrencyFormatter.formatPaisa(totalPaisa), equals('PKR 850.50'));
    });

    test('parsePkrInputToPaisa handles commas and whitespace', () {
      expect(CurrencyFormatter.parsePkrInputToPaisa(' 1,500.25 '), equals(150025));
    });

    test('parsePkrInputToPaisa rejects invalid formats', () {
      expect(() => CurrencyFormatter.parsePkrInputToPaisa(''), throwsA(isA<FormatException>()));
      expect(() => CurrencyFormatter.parsePkrInputToPaisa('   '), throwsA(isA<FormatException>()));
      expect(() => CurrencyFormatter.parsePkrInputToPaisa('abc'), throwsA(isA<FormatException>()));
      expect(() => CurrencyFormatter.parsePkrInputToPaisa('10.234'), throwsA(isA<FormatException>()));
      expect(() => CurrencyFormatter.parsePkrInputToPaisa('-100'), throwsA(isA<FormatException>()));
      expect(() => CurrencyFormatter.parsePkrInputToPaisa('0'), throwsA(isA<FormatException>()));
    });

    test('tryParsePkrInputToPaisa returns null on invalid input', () {
      expect(CurrencyFormatter.tryParsePkrInputToPaisa('invalid'), isNull);
      expect(CurrencyFormatter.tryParsePkrInputToPaisa(null), isNull);
      expect(CurrencyFormatter.tryParsePkrInputToPaisa('100.50'), equals(10050));
    });
  });
}
