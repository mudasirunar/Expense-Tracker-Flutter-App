import 'package:flutter/material.dart';
import '../core/constants/categories.dart';

/// Reusable category chip pill for filtering and selection.
class CategoryChip extends StatelessWidget {
  final ExpenseCategory? category;
  final String? customLabel;
  final IconData? customIcon;
  final Color? customColor;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showIcon;
  final bool neutralUnselected;

  const CategoryChip({
    super.key,
    required ExpenseCategory this.category,
    this.isSelected = false,
    this.onTap,
    this.showIcon = true,
    this.customColor,
    this.neutralUnselected = false,
  })  : customLabel = null,
        customIcon = null;

  const CategoryChip.all({
    super.key,
    required this.isSelected,
    this.onTap,
    this.showIcon = true,
    this.customColor,
    this.neutralUnselected = false,
  })  : category = null,
        customLabel = 'All',
        customIcon = Icons.grid_view_rounded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = customColor ??
        (category != null ? category!.color : theme.colorScheme.primary);
    final label = customLabel ?? category!.label;
    final icon = customIcon ?? category?.icon;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (isSelected) {
      bgColor = baseColor;
      borderColor = baseColor;
      textColor = Colors.white;
      iconColor = Colors.white;
    } else if (neutralUnselected) {
      bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
      borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
      iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    } else {
      bgColor = baseColor.withValues(alpha: isDark ? 0.12 : 0.08);
      borderColor = baseColor.withValues(alpha: isDark ? 0.25 : 0.18);
      textColor = isDark ? const Color(0xFFF1F5F9) : baseColor;
      iconColor = baseColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon && icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
