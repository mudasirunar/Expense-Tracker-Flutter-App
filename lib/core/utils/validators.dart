import 'currency_formatter.dart';
import 'date_formatter.dart';

/// Form input validators matching all project requirements.
abstract final class InputValidators {
  /// Validates that the expense title is not empty or containing only whitespace.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title must not be empty or contain only spaces.';
    }
    if (value.trim().length > 100) {
      return 'Title cannot exceed 100 characters.';
    }
    return null;
  }

  /// Validates that the amount is a valid number > 0 with at most 2 decimal places.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount.';
    }

    final trimmed = value.trim().replaceAll(',', '');
    final parts = trimmed.split('.');

    if (parts.length > 2) {
      return 'Please enter a valid amount format.';
    }

    if (parts.length == 2 && parts[1].length > 2) {
      return 'Amount cannot have more than 2 decimal places.';
    }

    final double? parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return 'Please enter a valid numeric amount.';
    }

    final int paisa = CurrencyFormatter.pkrToPaisa(parsed);
    if (paisa <= 0) {
      return 'Amount must be greater than zero.';
    }

    // Safety limit: 100 million PKR
    if (paisa > 10000000000) {
      return 'Amount exceeds maximum allowable limit.';
    }

    return null;
  }

  /// Validates that the selected expense date is not in the future.
  static String? validateDate(DateTime? value, [DateTime? referenceNow]) {
    if (value == null) {
      return 'Please select a date.';
    }
    if (DateFormatter.isFutureDate(value, referenceNow)) {
      return 'Expense date cannot be in the future.';
    }
    return null;
  }
}
