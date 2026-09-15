import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common_empty_state.dart';
import '../../widgets/expense_list_tile.dart';
import '../../widgets/theme_mode_dropdown.dart';
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
  DateTime _displayedMonth = DateTime.now();

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    // Don't allow navigating into future months
    if (!DateFormatter.isFutureDate(DateTime(next.year, next.month, 1))) {
      setState(() {
        _displayedMonth = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();

    final isCurrentMonth = DateFormatter.isSameMonth(_displayedMonth, DateTime.now());
    final monthTotalPaisa = expenseProvider.allExpenses
        .where((e) => DateFormatter.isSameMonth(e.date, _displayedMonth))
        .fold(0, (sum, e) => sum + e.amountPaisa);

    final categoryTotals = expenseProvider.getCategoryTotalsForMonth(_displayedMonth);
    final recentExpenses = isCurrentMonth
        ? expenseProvider.recentFiveExpenses
        : expenseProvider.allExpenses
            .where((e) => DateFormatter.isSameMonth(e.date, _displayedMonth))
            .take(5)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: const [
          ThemeModeDropdown(),
          SizedBox(width: 14),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddExpensePressed,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => expenseProvider.loadExpenses(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Month Navigation & Total Spending Card
                _buildTotalCard(theme, monthTotalPaisa, isCurrentMonth),
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
                  subtitle: DateFormatter.formatMonthYear(_displayedMonth),
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
                        onPressed: widget.onNavigateToHistory,
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recentExpenses.isEmpty)
                  CommonEmptyState(
                    title: 'No Expenses Recorded',
                    message: isCurrentMonth
                        ? 'No expenses recorded for this month yet. Tap "+ Add Expense" to begin tracking.'
                        : 'No expenses found for ${DateFormatter.formatMonthYear(_displayedMonth)}.',
                    actionLabel: isCurrentMonth ? '+ Add Expense' : null,
                    onAction: widget.onAddExpensePressed,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = recentExpenses[index];
                      return ExpenseListTile(
                        expense: expense,
                        onTap: () {
                          // Will navigate to edit in Phase 5
                        },
                      );
                    },
                  ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme, int totalPaisa, bool isCurrentMonth) {
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
                onPressed: _previousMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Previous Month',
              ),
              Text(
                DateFormatter.formatMonthYear(_displayedMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: isCurrentMonth ? null : _nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Next Month',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isCurrentMonth ? 'Total Spending This Month' : 'Total Spending in ${DateFormatter.formatShortMonthYear(_displayedMonth)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatPaisa(totalPaisa),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((category) {
            final categoryPaisa = totals[category] ?? 0;
            return Container(
              width: (constraints.maxWidth - 8) / 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatPaisa(categoryPaisa),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
