import 'package:intl/intl.dart';

/// Utility class for precise currency calculations and formatting.
///
/// All financial calculations in the app are performed using integer [paisa]
/// (1 PKR = 100 paisas) to completely eliminate floating-point precision errors.
abstract final class CurrencyFormatter {
  static const String currencyCode = 'PKR';
  static const int paisaPerPkr = 100;

  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');

  /// Converts integer paisa into formatted PKR string with 2 decimal places.
  /// Example: `75050` -> `"PKR 750.50"` (or `"750.50"` if [includeSymbol] is false).
  static String formatPaisa(int paisa, {bool includeSymbol = true}) {
    final double pkrValue = paisa / paisaPerPkr;
    final String formattedNumber = _formatter.format(pkrValue);
    return includeSymbol ? '$currencyCode $formattedNumber' : formattedNumber;
  }

  /// Converts integer paisa into double PKR for chart or display purposes.
  static double paisaToPkr(int paisa) {
    return paisa / paisaPerPkr;
  }

  /// Converts a double PKR value to integer paisa.
  static int pkrToPaisa(double pkr) {
    return (pkr * paisaPerPkr).round();
  }

  /// Parses a user-entered PKR string into integer paisa.
  ///
  /// Throws [FormatException] if:
  /// - Input is empty or not a valid number.
  /// - Input has more than 2 decimal places.
  /// - Parsed paisa value is negative or zero (when [mustBePositive] is true).
  static int parsePkrInputToPaisa(String input, {bool mustBePositive = true}) {
    final trimmed = input.trim().replaceAll(',', '');
    if (trimmed.isEmpty) {
      throw const FormatException('Amount cannot be empty');
    }

    final parts = trimmed.split('.');
    if (parts.length > 2) {
      throw const FormatException('Invalid amount format');
    }

    if (parts.length == 2 && parts[1].length > 2) {
      throw const FormatException('Amount cannot have more than 2 decimal places');
    }

    final double? parsedDouble = double.tryParse(trimmed);
    if (parsedDouble == null || parsedDouble.isNaN || parsedDouble.isInfinite) {
      throw const FormatException('Please enter a valid number');
    }

    final int paisa = (parsedDouble * paisaPerPkr).round();
    if (mustBePositive && paisa <= 0) {
      throw const FormatException('Amount must be greater than zero');
    }

    return paisa;
  }

  /// Safe helper that attempts to parse without throwing.
  static int? tryParsePkrInputToPaisa(String? input, {bool mustBePositive = true}) {
    if (input == null) return null;
    try {
      return parsePkrInputToPaisa(input, mustBePositive: mustBePositive);
    } catch (_) {
      return null;
    }
  }
}
