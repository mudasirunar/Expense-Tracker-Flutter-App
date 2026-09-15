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

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        actions: [
          if (provider.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Reset'),
            ),
        ],
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // 2. Category & Month Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" Category Pill
                    FilterChip(
                      selected: provider.selectedCategory == null,
                      label: const Text('All Categories'),
                      onSelected: (_) => provider.setCategoryFilter(null),
                    ),
                    const SizedBox(width: 8),

                    // 5 Categories
                    ...ExpenseCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          category: cat,
                          isSelected: provider.selectedCategory == cat,
                          onTap: () {
                            if (provider.selectedCategory == cat) {
                              provider.setCategoryFilter(null);
                            } else {
                              provider.setCategoryFilter(cat);
                            }
                          },
                        ),
                      );
                    }),

                    // Month Filter Button
                    ActionChip(
                      avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: Text(
                        provider.selectedMonth != null
                            ? DateFormatter.formatShortMonthYear(provider.selectedMonth!)
                            : 'All Months',
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
