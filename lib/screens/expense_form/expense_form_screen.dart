import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/loading_button.dart';

enum ExpenseFormAction { added, updated, deleted }

/// Returned when the form closes after a change, so the home screen can show
/// feedback (and offer undo for deletes).
class ExpenseFormResult {
  const ExpenseFormResult(this.action, this.expense);

  final ExpenseFormAction action;
  final Expense expense;
}

/// Adds a new expense, or edits [expense] when given.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  ExpenseCategory? _category;
  late DateTime _date;
  bool _isSaving = false;
  bool _isDirty = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title);
    _amountController = TextEditingController(
      text: expense == null ? null : _formatAmount(expense.amount),
    );
    _noteController = TextEditingController(text: expense?.note);
    _category = expense?.category;
    _date = expense?.date ?? DateTime.now();

    for (final controller in [
      _titleController,
      _amountController,
      _noteController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static String _formatAmount(double amount) => amount == amount.truncate()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Expense date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Keep the original time of day so same-day expenses stay in order.
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final note = _noteController.text.trim();
    final expense = Expense(
      id: widget.expense?.id ?? '',
      title: _titleController.text.trim(),
      amount: Validators.parseAmount(_amountController.text),
      category: _category!,
      date: _date,
      note: note.isEmpty ? null : note,
    );

    final error = await context.read<ExpenseProvider>().saveExpense(expense);
    if (!mounted) return;
    if (error != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(
      ExpenseFormResult(
        _isEditing ? ExpenseFormAction.updated : ExpenseFormAction.added,
        expense,
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete expense?',
      message: '"${widget.expense!.title}" will be removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    // The home screen performs the delete so it can offer undo.
    Navigator.of(context)
        .pop(ExpenseFormResult(ExpenseFormAction.deleted, widget.expense!));
  }

  Future<void> _onPopBlocked() async {
    final discard = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: 'Your changes to this expense will be lost.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
          actions: [
            if (_isEditing)
              IconButton(
                tooltip: 'Delete expense',
                icon: const Icon(Icons.delete_outline),
                onPressed: _isSaving ? null : _delete,
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AppConstants.titleMaxLength,
                        ),
                      ],
                      validator: Validators.title,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Groceries',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: Validators.amount,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.payments_outlined),
                        prefixText: '${AppConstants.currencySymbol} ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: _category,
                      validator: (value) =>
                          value == null ? 'Please choose a category' : null,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final category in ExpenseCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                CategoryAvatar(category: category, radius: 12),
                                const SizedBox(width: 12),
                                Text(category.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _category = value;
                        _isDirty = true;
                      }),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(Formatters.date(_date)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: AppConstants.noteMaxLength,
                      validator: Validators.note,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(
                      label: _isEditing ? 'Save changes' : 'Add expense',
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
