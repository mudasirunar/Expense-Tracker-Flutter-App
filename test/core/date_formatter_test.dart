import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 9, 15, 14, 30);

    test('formats date properly', () {
      expect(DateFormatter.formatDate(testDate), equals('Sep 15, 2026'));
      expect(DateFormatter.formatMonthYear(testDate), equals('September 2026'));
      expect(DateFormatter.formatShortMonthYear(testDate), equals('Sep 2026'));
    });

    test('isSameMonth checks month and year equality', () {
      expect(DateFormatter.isSameMonth(DateTime(2026, 9, 1), DateTime(2026, 9, 28)), isTrue);
      expect(DateFormatter.isSameMonth(DateTime(2026, 9, 1), DateTime(2026, 10, 1)), isFalse);
      expect(DateFormatter.isSameMonth(DateTime(2026, 9, 1), DateTime(2025, 9, 1)), isFalse);
    });

    test('startOfMonth and endOfMonth boundaries', () {
      final start = DateFormatter.startOfMonth(testDate);
      final end = DateFormatter.endOfMonth(testDate);

      expect(start.year, equals(2026));
      expect(start.month, equals(9));
      expect(start.day, equals(1));

      expect(end.year, equals(2026));
      expect(end.month, equals(9));
      expect(end.day, equals(30));
    });
  });
}
