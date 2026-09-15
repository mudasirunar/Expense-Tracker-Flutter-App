import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/expense.dart';

/// Clean, modular list tile displaying an individual expense transaction.
class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showCategoryChip;

  const ExpenseListTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.showCategoryChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = expense.category;

    final avatarBg = isDark ? category.darkBackgroundColor : category.lightBackgroundColor;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content Area: 2 independent full-width lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Title (left) & Amount (right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            expense.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.48,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              expense.formattedPkr,
                              maxLines: 1,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2), // Tight vertical rhythm matching home screen

                    // Line 2:
                    // When onDelete != null (History screen):
                    //   Left: [Category Chip (if showCategoryChip)] + Date
                    //   Right: Delete button below amount
                    // When onDelete == null (Home screen):
                    //   Left: [Category Chip (if showCategoryChip)] below title
                    //   Right: Date below amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left column
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showCategoryChip) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: category.color.withValues(
                                      alpha: isDark ? 0.18 : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category.label,
                                    style: TextStyle(
                                      color: category.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (onDelete != null) const SizedBox(width: 8),
                              ],
                              if (onDelete != null)
                                Flexible(
                                  child: Text(
                                    DateFormatter.formatDate(expense.date),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Right column
                        if (onDelete != null)
                          IconButton(
                            style: IconButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(CupertinoIcons.trash, size: 17),
                            color: theme.colorScheme.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete',
                            onPressed: onDelete,
                          )
                        else
                          Text(
                            DateFormatter.formatDate(expense.date),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),

                    if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.notes!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
