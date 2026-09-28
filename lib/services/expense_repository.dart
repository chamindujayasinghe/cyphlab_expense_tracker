import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

/// Thrown by [ExpenseRepository] with a message that is safe to show.
class ExpenseRepositoryException implements Exception {
  const ExpenseRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ExpenseRepositoryException: $message';
}

/// Storage for a user's expenses. Abstract so providers can be tested with
/// an in-memory fake.
abstract class ExpenseRepository {
  /// Live list of expenses with `start <= date < end`, newest first.
  Stream<List<Expense>> watchExpenses({
    required String uid,
    required DateTime start,
    required DateTime end,
  });

  /// Saves a new expense and returns its id. If [Expense.id] is set it is
  /// reused, which lets a deleted expense be restored (undo).
  Future<String> addExpense(String uid, Expense expense);

  Future<void> updateExpense(String uid, Expense expense);

  Future<void> deleteExpense(String uid, String expenseId);
}

/// [ExpenseRepository] backed by Cloud Firestore at
/// `users/{uid}/expenses/{expenseId}`.
class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _expenses(String uid) =>
      _firestore.collection('users').doc(uid).collection('expenses');

  @override
  Stream<List<Expense>> watchExpenses({
    required String uid,
    required DateTime start,
    required DateTime end,
  }) {
    // Range filter and ordering on the same field need no composite index.
    return _expenses(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList())
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(_mapError(error), stackTrace),
          ),
        );
  }

  @override
  Future<String> addExpense(String uid, Expense expense) async {
    final collection = _expenses(uid);
    final doc = expense.id.isEmpty
        ? collection.doc()
        : collection.doc(expense.id);
    await _guard(
      () => doc.set({
        ...expense.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    return doc.id;
  }

  @override
  Future<void> updateExpense(String uid, Expense expense) {
    return _guard(
      () => _expenses(uid).doc(expense.id).update({
        ...expense.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> deleteExpense(String uid, String expenseId) {
    return _guard(() => _expenses(uid).doc(expenseId).delete());
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      throw _mapError(error);
    }
  }

  static ExpenseRepositoryException _mapError(Object error) {
    if (error is ExpenseRepositoryException) return error;
    if (error is FirebaseException) {
      return ExpenseRepositoryException(messageForCode(error.code));
    }
    return const ExpenseRepositoryException(
      'Something went wrong. Please try again.',
    );
  }

  /// Maps Firestore error codes to user-facing messages.
  static String messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return "You don't have permission to access these expenses.";
      case 'unavailable':
        return "Can't reach the server. Check your connection and try again.";
      case 'not-found':
        return 'This expense no longer exists.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
