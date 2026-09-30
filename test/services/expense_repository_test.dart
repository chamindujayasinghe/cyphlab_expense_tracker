import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/services/expense_repository.dart';

/// Tests the real Firestore repository against an in-memory Firestore.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreExpenseRepository repository;

  CollectionReference<Map<String, dynamic>> expensesOf(String uid) =>
      firestore.collection('users').doc(uid).collection('expenses');

  Expense expense(
    String title,
    DateTime date, {
    String id = '',
    String? note,
  }) => Expense(
    id: id,
    title: title,
    amount: 100,
    category: ExpenseCategory.food,
    date: date,
    note: note,
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreExpenseRepository(firestore: firestore);
  });

  test(
    'addExpense stores fields under the user with server timestamps',
    () async {
      final id = await repository.addExpense(
        'user-1',
        expense('Lunch', DateTime(2026, 9, 12), note: 'Team'),
      );

      final doc = await expensesOf('user-1').doc(id).get();
      final data = doc.data()!;
      expect(data['title'], 'Lunch');
      expect(data['amount'], 100);
      expect(data['category'], 'food');
      expect(data['note'], 'Team');
      expect((data['date'] as Timestamp).toDate(), DateTime(2026, 9, 12));
      expect(data['createdAt'], isA<Timestamp>());
      expect(data['updatedAt'], isA<Timestamp>());
    },
  );

  test('addExpense reuses an existing id (used for undo)', () async {
    final id = await repository.addExpense(
      'user-1',
      expense('Restored', DateTime(2026, 9, 1), id: 'abc'),
    );

    expect(id, 'abc');
    expect((await expensesOf('user-1').doc('abc').get()).exists, isTrue);
  });

  test('watchExpenses returns the range newest first, end exclusive', () async {
    for (final e in [
      expense('Aug 31', DateTime(2026, 8, 31, 23)),
      expense('Sep 1', DateTime(2026, 9, 1)),
      expense('Sep 20', DateTime(2026, 9, 20)),
      expense('Oct 1', DateTime(2026, 10, 1)),
    ]) {
      await repository.addExpense('user-1', e);
    }

    final list = await repository
        .watchExpenses(
          uid: 'user-1',
          start: DateTime(2026, 9),
          end: DateTime(2026, 10),
        )
        .first;

    expect(list.map((e) => e.title), ['Sep 20', 'Sep 1']);
    expect(list.every((e) => e.id.isNotEmpty), isTrue);
  });

  test("watchExpenses only returns the given user's expenses", () async {
    await repository.addExpense(
      'user-1',
      expense('Mine', DateTime(2026, 9, 5)),
    );
    await repository.addExpense(
      'user-2',
      expense('Theirs', DateTime(2026, 9, 5)),
    );

    final list = await repository
        .watchExpenses(
          uid: 'user-1',
          start: DateTime(2026, 9),
          end: DateTime(2026, 10),
        )
        .first;

    expect(list.map((e) => e.title), ['Mine']);
  });

  test(
    'updateExpense changes fields, clears the note, keeps createdAt',
    () async {
      final id = await repository.addExpense(
        'user-1',
        expense('Lunch', DateTime(2026, 9, 12), note: 'Team'),
      );
      final createdAt = (await expensesOf('user-1').doc(id).get())['createdAt'];

      await repository.updateExpense(
        'user-1',
        Expense(
          id: id,
          title: 'Dinner',
          amount: 250.5,
          category: ExpenseCategory.entertainment,
          date: DateTime(2026, 9, 13),
        ),
      );

      final data = (await expensesOf('user-1').doc(id).get()).data()!;
      expect(data['title'], 'Dinner');
      expect(data['amount'], 250.5);
      expect(data['category'], 'entertainment');
      expect(data['note'], isNull);
      expect(data['createdAt'], createdAt);
    },
  );

  test('deleteExpense removes the document', () async {
    final id = await repository.addExpense(
      'user-1',
      expense('Lunch', DateTime(2026, 9, 12)),
    );

    await repository.deleteExpense('user-1', id);

    expect((await expensesOf('user-1').doc(id).get()).exists, isFalse);
  });

  test('updating a missing expense throws a friendly exception', () async {
    expect(
      () => repository.updateExpense(
        'user-1',
        expense('Ghost', DateTime(2026, 9, 1), id: 'missing'),
      ),
      throwsA(isA<ExpenseRepositoryException>()),
    );
  });

  test('messageForCode maps Firestore error codes', () {
    expect(
      FirestoreExpenseRepository.messageForCode('permission-denied'),
      "You don't have permission to access these expenses.",
    );
    expect(
      FirestoreExpenseRepository.messageForCode('unavailable'),
      "Can't reach the server. Check your connection and try again.",
    );
    expect(
      FirestoreExpenseRepository.messageForCode('something-else'),
      'Something went wrong. Please try again.',
    );
  });
}
