import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/state_views.dart';
import '../../widgets/total_card.dart';
import '../expense_form/expense_form_screen.dart';

/// Monthly expense overview: month switcher, total, and the day-grouped list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
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

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in at any time.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;

    final error = await context.read<AuthProvider>().signOut();
    if (error != null && context.mounted) _showMessage(context, error);
  }
}

/// Opens the add form, or the edit form for [expense], and reports the result.
Future<void> openExpenseForm(BuildContext context, [Expense? expense]) async {
  final result = await Navigator.of(context).push<ExpenseFormResult>(
    MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
  );
  if (result == null || !context.mounted) return;

  switch (result.action) {
    case ExpenseFormAction.added:
      final selected = context.read<ExpenseProvider>().selectedMonth;
      final date = result.expense.date;
      final inOtherMonth =
          date.year != selected.year || date.month != selected.month;
      _showMessage(
        context,
        inOtherMonth
            ? 'Expense added to ${Formatters.monthYear(date)}'
            : 'Expense added',
      );
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

class _ExpenseOverview extends StatelessWidget {
  const _ExpenseOverview();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final month = provider.selectedMonth;
    final isCurrentMonth = !provider.canGoToNextMonth;
    final showSpinner = provider.isLoading && provider.expenses.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          sliver: SliverToBoxAdapter(
            child: MonthSelector(
              month: month,
              onPrevious: provider.previousMonth,
              onNext: provider.canGoToNextMonth ? provider.nextMonth : null,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: TotalCard(
              label: isCurrentMonth
                  ? 'Spent this month'
                  : 'Spent in ${Formatters.monthYear(month)}',
              total: provider.total,
              count: provider.expenses.length,
              isLoading: showSpinner || provider.hasError,
            ),
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
              title: isCurrentMonth
                  ? 'No expenses this month'
                  : 'No expenses in ${Formatters.monthYear(month)}',
              message: 'Tap "Add expense" to record one.',
            ),
          )
        else
          _ExpenseList(expenses: provider.expenses),
        // Keeps the last tile clear of the floating action button.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

/// Day header row: `Today · LKR 1,500.00`.
class _DayHeader {
  const _DayHeader(this.date, this.total);

  final DateTime date;
  final double total;
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  /// Sorted newest first.
  final List<Expense> expenses;

  /// Interleaves a [_DayHeader] before each day's expenses.
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
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  Formatters.currency(row.total),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
