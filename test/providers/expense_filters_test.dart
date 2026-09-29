import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/providers/expense_provider.dart';

import '../fakes/fake_expense_repository.dart';

void main() {
  late FakeExpenseRepository repository;
  late ExpenseProvider provider;

  final lunch = Expense(
    id: '1',
    title: 'Lunch',
    amount: 1000,
    category: ExpenseCategory.food,
    date: DateTime(2026, 9, 20),
    note: 'Team outing',
  );
  final bus = Expense(
    id: '2',
    title: 'Bus fare',
    amount: 200,
    category: ExpenseCategory.transport,
    date: DateTime(2026, 9, 15),
  );
  final groceries = Expense(
    id: '3',
    title: 'Groceries',
    amount: 3000,
    category: ExpenseCategory.food,
    date: DateTime(2026, 9, 10),
    note: 'Weekly shop',
  );

  setUp(() async {
    repository = FakeExpenseRepository();
    provider = ExpenseProvider(
      repository,
      clock: () => DateTime(2026, 9, 29, 10),
    )..updateUser('user-1');
    repository.emit([lunch, bus, groceries]);
    await pumpEventQueue();
  });

  tearDown(() => provider.dispose());

  test('without filters everything is visible', () {
    expect(provider.visibleExpenses, [lunch, bus, groceries]);
    expect(provider.total, 4200);
    expect(provider.hasAnyFilter, isFalse);
  });

  test('category filter keeps only selected categories', () {
    provider.toggleCategory(ExpenseCategory.food);

    expect(provider.visibleExpenses, [lunch, groceries]);
    expect(provider.total, 4000);
    expect(provider.hasListFilters, isTrue);

    provider.toggleCategory(ExpenseCategory.transport);
    expect(provider.visibleExpenses, hasLength(3));

    provider.toggleCategory(ExpenseCategory.food);
    expect(provider.visibleExpenses, [bus]);
  });

  test('search matches title or note, case-insensitively', () {
    provider.setSearchQuery('  LUNCH ');
    expect(provider.visibleExpenses, [lunch]);

    provider.setSearchQuery('weekly');
    expect(provider.visibleExpenses, [groceries]);

    provider.setSearchQuery('taxi');
    expect(provider.visibleExpenses, isEmpty);
    expect(provider.total, 0);
  });

  test('search and category filters combine', () {
    provider.toggleCategory(ExpenseCategory.food);
    provider.setSearchQuery('shop');

    expect(provider.visibleExpenses, [groceries]);
  });

  test('date range re-queries with inclusive end day', () {
    provider.setDateRange(DateTime(2026, 9, 12, 15), DateTime(2026, 9, 18));

    expect(provider.hasDateRange, isTrue);
    expect(repository.lastWatch!.start, DateTime(2026, 9, 12));
    expect(repository.lastWatch!.end, DateTime(2026, 9, 19));
    expect(provider.isCurrentMonth, isFalse);
    expect(provider.isInPeriod(DateTime(2026, 9, 18, 23)), isTrue);
    expect(provider.isInPeriod(DateTime(2026, 9, 19)), isFalse);
  });

  test('clearing the date range returns to the selected month', () {
    provider.setDateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 5));

    provider.clearDateRange();

    expect(provider.hasDateRange, isFalse);
    expect(repository.lastWatch!.start, DateTime(2026, 9));
    expect(repository.lastWatch!.end, DateTime(2026, 10));
  });

  test('clearFilters resets categories, search and range', () {
    provider.toggleCategory(ExpenseCategory.food);
    provider.setSearchQuery('lunch');
    provider.setDateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 5));

    provider.clearFilters();

    expect(provider.hasAnyFilter, isFalse);
    expect(provider.selectedCategories, isEmpty);
    expect(provider.searchQuery, isEmpty);
    expect(repository.lastWatch!.end, DateTime(2026, 10));
  });

  test('filters are kept when changing month', () async {
    provider.toggleCategory(ExpenseCategory.transport);

    provider.previousMonth();
    repository.emit([bus.copyWith(id: '4', date: DateTime(2026, 8, 3))]);
    await pumpEventQueue();

    expect(provider.selectedCategories, {ExpenseCategory.transport});
    expect(provider.visibleExpenses, hasLength(1));
  });

  test('signing in as another user resets filters', () {
    provider.toggleCategory(ExpenseCategory.food);
    provider.setSearchQuery('lunch');

    provider.updateUser('user-2');

    expect(provider.hasAnyFilter, isFalse);
  });
}
