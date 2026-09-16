import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/theme_mode_dropdown.dart';
import '../expense_form/add_edit_expense_screen.dart';
import 'widgets/spending_chart.dart';

/// Primary dashboard screen displaying month totals, category breakdown, and recent expenses.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onAddExpensePressed;

  const DashboardScreen({
    super.key,
    this.onNavigateToHistory,
    this.onAddExpensePressed,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _selectedMonth;

  /// Returns sorted unique list of months that contain expenses.
  List<DateTime> _getAvailableMonths(List<Expense> allExpenses) {
    if (allExpenses.isEmpty) {
      final now = DateTime.now();
      return [DateTime(now.year, now.month)];
    }

    final monthSet = <DateTime>{};
    for (final e in allExpenses) {
      monthSet.add(DateTime(e.date.year, e.date.month));
    }

    final sorted = monthSet.toList()..sort();
    return sorted;
  }

  /// Resolves the month to display: currently selected if valid, or the newest month with expenses.
  DateTime _resolveDisplayedMonth(List<DateTime> availableMonths) {
    if (_selectedMonth != null &&
        availableMonths.any((m) => DateFormatter.isSameMonth(m, _selectedMonth!))) {
      return _selectedMonth!;
    }
    // Default to the latest month that has recorded expenses
    return availableMonths.last;
  }

  void _previousMonth(List<DateTime> availableMonths, DateTime currentMonth) {
    final index = availableMonths.indexWhere((m) => DateFormatter.isSameMonth(m, currentMonth));
    if (index > 0) {
      setState(() {
        _selectedMonth = availableMonths[index - 1];
      });
    }
  }

  void _nextMonth(List<DateTime> availableMonths, DateTime currentMonth) {
    final index = availableMonths.indexWhere((m) => DateFormatter.isSameMonth(m, currentMonth));
    if (index >= 0 && index < availableMonths.length - 1) {
      setState(() {
        _selectedMonth = availableMonths[index + 1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();
    final allExpenses = expenseProvider.allExpenses;
    final hasAnyExpenses = allExpenses.isNotEmpty;

    final availableMonths = _getAvailableMonths(allExpenses);
    final displayedMonth = _resolveDisplayedMonth(availableMonths);
    final currentMonthIndex =
        availableMonths.indexWhere((m) => DateFormatter.isSameMonth(m, displayedMonth));
    final canGoPrevious = currentMonthIndex > 0;
    final canGoNext = currentMonthIndex >= 0 && currentMonthIndex < availableMonths.length - 1;

    final isCurrentCalendarMonth = DateFormatter.isSameMonth(displayedMonth, DateTime.now());
    final monthTotalPaisa = allExpenses
        .where((e) => DateFormatter.isSameMonth(e.date, displayedMonth))
        .fold(0, (sum, e) => sum + e.amountPaisa);

    final categoryTotals = expenseProvider.getCategoryTotalsForMonth(displayedMonth);
    final recentExpenses = expenseProvider.recentFiveExpenses;

    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      floatingActionButton: hasAnyExpenses ? _buildFloatingActionButton(theme) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar — fixed, never scrolls
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: topPadding + 8, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const ThemeModeDropdown(),
              ],
            ),
          ),

          // Content area
          if (!hasAnyExpenses)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEmptyOnboardingState(theme),
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Month Navigation & Total Spending Card
                    _buildTotalCard(
                      theme: theme,
                      totalPaisa: monthTotalPaisa,
                      displayedMonth: displayedMonth,
                      isCurrentCalendarMonth: isCurrentCalendarMonth,
                      canGoPrevious: canGoPrevious,
                      canGoNext: canGoNext,
                      onPrevious: () => _previousMonth(availableMonths, displayedMonth),
                      onNext: () => _nextMonth(availableMonths, displayedMonth),
                    ),
                    const SizedBox(height: 20),

                    // 1.5 Bonus Feature: Monthly Category Spending Chart
                    MonthlySpendingChart(
                      categoryTotals: categoryTotals,
                      totalPaisa: monthTotalPaisa,
                    ),
                    const SizedBox(height: 24),

                    // 2. Category Spending Breakdown
                    _buildSectionHeader(
                      theme,
                      title: 'Category Breakdown',
                      subtitle: DateFormatter.formatMonthYear(displayedMonth),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBreakdown(theme, categoryTotals, monthTotalPaisa),
                    const SizedBox(height: 28),

                    // 3. Recent 5 Expenses Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (widget.onNavigateToHistory != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: widget.onNavigateToHistory,
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (recentExpenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 32,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No expenses recorded in ${DateFormatter.formatMonthYear(displayedMonth)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentExpenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = recentExpenses[index];
                          return ExpenseListTile(
                            expense: expense,
                            onTap: () {
                              ScaffoldMessenger.of(context).removeCurrentSnackBar();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditExpenseScreen(existingExpense: expense),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Minimalist Translucent Border FAB with + icon only when expenses > 0.
  Widget _buildFloatingActionButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: widget.onAddExpensePressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.add_rounded,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Clean, welcoming onboarding state when the app has no transactions yet.
  Widget _buildEmptyOnboardingState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 38,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Expenses Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your daily spending, manage categories, and visualize your financial habits effortlessly.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: widget.onAddExpensePressed,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Expense'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard({
    required ThemeData theme,
    required int totalPaisa,
    required DateTime displayedMonth,
    required bool isCurrentCalendarMonth,
    required bool canGoPrevious,
    required bool canGoNext,
    required VoidCallback onPrevious,
    required VoidCallback onNext,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.cardTheme.color : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: canGoPrevious ? onPrevious : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: canGoPrevious ? 'Previous Recorded Month' : 'No earlier expenses',
              ),
              Text(
                DateFormatter.formatMonthYear(displayedMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: canGoNext ? onNext : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: canGoNext ? 'Next Recorded Month' : 'No later expenses',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isCurrentCalendarMonth
                ? 'Total Spending This Month'
                : 'Total Spending in ${DateFormatter.formatShortMonthYear(displayedMonth)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatPaisa(totalPaisa),
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, {required String title, required String subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, Map<ExpenseCategory, int> totals, int totalMonthPaisa) {
    final isDark = theme.brightness == Brightness.dark;

    // Sort categories: highest spending first, then remaining
    final sortedCategories = List<ExpenseCategory>.from(ExpenseCategory.values)
      ..sort((a, b) {
        final totalA = totals[a] ?? 0;
        final totalB = totals[b] ?? 0;
        return totalB.compareTo(totalA);
      });

    return Column(
      children: sortedCategories.map((category) {
        final categoryPaisa = totals[category] ?? 0;
        final percentage = totalMonthPaisa > 0 ? (categoryPaisa / totalMonthPaisa) : 0.0;
        final percentString = totalMonthPaisa > 0
            ? (categoryPaisa > 0 && (percentage * 100) < 1.0
                ? '<1%'
                : '${(percentage * 100).toStringAsFixed(0)}%')
            : '0%';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      size: 18,
                      color: category.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyFormatter.formatPaisa(categoryPaisa),
                            maxLines: 1,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          percentString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: categoryPaisa > 0
                                ? category.color
                                : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: categoryPaisa > 0 ? percentage.clamp(0.015, 1.0) : 0.0,
                  minHeight: 5,
                  backgroundColor: category.color.withValues(alpha: isDark ? 0.12 : 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
