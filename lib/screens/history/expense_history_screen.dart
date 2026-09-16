import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/common_empty_state.dart';
import '../../widgets/delete_confirm_dialog.dart';
import '../../widgets/expense_list_tile.dart';
import '../expense_form/add_edit_expense_screen.dart';

/// Screen displaying all expenses with live search and category/month filtering.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _filterScrollController = ScrollController();
  final Map<ExpenseCategory, GlobalKey> _categoryKeys = {
    for (final cat in ExpenseCategory.values) cat: GlobalKey(),
  };

  late final AnimationController _clearIconAnimationController;
  late final Animation<double> _clearRotateAnimation;
  late final Animation<double> _clearFadeAnimation;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _clearIconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _clearRotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _clearIconAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _clearFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _clearIconAnimationController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveCategory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    _clearIconAnimationController.dispose();
    super.dispose();
  }

  void _clearSearchText(ExpenseProvider provider) {
    if (_isClearing) return;
    _isClearing = true;
    _clearIconAnimationController.forward(from: 0.0).then((_) {
      if (mounted) {
        _searchController.clear();
        provider.setSearchQuery('');
        _clearIconAnimationController.reset();
        _isClearing = false;
      }
    });
  }

  void _scrollToActiveCategory() {
    if (!mounted) return;
    final selectedCategory = context.read<ExpenseProvider>().selectedCategory;
    if (selectedCategory != null) {
      final targetContext = _categoryKeys[selectedCategory]?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    }
  }

  void _scrollToAll() {
    if (_filterScrollController.hasClients) {
      _filterScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildMonthDropdown(BuildContext context, ThemeData theme, ExpenseProvider provider) {
    final isDark = theme.brightness == Brightness.dark;
    final isMonthSelected = provider.selectedMonth != null;
    final recordedMonths = provider.recordedMonths;

    // Sentinel value — PopupMenuButton.onSelected ignores null,
    // so we use DateTime(0) to represent "All Months" (reset).
    final allMonthsSentinel = DateTime(0);

    final label = isMonthSelected
        ? DateFormatter.formatShortMonthYear(provider.selectedMonth!)
        : 'All Months';

    return Theme(
      data: theme.copyWith(
        // Kill the persistent focus/highlight stain from initialValue
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          elevation: 6,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: PopupMenuButton<DateTime>(
          tooltip: 'Filter by Month',
          offset: const Offset(0, 50),
          padding: EdgeInsets.zero,
          // All Months (48) + Divider (16) + 6.5 month rows (312) = 376
          constraints: const BoxConstraints(maxHeight: 376),
          // Auto-scroll to selected month only if beyond first 6 visible
          initialValue: () {
            if (provider.selectedMonth == null) return null;
            final idx = recordedMonths.indexWhere(
              (m) => DateFormatter.isSameMonth(m, provider.selectedMonth!),
            );
            return idx >= 6 ? provider.selectedMonth : null;
          }(),

          onSelected: (DateTime month) {
            if (month == allMonthsSentinel) {
              provider.setSelectedMonth(null);
            } else {
              provider.setSelectedMonth(month);
            }
          },
          itemBuilder: (context) {
            return [
              // "All Months" option (Reset)
              PopupMenuItem<DateTime>(
                value: allMonthsSentinel,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_month_rounded,
                      size: 18,
                      color: !isMonthSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All Months',
                        style: TextStyle(
                          fontWeight: !isMonthSelected ? FontWeight.w700 : FontWeight.w500,
                          color: !isMonthSelected ? theme.colorScheme.primary : null,
                          fontSize: 13.5,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              if (recordedMonths.isNotEmpty) const PopupMenuDivider(),

              // Only recorded months!
              ...recordedMonths.map((month) {
                final isThisSelected = isMonthSelected &&
                    DateFormatter.isSameMonth(provider.selectedMonth!, month);

                return PopupMenuItem<DateTime>(
                  value: month,
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 18,
                        color: isThisSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormatter.formatMonthYear(month),
                          style: TextStyle(
                            fontWeight: isThisSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isThisSelected ? theme.colorScheme.primary : null,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ];
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isMonthSelected
                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMonthSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isMonthSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: isMonthSelected
                      ? theme.colorScheme.primary
                      : (theme.brightness == Brightness.dark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isMonthSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isMonthSelected
                        ? theme.colorScheme.primary
                        : (theme.brightness == Brightness.dark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isMonthSelected
                      ? theme.colorScheme.primary
                      : (theme.brightness == Brightness.dark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed && mounted) {
      await context.read<ExpenseProvider>().deleteExpense(expense.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExpenseProvider>();
    final filteredExpenses = provider.filteredExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddEditExpenseScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Search Bar & Month Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => provider.setSearchQuery(val),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search expenses...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: RotationTransition(
                                    turns: _clearRotateAnimation,
                                    child: FadeTransition(
                                      opacity: _clearFadeAnimation,
                                      child: const Icon(Icons.clear_rounded, size: 18),
                                    ),
                                  ),
                                  onPressed: () => _clearSearchText(provider),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Option B: Month Dropdown
                  _buildMonthDropdown(context, theme, provider),
                ],
              ),
            ),

            // 2. Category Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                controller: _filterScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" Category Pill
                    CategoryChip.all(
                      isSelected: provider.selectedCategory == null,
                      customColor: theme.colorScheme.primary,
                      neutralUnselected: true,
                      onTap: () {
                        provider.setCategoryFilter(null);
                        _scrollToAll();
                      },
                    ),
                    const SizedBox(width: 8),

                    // 5 Categories
                    ...ExpenseCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          key: _categoryKeys[cat],
                          category: cat,
                          isSelected: provider.selectedCategory == cat,
                          customColor: theme.colorScheme.primary,
                          neutralUnselected: true,
                          onTap: () {
                            if (provider.selectedCategory == cat) {
                              provider.setCategoryFilter(null);
                            } else {
                              provider.setCategoryFilter(cat);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final targetContext = _categoryKeys[cat]?.currentContext;
                                if (targetContext != null) {
                                  Scrollable.ensureVisible(
                                    targetContext,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    alignment: 0.5,
                                  );
                                }
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 3. Filter Summary Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${provider.filteredCount} ${provider.filteredCount == 1 ? 'expense' : 'expenses'} found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ${provider.formattedFilteredTotal}',
                        maxLines: 1,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Expenses List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? _buildEmptyState(context, theme, provider)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredExpenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return ExpenseListTile(
                          expense: expense,
                          showCategoryChip: provider.selectedCategory == null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddEditExpenseScreen(existingExpense: expense),
                              ),
                            );
                          },
                          onDelete: () => _deleteExpense(expense),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ExpenseProvider provider,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final searchQuery = provider.searchQuery.trim();
    final selectedCategory = provider.selectedCategory;
    final selectedMonth = provider.selectedMonth;

    // 1. App has no recorded expenses at all
    if (provider.allExpenses.isEmpty) {
      return CommonEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Expenses Yet',
        message:
            'You haven\'t recorded any expenses yet. Tap below or the + button above to log your first transaction.',
        actionLabel: 'Add Expense',
        actionIcon: Icons.add_rounded,
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditExpenseScreen(),
            ),
          );
        },
      );
    }

    // 2. Active search query yields no results
    if (searchQuery.isNotEmpty) {
      final bool hasOtherFilters = selectedCategory != null || selectedMonth != null;
      return CommonEmptyState(
        icon: Icons.search_off_rounded,
        iconColor: Colors.amber.shade700,
        iconBackgroundColor: isDark
            ? Colors.amber.shade900.withValues(alpha: 0.25)
            : Colors.amber.shade50,
        title: 'No Results Found',
        message: hasOtherFilters
            ? 'No transactions match "$searchQuery" within your active filter criteria.'
            : 'No transactions found matching "$searchQuery". Check for spelling or try searching another keyword.',
        actionLabel: 'Clear Search',
        actionIcon: Icons.close_rounded,
        onAction: () => _clearSearchText(provider),
      );
    }

    // 3. Category filter has no matching expenses
    if (selectedCategory != null) {
      final category = selectedCategory;
      final String message = selectedMonth != null
          ? 'You haven\'t logged any ${category.label.toLowerCase()} expenses in ${DateFormatter.formatMonthYear(selectedMonth)}.'
          : 'You have no transactions recorded under the ${category.label} category.';

      return CommonEmptyState(
        icon: category.icon,
        iconColor: category.color,
        iconBackgroundColor:
            isDark ? category.darkBackgroundColor : category.lightBackgroundColor,
        title: 'No ${category.label} Expenses',
        message: message,
        actionLabel: 'Show All Categories',
        actionIcon: Icons.clear_all_rounded,
        onAction: () {
          provider.setCategoryFilter(null);
          _scrollToAll();
        },
      );
    }

    // 4. Month filter has no expenses
    if (selectedMonth != null) {
      final monthStr = DateFormatter.formatMonthYear(selectedMonth);
      return CommonEmptyState(
        icon: Icons.event_busy_rounded,
        iconColor: theme.colorScheme.primary,
        iconBackgroundColor: isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        title: 'No Expenses in $monthStr',
        message:
            'There are no transactions recorded for this period. Try picking another month or view all.',
        actionLabel: 'Show All Months',
        actionIcon: Icons.calendar_month_rounded,
        onAction: () {
          provider.setSelectedMonth(null);
        },
      );
    }

    // 5. Fallback for any other combined filter state
    return CommonEmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'No Matching Expenses',
      message: 'No transactions match your current filter criteria.',
      actionLabel: 'Clear All Filters',
      actionIcon: Icons.refresh_rounded,
      onAction: () {
        _searchController.clear();
        provider.clearFilters();
        _scrollToAll();
      },
    );
  }
}
