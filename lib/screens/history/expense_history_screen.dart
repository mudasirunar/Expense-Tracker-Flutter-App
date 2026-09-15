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

  Future<void> _pickMonth(BuildContext context, ExpenseProvider provider) async {
    final now = DateTime.now();
    final currentSelected = provider.selectedMonth ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentSelected,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'SELECT MONTH TO FILTER',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      provider.setSelectedMonth(DateTime(picked.year, picked.month));
    }
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
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => provider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search expenses by title...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
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

            // 2. Category & Month Filter Pills
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

                    // Month Filter Button
                    ActionChip(
                      avatar: Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: provider.selectedMonth != null
                            ? Colors.white
                            : (theme.brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                      label: Text(
                        provider.selectedMonth != null
                            ? DateFormatter.formatShortMonthYear(provider.selectedMonth!)
                            : 'All Months',
                        style: TextStyle(
                          color: provider.selectedMonth != null
                              ? Colors.white
                              : (theme.brightness == Brightness.dark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155)),
                          fontWeight: provider.selectedMonth != null
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: provider.selectedMonth != null
                          ? theme.colorScheme.primary
                          : (theme.brightness == Brightness.dark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC)),
                      side: BorderSide(
                        color: provider.selectedMonth != null
                            ? theme.colorScheme.primary
                            : (theme.brightness == Brightness.dark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: provider.selectedMonth != null ? 1.5 : 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: () => _pickMonth(context, provider),
                    ),
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
                  Text(
                    '${provider.filteredCount} ${provider.filteredCount == 1 ? 'expense' : 'expenses'} found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Total: ${provider.formattedFilteredTotal}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Expenses List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? CommonEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Matching Expenses',
                      message: provider.hasActiveFilters
                          ? 'No transactions match your current search or filter criteria.'
                          : 'You haven\'t recorded any expenses yet.',
                      actionLabel: provider.hasActiveFilters ? 'Clear Filters' : null,
                      onAction: provider.hasActiveFilters
                          ? () {
                              _searchController.clear();
                              provider.clearFilters();
                              _scrollToAll();
                            }
                          : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredExpenses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return ExpenseListTile(
                          expense: expense,
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
}
