import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';
import 'package:cyphlab_expense_tracker/services/expense_repository.dart';

import '../fakes/fake_expense_repository.dart';

Expense _expense(String id, double amount, {DateTime? date}) => Expense(
  id: id,
  title: 'Expense $id',
  amount: amount,
  category: ExpenseCategory.food,
  date: date ?? DateTime(2026, 9, 10),
);

void main() {
  late FakeExpenseRepository repository;
  late ExpenseProvider provider;

  setUp(() {
    repository = FakeExpenseRepository();
    provider = ExpenseProvider(
      repository,
      clock: () => DateTime(2026, 9, 29, 10),
    );
  });

  tearDown(() => provider.dispose());

  test('does not subscribe until a user is set', () {
    expect(repository.watchCount, 0);
    expect(provider.isLoading, isFalse);
    expect(provider.selectedMonth, DateTime(2026, 9));
  });

  test('subscribes to the current month when a user signs in', () async {
    provider.updateUser('user-1');

    expect(provider.isLoading, isTrue);
    expect(repository.lastWatch!.uid, 'user-1');
    expect(repository.lastWatch!.start, DateTime(2026, 9));
    expect(repository.lastWatch!.end, DateTime(2026, 10));

    repository.emit([_expense('a', 100), _expense('b', 250.5)]);
    await pumpEventQueue();

    expect(provider.isLoading, isFalse);
    expect(provider.expenses, hasLength(2));
    expect(provider.total, 350.5);
  });

  test('shows the repository error message and can retry', () async {
    provider.updateUser('user-1');
    repository.emitError(const ExpenseRepositoryException('Offline'));
    await pumpEventQueue();

    expect(provider.hasError, isTrue);
    expect(provider.errorMessage, 'Offline');
    expect(provider.isLoading, isFalse);

    provider.retry();

    expect(repository.watchCount, 2);
    expect(provider.hasError, isFalse);
    expect(provider.isLoading, isTrue);
  });

  test('changing month re-subscribes with the new range', () {
    provider.updateUser('user-1');

    provider.previousMonth();

    expect(provider.selectedMonth, DateTime(2026, 8));
    expect(repository.lastWatch!.start, DateTime(2026, 8));
    expect(repository.lastWatch!.end, DateTime(2026, 9));
  });

  test('cannot move past the current month', () {
    provider.updateUser('user-1');
    final watches = repository.watchCount;

    expect(provider.canGoToNextMonth, isFalse);
    provider.nextMonth();

    expect(provider.selectedMonth, DateTime(2026, 9));
    expect(repository.watchCount, watches);
  });

  test('previous month crosses the year boundary', () {
    provider.updateUser('user-1');
    provider.selectMonth(DateTime(2026, 1, 15));

    provider.previousMonth();

    expect(provider.selectedMonth, DateTime(2025, 12));
    expect(provider.canGoToNextMonth, isTrue);
  });

  test('signing out cancels the subscription and clears data', () async {
    provider.updateUser('user-1');
    repository.emit([_expense('a', 100)]);
    await pumpEventQueue();

    provider.updateUser(null);

    expect(repository.hasListener, isFalse);
    expect(provider.expenses, isEmpty);
    expect(provider.total, 0);
  });

  test('saveExpense adds new expenses and updates existing ones', () async {
    provider.updateUser('user-1');

    expect(await provider.saveExpense(_expense('', 10)), isNull);
    expect(await provider.saveExpense(_expense('x1', 10)), isNull);

    expect(repository.calls, ['add:user-1::Expense ', 'update:user-1:x1']);
  });

  test('delete and restore call the repository with the same id', () async {
    provider.updateUser('user-1');
    final expense = _expense('x1', 10);

    await provider.deleteExpense(expense);
    await provider.restoreExpense(expense);

    expect(repository.calls, ['delete:user-1:x1', 'add:user-1:x1:Expense x1']);
  });

  test('actions return error messages', () async {
    provider.updateUser('user-1');
    repository.errorMessage = 'No permission';

    expect(await provider.deleteExpense(_expense('x1', 10)), 'No permission');
  });

  test('actions fail with a message when signed out', () async {
    expect(
      await provider.saveExpense(_expense('', 10)),
      'Please sign in again.',
    );
    expect(repository.calls, isEmpty);
  });
}
