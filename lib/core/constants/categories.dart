import 'package:flutter/material.dart';

/// Predefined expense categories required by project specifications.
enum ExpenseCategory {
  food('Food', Icons.restaurant_rounded, Color(0xFFD97706), Color(0xFFFEF3C7), Color(0xFF451A03)),
  transport('Transport', Icons.directions_subway_rounded, Color(0xFF2563EB), Color(0xFFEFF6FF), Color(0xFF172554)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFDB2777), Color(0xFFFDF2F8), Color(0xFF500724)),
  bills('Bills', Icons.receipt_long_rounded, Color(0xFF7C3AED), Color(0xFFF5F3FF), Color(0xFF2E1065)),
  other('Other', Icons.category_rounded, Color(0xFF4B5563), Color(0xFFF3F4F6), Color(0xFF111827));

  final String label;
  final IconData icon;
  final Color color;
  final Color lightBackgroundColor;
  final Color darkBackgroundColor;

  const ExpenseCategory(
    this.label,
    this.icon,
    this.color,
    this.lightBackgroundColor,
    this.darkBackgroundColor,
  );

  /// Resolves an [ExpenseCategory] from its raw string name.
  static ExpenseCategory fromString(String name) {
    return ExpenseCategory.values.firstWhere(
      (cat) => cat.name.toLowerCase() == name.trim().toLowerCase() ||
          cat.label.toLowerCase() == name.trim().toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
