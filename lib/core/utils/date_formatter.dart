import 'package:intl/intl.dart';

/// Standardized date formatters and comparison utilities.
abstract final class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthYearFormat = DateFormat('MMM yyyy');
  static final DateFormat _weekdayFormat = DateFormat('EEE, MMM dd, yyyy');

  /// Formats date as `MMM dd, yyyy` (e.g. `Sep 15, 2026`).
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Formats date with weekday as `EEE, MMM dd, yyyy` (e.g. `Tue, Sep 15, 2026`).
  static String formatDateWithWeekday(DateTime date) => _weekdayFormat.format(date);

  /// Formats month and year as `MMMM yyyy` (e.g. `September 2026`).
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Formats short month and year as `MMM yyyy` (e.g. `Sep 2026`).
  static String formatShortMonthYear(DateTime date) => _shortMonthYearFormat.format(date);

  /// Checks if [date] is in the future compared to the end of today.
  static bool isFutureDate(DateTime date, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    final todayEndOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return date.isAfter(todayEndOfDay);
  }

  /// Checks if two dates fall in the same month and year.
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Returns the start of the month (1st day at 00:00:00).
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the end of the month (last day at 23:59:59.999).
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }
}
