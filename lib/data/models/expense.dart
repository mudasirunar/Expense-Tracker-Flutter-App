import 'package:uuid/uuid.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';

/// Immutable model representing an expense transaction.
///
/// Financial precision is maintained by storing money strictly as integer [amountPaisa]
/// (1 PKR = 100 paisa), eliminating floating-point rounding issues.
class Expense {
  final String id;
  final String title;
  final int amountPaisa;
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Expense({
    String? id,
    required this.title,
    required this.amountPaisa,
    required this.category,
    required this.date,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Returns the amount in PKR as a double (e.g., `750.50`).
  double get amountPkr => CurrencyFormatter.paisaToPkr(amountPaisa);

  /// Returns the formatted PKR currency string (e.g., `"PKR 750.50"`).
  String get formattedPkr => CurrencyFormatter.formatPaisa(amountPaisa);

  /// Creates a copy of this expense with modified fields.
  Expense copyWith({
    String? id,
    String? title,
    int? amountPaisa,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amountPaisa: amountPaisa ?? this.amountPaisa,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serializes the expense into a map suitable for SQLite / JSON storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount_paisa': amountPaisa,
      'category': category.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Deserializes a map from SQLite / JSON into an [Expense] instance.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amountPaisa: (map['amount_paisa'] as num).toInt(),
      category: ExpenseCategory.fromString(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.title == title &&
        other.amountPaisa == amountPaisa &&
        other.category == category &&
        other.date == date &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, title, amountPaisa, category, date, notes, createdAt);

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amountPaisa: $amountPaisa, category: ${category.label}, date: $date)';
  }
}
