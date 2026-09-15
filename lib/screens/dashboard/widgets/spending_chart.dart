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
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Spending Distribution',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (activeCategories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${activeCategories.length} ${activeCategories.length == 1 ? "Category" : "Categories"}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),

          if (totalPaisa == 0 || activeCategories.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _EmptyDonutPainter(
                        ringColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No spending data for this month',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Elevated Donut Chart + Expanding Center Floating Summary
            Center(
              child: SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(170, 170),
                      painter: _DonutChartPainter(
                        activeCategories: activeCategories,
                        totalPaisa: totalPaisa,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    // Center Amount: Completely transparent with no background or box.
                    // Floats freely over the chart and expands horizontally when large.
                    OverflowBox(
                      minWidth: 0,
                      maxWidth: math.min(240, MediaQuery.sizeOf(context).width - 64),
                      minHeight: 0,
                      maxHeight: 170,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL SPENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.formatPaisa(totalPaisa),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Premium Category Legend Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeCategories.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final pctValue = (amount / totalPaisa) * 100;
                final percentageText = (pctValue < 0.1 && amount > 0)
                    ? '<0.1%'
                    : '${pctValue.toStringAsFixed(1)}%';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? category.darkBackgroundColor : category.lightBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.color.withValues(alpha: isDark ? 0.28 : 0.20),
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
                          boxShadow: [
                            BoxShadow(
                              color: category.color.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: isDark ? 0.25 : 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          percentageText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: category.color,
                          ),
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
    final radius = size.width / 2 - 14;
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
    final radius = size.width / 2 - 14;
    const strokeWidth = 16.0;

    // Background track ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalPaisa <= 0 || activeCategories.isEmpty) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Case 1: Single category spending - draw full smooth 360 ring
    if (activeCategories.length == 1) {
      final singlePaint = Paint()
        ..color = activeCategories.first.key.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, singlePaint);
      return;
    }

    // Case 2: Multiple categories - draw smooth rounded capsule segments
    // StrokeCap.round extends by half the stroke width on both ends.
    // In angular terms, that extension is capAngle = (strokeWidth / 2) / radius.
    final capAngle = (strokeWidth / 2) / radius;

    // Visual gap between adjacent capsule ends
    const visualGap = 0.08; // ~4.6 degrees clean space between pills
    final n = activeCategories.length;
    final totalGap = n * visualGap;
    final availableVisualSweep = (2 * math.pi) - totalGap;

    // Minimum visual pill sector so tiny values render as a complete, visible capsule
    final minVisualSector = (2 * capAngle) + 0.03;

    final ratios = activeCategories
        .map((e) => (e.value / totalPaisa).clamp(0.0, 1.0))
        .toList();

    final visualSectors = _calculateVisualSectors(
      ratios,
      availableVisualSweep,
      minVisualSector,
    );

    double currentSectorStart = -math.pi / 2;
    for (int i = 0; i < activeCategories.length; i++) {
      final category = activeCategories[i].key;
      final sectorSpan = visualSectors[i];

      // To draw a rounded capsule covering [currentSectorStart, currentSectorStart + sectorSpan],
      // the central arc must start at currentSectorStart + capAngle and sweep (sectorSpan - 2 * capAngle)
      final drawnStart = currentSectorStart + capAngle;
      final drawnSweep = math.max(0.001, sectorSpan - (2 * capAngle));

      final slicePaint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, drawnStart, drawnSweep, false, slicePaint);
      currentSectorStart += sectorSpan + visualGap;
    }
  }

  /// Allocates visual sector angles, guaranteeing that tiny spending values
  /// receive at least [minSector] radians so their rounded capsule remains clearly
  /// visible while distributing remaining sweep proportionally across larger categories.
  List<double> _calculateVisualSectors(
    List<double> ratios,
    double totalAvailableSweep,
    double minSector,
  ) {
    final count = ratios.length;
    if (count == 0) return [];

    // Fallback if all minimum sectors would exceed available sweep
    if (count * minSector >= totalAvailableSweep) {
      return ratios.map((r) => r * totalAvailableSweep).toList();
    }

    final sectors = List<double>.filled(count, 0.0);
    double allocatedForMin = 0.0;
    double remainingRatioSum = 0.0;
    final isSmall = List<bool>.filled(count, false);

    for (int i = 0; i < count; i++) {
      final naturalSweep = ratios[i] * totalAvailableSweep;
      if (naturalSweep < minSector) {
        isSmall[i] = true;
        sectors[i] = minSector;
        allocatedForMin += minSector;
      } else {
        remainingRatioSum += ratios[i];
      }
    }

    final remainingSweep = totalAvailableSweep - allocatedForMin;

    if (remainingRatioSum > 0 && remainingSweep > 0) {
      for (int i = 0; i < count; i++) {
        if (!isSmall[i]) {
          sectors[i] = (ratios[i] / remainingRatioSum) * remainingSweep;
        }
      }
    } else {
      return ratios.map((r) => r * totalAvailableSweep).toList();
    }

    return sectors;
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    if (oldDelegate.totalPaisa != totalPaisa ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.activeCategories.length != activeCategories.length) {
      return true;
    }
    for (int i = 0; i < activeCategories.length; i++) {
      if (oldDelegate.activeCategories[i].key != activeCategories[i].key ||
          oldDelegate.activeCategories[i].value != activeCategories[i].value) {
        return true;
      }
    }
    return false;
  }
}


