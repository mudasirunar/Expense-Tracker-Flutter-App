import 'package:flutter/foundation.dart';
import '../core/constants/categories.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/expense.dart';
import '../data/services/database_service.dart';

/// Primary state management provider for expenses, calculations, and filters.
///
/// Ensures exact mathematical precision by calculating all aggregates
/// using integer [amountPaisa] (1 PKR = 100 paisas).
class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<Expense> _expenses = [];
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  DateTime? _selectedMonth;
  bool _isLoading = false;
  String? _errorMessage;

  ExpenseProvider(this._databaseService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  ExpenseCategory? get selectedCategory => _selectedCategory;
  DateTime? get selectedMonth => _selectedMonth;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedCategory != null || _selectedMonth != null;

  /// Returns all expenses, unmodifiable, sorted newest first.
  List<Expense> get allExpenses => List.unmodifiable(_expenses);

  /// Returns up to the 5 most recent expenses for the Dashboard.
  List<Expense> get recentFiveExpenses =>
      _expenses.length <= 5 ? List.unmodifiable(_expenses) : List.unmodifiable(_expenses.sublist(0, 5));

  /// Calculates total paisa spent in the current calendar month.
  int get currentMonthTotalPaisa {
    final now = DateTime.now();
    return _expenses
        .where((e) => DateFormatter.isSameMonth(e.date, now))
        .fold(0, (sum, e) => sum + e.amountPaisa);
  }

  /// Current month total in PKR double.
  double get currentMonthTotalPkr => CurrencyFormatter.paisaToPkr(currentMonthTotalPaisa);

  /// Formatted current month total (e.g. `PKR 12,450.00`).
  String get formattedCurrentMonthTotal => CurrencyFormatter.formatPaisa(currentMonthTotalPaisa);

  /// Calculates the total paisa spent for a specific category in a given month.
  int getCategoryTotalPaisa(ExpenseCategory category, DateTime month) {
    return _expenses
        .where((e) => e.category == category && DateFormatter.isSameMonth(e.date, month))
        .fold(0, (sum, e) => sum + e.amountPaisa);
  }

  /// Calculates a map of all categories and their respective totals for a given month.
  Map<ExpenseCategory, int> getCategoryTotalsForMonth(DateTime month) {
    final totals = <ExpenseCategory, int>{};
    for (final category in ExpenseCategory.values) {
      totals[category] = getCategoryTotalPaisa(category, month);
    }
    return totals;
  }

  /// Returns expenses matching all active search and filter criteria.
  List<Expense> get filteredExpenses {
    return _expenses.where((expense) {
      // 1. Search filter: case-insensitive substring on title
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        if (!expense.title.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 2. Category filter
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }

      // 3. Month filter
      if (_selectedMonth != null && !DateFormatter.isSameMonth(expense.date, _selectedMonth!)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Exact integer sum of paisa for the currently filtered expenses.
  int get filteredTotalPaisa {
    return filteredExpenses.fold(0, (sum, e) => sum + e.amountPaisa);
  }

  /// Double PKR value of the filtered total.
  double get filteredTotalPkr => CurrencyFormatter.paisaToPkr(filteredTotalPaisa);

  /// Formatted PKR string of the filtered total (e.g. `PKR 750.50`).
  String get formattedFilteredTotal => CurrencyFormatter.formatPaisa(filteredTotalPaisa);

  /// Number of expenses matching the active filter.
  int get filteredCount => filteredExpenses.length;

  /// Finds a specific expense by [id].
  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // State Mutation Methods

  /// Loads all expenses from the persistent storage database.
  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_databaseService.isInitialized) {
        await _databaseService.init();
      }
      _expenses = await _databaseService.getAllExpenses();
      _sortExpenses();
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new expense record to storage and updates state.
  Future<void> addExpense({
    required String title,
    required int amountPaisa,
    required ExpenseCategory category,
    required DateTime date,
    String? notes,
  }) async {
    final newExpense = Expense(
      title: title.trim(),
      amountPaisa: amountPaisa,
      category: category,
      date: date,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );

    await _databaseService.insertExpense(newExpense);
    _expenses.add(newExpense);
    _sortExpenses();
    notifyListeners();
  }

  /// Updates an existing expense in storage and in state.
  Future<void> updateExpense(Expense updatedExpense) async {
    await _databaseService.updateExpense(updatedExpense);
    final index = _expenses.indexWhere((e) => e.id == updatedExpense.id);
    if (index != -1) {
      _expenses[index] = updatedExpense;
      _sortExpenses();
      notifyListeners();
    }
  }

  /// Deletes an expense by its [id] from storage and state.
  Future<void> deleteExpense(String id) async {
    await _databaseService.deleteExpense(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Updates the search query filter.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Updates the category filter (null means all categories).
  void setCategoryFilter(ExpenseCategory? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// Updates the selected month filter (null means all months).
  void setSelectedMonth(DateTime? month) {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    notifyListeners();
  }

  /// Resets all active filters.
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedMonth = null;
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) {
      final cmp = b.date.compareTo(a.date);
      return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
    });
  }
}
