import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/expense_repository.dart';

/// Holds the signed-in user's expenses for the selected month.
///
/// Wired to [AuthProvider] through a proxy provider: [updateUser] starts or
/// stops the Firestore subscription as the user signs in or out. Actions
/// return an error message on failure, or null on success.
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
  List<Expense> _expenses = const [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  /// First day of the month being shown.
  DateTime get selectedMonth => _selectedMonth;

  /// Expenses in the selected month, newest first.
  List<Expense> get expenses => _expenses;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  double get total => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  /// Months after the current one can't have expenses worth browsing.
  bool get canGoToNextMonth => _selectedMonth.isBefore(_monthStart(_clock()));

  /// Called by the proxy provider whenever auth state changes. Must not call
  /// [notifyListeners] synchronously because it runs during a build.
  void updateUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _selectedMonth = _monthStart(_clock());
    _expenses = const [];
    _errorMessage = null;
    _subscribe(notify: false);
  }

  void selectMonth(DateTime month) {
    final start = _monthStart(month);
    if (start == _selectedMonth) return;
    _selectedMonth = start;
    _expenses = const [];
    _subscribe();
  }

  void previousMonth() =>
      selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void nextMonth() {
    if (!canGoToNextMonth) return;
    selectMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1));
  }

  /// Re-subscribes after an error.
  void retry() => _subscribe();

  /// Adds [expense] if it has no id yet, otherwise updates it.
  Future<String?> saveExpense(Expense expense) {
    return _run((uid) async {
      if (expense.id.isEmpty) {
        await _repository.addExpense(uid, expense);
      } else {
        await _repository.updateExpense(uid, expense);
      }
    });
  }

  /// Removes the expense from the list immediately (so a swiped-away tile
  /// disappears at once), then deletes it; puts it back if that fails.
  Future<String?> deleteExpense(Expense expense) async {
    final previous = _expenses;
    _expenses = List.unmodifiable(_expenses.where((e) => e.id != expense.id));
    _notify();

    final error = await _run(
      (uid) => _repository.deleteExpense(uid, expense.id),
    );
    if (error != null && !_expenses.any((e) => e.id == expense.id)) {
      _expenses = previous;
      _notify();
    }
    return error;
  }

  /// Re-creates a just-deleted expense with its original id (undo).
  Future<String?> restoreExpense(Expense expense) {
    return _run((uid) => _repository.addExpense(uid, expense));
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

    _subscription = _repository
        .watchExpenses(
          uid: uid,
          start: _selectedMonth,
          end: DateTime(_selectedMonth.year, _selectedMonth.month + 1),
        )
        .listen(
          (expenses) {
            _expenses = List.unmodifiable(expenses);
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

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
