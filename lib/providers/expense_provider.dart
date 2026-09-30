import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/expense_repository.dart';
import '../utils/expense_stats.dart';

/// Expenses for the selected month or date range, plus category/search
/// filters. Only the period is queried from Firestore; filters run
/// client-side, so no composite indexes are needed.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _selectedMonth = _monthStart(_clock());
  }

  final ExpenseRepository _repository;
  final DateTime Function() _clock;

  StreamSubscription<List<Expense>>? _subscription;
  String? _uid;
  late DateTime _selectedMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<Expense> _expenses = const [];
  List<Expense>? _visibleCache;
  Set<ExpenseCategory> _categories = const {};
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  DateTime get selectedMonth => _selectedMonth;

  /// All fetched expenses, before filtering.
  List<Expense> get expenses => _expenses;

  /// Expenses after the category and search filters.
  List<Expense> get visibleExpenses =>
      _visibleCache ??= List.unmodifiable(_expenses.where(_matchesFilters));

  double get total =>
      visibleExpenses.fold(0, (sum, expense) => sum + expense.amount);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  bool get canGoToNextMonth => _selectedMonth.isBefore(_monthStart(_clock()));

  bool get isCurrentMonth => !hasDateRange && !canGoToNextMonth;

  // Filters.

  bool get hasDateRange => _rangeStart != null;

  /// Custom range days (inclusive), when set.
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;

  Set<ExpenseCategory> get selectedCategories => _categories;
  String get searchQuery => _searchQuery;

  bool get hasListFilters => _categories.isNotEmpty || _searchQuery.isNotEmpty;

  bool get hasAnyFilter => hasListFilters || hasDateRange;

  /// Called by the proxy provider during build, so it must not notify
  /// listeners synchronously.
  void updateUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _selectedMonth = _monthStart(_clock());
    _rangeStart = null;
    _rangeEnd = null;
    _categories = const {};
    _searchQuery = '';
    _setExpenses(const []);
    _errorMessage = null;
    _subscribe(notify: false);
  }

  void selectMonth(DateTime month) {
    final start = _monthStart(month);
    if (start == _selectedMonth && !hasDateRange) return;
    _selectedMonth = start;
    _rangeStart = null;
    _rangeEnd = null;
    _setExpenses(const []);
    _subscribe();
  }

  void previousMonth() =>
      selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void nextMonth() {
    if (!canGoToNextMonth) return;
    selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  /// Shows a custom date range (both days inclusive) instead of a month.
  void setDateRange(DateTime start, DateTime end) {
    final first = _dayStart(start);
    final last = _dayStart(end);
    if (first == _rangeStart && last == _rangeEnd) return;
    _rangeStart = first.isAfter(last) ? last : first;
    _rangeEnd = first.isAfter(last) ? first : last;
    _setExpenses(const []);
    _subscribe();
  }

  void clearDateRange() {
    if (!hasDateRange) return;
    _rangeStart = null;
    _rangeEnd = null;
    _setExpenses(const []);
    _subscribe();
  }

  void toggleCategory(ExpenseCategory category) {
    final updated = {..._categories};
    if (!updated.remove(category)) updated.add(category);
    _categories = Set.unmodifiable(updated);
    _filtersChanged();
  }

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized == _searchQuery) return;
    _searchQuery = normalized;
    _filtersChanged();
  }

  void clearFilters() {
    final hadRange = hasDateRange;
    _categories = const {};
    _searchQuery = '';
    _rangeStart = null;
    _rangeEnd = null;
    if (hadRange) {
      _setExpenses(const []);
      _subscribe();
    } else {
      _filtersChanged();
    }
  }

  void retry() => _subscribe();

  /// Monthly totals for the summary trend chart (a separate query).
  Stream<List<MonthTotal>> watchMonthlyTotals({int months = 6}) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    final firstMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - months + 1,
    );
    return _repository
        .watchExpenses(
          uid: uid,
          start: firstMonth,
          end: DateTime(_selectedMonth.year, _selectedMonth.month + 1),
        )
        .map(
          (expenses) => ExpenseStats.byMonth(
            expenses,
            firstMonth: firstMonth,
            count: months,
          ),
        );
  }

  // Actions.

  /// Adds a new expense or updates an existing one.
  Future<String?> saveExpense(Expense expense) {
    return _run((uid) async {
      if (expense.id.isEmpty) {
        await _repository.addExpense(uid, expense);
      } else {
        await _repository.updateExpense(uid, expense);
      }
    });
  }

  /// Optimistic delete (required by Dismissible); restored if it fails.
  Future<String?> deleteExpense(Expense expense) async {
    final previous = _expenses;
    _setExpenses(_expenses.where((e) => e.id != expense.id).toList());
    _notify();

    final error = await _run(
      (uid) => _repository.deleteExpense(uid, expense.id),
    );
    if (error != null && !_expenses.any((e) => e.id == expense.id)) {
      _setExpenses(previous);
      _notify();
    }
    return error;
  }

  /// Undo: re-adds the expense with its original id.
  Future<String?> restoreExpense(Expense expense) {
    return _run((uid) => _repository.addExpense(uid, expense));
  }

  bool isInPeriod(DateTime date) {
    final (start, end) = _period;
    return !date.isBefore(start) && date.isBefore(end);
  }

  /// Query range: start inclusive, end exclusive.
  (DateTime, DateTime) get _period {
    final rangeStart = _rangeStart;
    final rangeEnd = _rangeEnd;
    if (rangeStart != null && rangeEnd != null) {
      return (
        rangeStart,
        DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day + 1),
      );
    }
    return (
      _selectedMonth,
      DateTime(_selectedMonth.year, _selectedMonth.month + 1),
    );
  }

  bool _matchesFilters(Expense expense) {
    if (_categories.isNotEmpty && !_categories.contains(expense.category)) {
      return false;
    }
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return expense.title.toLowerCase().contains(query) ||
        (expense.note?.toLowerCase().contains(query) ?? false);
  }

  void _setExpenses(List<Expense> expenses) {
    _expenses = List.unmodifiable(expenses);
    _visibleCache = null;
  }

  void _filtersChanged() {
    _visibleCache = null;
    _notify();
  }

  void _subscribe({bool notify = true}) {
    _subscription?.cancel();
    _subscription = null;

    final uid = _uid;
    if (uid == null) {
      _isLoading = false;
      if (notify) _notify();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    if (notify) _notify();

    final (start, end) = _period;
    _subscription = _repository
        .watchExpenses(uid: uid, start: start, end: end)
        .listen(
          (expenses) {
            _setExpenses(expenses);
            _isLoading = false;
            _errorMessage = null;
            _notify();
          },
          onError: (Object error) {
            _isLoading = false;
            _errorMessage = error is ExpenseRepositoryException
                ? error.message
                : 'Could not load expenses. Please try again.';
            _notify();
          },
        );
  }

  Future<String?> _run(Future<void> Function(String uid) action) async {
    final uid = _uid;
    if (uid == null) return 'Please sign in again.';
    try {
      await action(uid);
      return null;
    } on ExpenseRepositoryException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  static DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
