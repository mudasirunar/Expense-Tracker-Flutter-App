import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';

/// Interactive and minimal donut chart displaying monthly category spending proportions.
class MonthlySpendingChart extends StatelessWidget {
  final Map<ExpenseCategory, int> categoryTotals;
  final int totalPaisa;

  const MonthlySpendingChart({
    super.key,
    required this.categoryTotals,
    required this.totalPaisa,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeCategories = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),

          if (totalPaisa == 0 || activeCategories.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _EmptyDonutPainter(
                        ringColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No spending data for this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Donut Chart + Center Label
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(150, 150),
                    painter: _DonutChartPainter(
                      activeCategories: activeCategories,
                      totalPaisa: totalPaisa,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatPaisa(totalPaisa),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Legend Breakdown
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeCategories.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / totalPaisa * 100).toStringAsFixed(1);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? category.darkBackgroundColor : category.lightBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: category.color.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: category.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyDonutPainter extends CustomPainter {
  final Color ringColor;

  _EmptyDonutPainter({required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final paint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<ExpenseCategory, int>> activeCategories;
  final int totalPaisa;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.activeCategories,
    required this.totalPaisa,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 20.0;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalPaisa <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;
    const gap = 0.04; // Visual separation between slices

    for (final entry in activeCategories) {
      final sweepAngle = (entry.value / totalPaisa) * (2 * math.pi);
      if (sweepAngle <= 0) continue;

      final slicePaint = Paint()
        ..color = entry.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final actualSweep = sweepAngle > gap ? sweepAngle - gap : sweepAngle;
      canvas.drawArc(rect, startAngle + (gap / 2), actualSweep, false, slicePaint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.totalPaisa != totalPaisa ||
        oldDelegate.activeCategories.length != activeCategories.length;
  }
}
