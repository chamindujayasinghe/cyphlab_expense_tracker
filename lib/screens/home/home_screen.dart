import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/filter_bar.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/state_views.dart';
import '../../widgets/total_card.dart';
import '../expense_form/expense_form_screen.dart';

/// Expenses tab: month switcher, total, filters and the day-grouped list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openExpenseForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const _ExpenseOverview(),
          ),
        ),
      ),
    );
  }
}

/// Opens the add/edit form and shows feedback for the result.
Future<void> openExpenseForm(BuildContext context, [Expense? expense]) async {
  final result = await Navigator.of(context).push<ExpenseFormResult>(
    MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
  );
  if (result == null || !context.mounted) return;

  switch (result.action) {
    case ExpenseFormAction.added:
      // Explain why a new expense doesn't appear in the current view.
      final provider = context.read<ExpenseProvider>();
      final date = result.expense.date;
      final String message;
      if (provider.isInPeriod(date)) {
        message = 'Expense added';
      } else if (provider.hasDateRange) {
        message = 'Expense added outside the selected dates';
      } else {
        message = 'Expense added to ${Formatters.monthYear(date)}';
      }
      _showMessage(context, message);
    case ExpenseFormAction.updated:
      _showMessage(context, 'Expense updated');
    case ExpenseFormAction.deleted:
      await deleteWithUndo(context, result.expense);
  }
}

/// Deletes [expense] and shows a snackbar offering to undo.
Future<void> deleteWithUndo(BuildContext context, Expense expense) async {
  final provider = context.read<ExpenseProvider>();
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"${expense.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final error = await provider.restoreExpense(expense);
            if (error != null) {
              messenger.showSnackBar(SnackBar(content: Text(error)));
            }
          },
        ),
      ),
    );

  final error = await provider.deleteExpense(expense);
  if (error != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ExpenseOverview extends StatefulWidget {
  const _ExpenseOverview();

  @override
  State<_ExpenseOverview> createState() => _ExpenseOverviewState();
}

class _ExpenseOverviewState extends State<_ExpenseOverview> {
  // Owned here so "Clear filters" can also reset the search text.
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<ExpenseProvider>().setSearchQuery(_searchController.text);
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ExpenseProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final showSpinner = provider.isLoading && provider.expenses.isEmpty;
    final rangeStart = provider.rangeStart;
    final rangeEnd = provider.rangeEnd;
    final periodLabel = rangeStart != null && rangeEnd != null
        ? Formatters.dateRange(rangeStart, rangeEnd)
        : Formatters.monthYear(provider.selectedMonth);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          sliver: SliverToBoxAdapter(
            child: provider.hasDateRange
                ? _DateRangeHeader(
                    label: periodLabel,
                    onClose: provider.clearDateRange,
                  )
                : MonthSelector(
                    month: provider.selectedMonth,
                    onPrevious: provider.previousMonth,
                    onNext: provider.canGoToNextMonth
                        ? provider.nextMonth
                        : null,
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          sliver: SliverToBoxAdapter(
            child: TotalCard(
              label: provider.isCurrentMonth
                  ? 'Spent this month'
                  : 'Spent in $periodLabel',
              total: provider.total,
              count: provider.visibleExpenses.length,
              totalCount: provider.hasListFilters
                  ? provider.expenses.length
                  : null,
              isLoading: showSpinner || provider.hasError,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FilterBar(
            controller: _searchController,
            onClearAll: _clearFilters,
          ),
        ),
        if (showSpinner)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.hasError)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.retry,
            ),
          )
        else if (provider.expenses.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: provider.isCurrentMonth
                  ? 'No expenses this month'
                  : 'No expenses in $periodLabel',
              message: 'Tap "Add expense" to record one.',
              action: provider.hasDateRange
                  ? TextButton(
                      onPressed: provider.clearDateRange,
                      child: const Text('Back to month view'),
                    )
                  : null,
            ),
          )
        else if (provider.visibleExpenses.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching expenses',
              message: 'Try a different search or category.',
              action: TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ),
          )
        else
          _ExpenseList(expenses: provider.visibleExpenses),
        // Keeps the last tile clear of the floating action button.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

/// Replaces the month selector while a custom date range is active.
class _DateRangeHeader extends StatelessWidget {
  const _DateRangeHeader({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Back to month view',
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Data for a day header row.
class _DayHeader {
  const _DayHeader(this.date, this.total);

  final DateTime date;
  final double total;
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  /// Sorted newest first.
  final List<Expense> expenses;

  List<Object> _buildRows() {
    DateTime dayOf(Expense e) =>
        DateTime(e.date.year, e.date.month, e.date.day);

    final dayTotals = <DateTime, double>{};
    for (final expense in expenses) {
      dayTotals.update(
        dayOf(expense),
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final rows = <Object>[];
    DateTime? currentDay;
    for (final expense in expenses) {
      final day = dayOf(expense);
      if (day != currentDay) {
        rows.add(_DayHeader(day, dayTotals[day]!));
        currentDay = day;
      }
      rows.add(expense);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    final theme = Theme.of(context);

    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row is _DayHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.relativeDay(row.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      Formatters.currency(row.total),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final expense = row as Expense;
        return ExpenseTile(
          expense: expense,
          onTap: () => openExpenseForm(context, expense),
          confirmDelete: () => showConfirmDialog(
            context,
            title: 'Delete expense?',
            message: '"${expense.title}" will be removed.',
            confirmLabel: 'Delete',
            isDestructive: true,
          ),
          onDeleted: () => deleteWithUndo(context, expense),
        );
      },
    );
  }
}
