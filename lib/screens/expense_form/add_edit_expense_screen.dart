import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/delete_confirm_dialog.dart';

/// Screen for creating a new expense or modifying an existing one.
class AddEditExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddEditExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _notesFocusNode = FocusNode();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  bool get isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    _notesFocusNode.addListener(_onNotesFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      }
    });
    final expense = widget.existingExpense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense != null ? (expense.amountPaisa / 100).toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _selectedCategory = expense?.category ?? ExpenseCategory.food;
    _selectedDate = expense?.date ?? DateTime.now();
  }

  void _onNotesFocusChanged() {
    if (_notesFocusNode.hasFocus) {
      _scrollToNotes();
    }
  }

  void _scrollToNotes() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || !_notesFocusNode.hasFocus) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _notesFocusNode.removeListener(_onNotesFocusChanged);
    _notesFocusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(1900),
      lastDate: now, // Stated rule: no future dates allowed
      helpText: 'SELECT EXPENSE DATE',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final paisa = CurrencyFormatter.parsePkrInputToPaisa(_amountController.text);
    final provider = context.read<ExpenseProvider>();

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        final updated = widget.existingExpense!.copyWith(
          title: _titleController.text.trim(),
          amountPaisa: paisa,
          category: _selectedCategory,
          date: _selectedDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await provider.updateExpense(updated);
      } else {
        await provider.addExpense(
          title: _titleController.text.trim(),
          amountPaisa: paisa,
          category: _selectedCategory,
          date: _selectedDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Expense updated successfully.' : 'Expense recorded successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteExpense() async {
    if (!isEditing) return;

    final confirmed = await DeleteConfirmDialog.show(context);
    if (confirmed && mounted) {
      final provider = context.read<ExpenseProvider>();
      await provider.deleteExpense(widget.existingExpense!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    final bottomPadding = isKeyboardOpen
        ? 16.0
        : (MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 16
            : 24.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(CupertinoIcons.trash_fill, color: theme.colorScheme.error, size: 20),
              tooltip: 'Delete Expense',
              onPressed: _isSaving ? null : _deleteExpense,
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Amount Input
                CustomTextField(
                  controller: _amountController,
                  label: 'Amount',
                  hintText: '0.00',
                  prefixText: 'PKR ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: InputValidators.validateAmount,
                  onChanged: (val) {
                    if (_autoValidateMode == AutovalidateMode.onUserInteraction) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 2. Title Input
                CustomTextField(
                  controller: _titleController,
                  label: 'Title',
                  hintText: 'e.g. Grocery shopping, Metro card recharge',
                  validator: InputValidators.validateTitle,
                  onChanged: (val) {
                    if (_autoValidateMode == AutovalidateMode.onUserInteraction) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 3. Category Selector
                Text(
                  'Category',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return CategoryChip(
                      category: category,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 4. Date Picker Tile
                Text(
                  'Date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.0,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatter.formatDateWithWeekday(_selectedDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Notes (Optional)
                CustomTextField(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  label: 'Notes (Optional)',
                  hintText: 'Add additional context or memo...',
                  maxLines: 3,
                  scrollPadding: const EdgeInsets.only(bottom: 110),
                  onTap: _scrollToNotes,
                ),
                const SizedBox(height: 28),

                // 6. Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Save Expense',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
