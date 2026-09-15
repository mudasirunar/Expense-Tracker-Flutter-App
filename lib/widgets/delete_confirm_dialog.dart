import 'package:flutter/material.dart';

/// Modal dialog prompting confirmation before permanently deleting an expense.
class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const DeleteConfirmDialog({
    super.key,
    this.title = 'Delete Expense?',
    this.message = 'This action cannot be undone.',
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
  });

  /// Displays the confirmation dialog and returns true if user confirmed, false/null if cancelled.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => DeleteConfirmDialog(
        title: title ?? 'Delete Expense?',
        message: message ?? 'This action cannot be undone.',
        confirmLabel: confirmLabel ?? 'Delete',
        cancelLabel: cancelLabel ?? 'Cancel',
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      contentPadding: EdgeInsets.fromLTRB(
        24,
        isLandscape ? 16 : 24,
        24,
        isLandscape ? 12 : 16,
      ),
      actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, isLandscape ? 16 : 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Centered Icon Badge
              Container(
                width: isLandscape ? 44 : 52,
                height: isLandscape ? 44 : 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(
                      alpha: isDark ? 0.35 : 0.20,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: isLandscape ? 22 : 26,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              SizedBox(height: isLandscape ? 10 : 14),

              // Centered Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isLandscape ? 18 : 20,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Centered Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.20 : 0.15,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
