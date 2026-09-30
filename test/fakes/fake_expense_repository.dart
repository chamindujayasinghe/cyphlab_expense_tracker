import 'dart:async';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/services/expense_repository.dart';

/// Records calls and lets tests push list updates or errors to watchers.
class FakeExpenseRepository implements ExpenseRepository {
  StreamController<List<Expense>>? _controller;

  ({String uid, DateTime start, DateTime end})? lastWatch;
  int watchCount = 0;

  final List<String> calls = [];
  String? errorMessage;

  void emit(List<Expense> expenses) => _controller!.add(expenses);

  void emitError(Object error) => _controller!.addError(error);

  bool get hasListener => _controller?.hasListener ?? false;

  @override
  Stream<List<Expense>> watchExpenses({
    required String uid,
    required DateTime start,
    required DateTime end,
  }) {
    watchCount++;
    lastWatch = (uid: uid, start: start, end: end);
    _controller = StreamController<List<Expense>>();
    return _controller!.stream;
  }

  @override
  Future<String> addExpense(String uid, Expense expense) async {
    await _record('add:$uid:${expense.id}:${expense.title}');
    return expense.id.isEmpty ? 'new-id' : expense.id;
  }

  @override
  Future<void> updateExpense(String uid, Expense expense) =>
      _record('update:$uid:${expense.id}');

  @override
  Future<void> deleteExpense(String uid, String expenseId) =>
      _record('delete:$uid:$expenseId');

  Future<void> _record(String call) async {
    calls.add(call);
    final message = errorMessage;
    if (message != null) throw ExpenseRepositoryException(message);
  }
}
