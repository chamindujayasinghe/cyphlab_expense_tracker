import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';

void main() {
  final expense = Expense(
    id: 'abc123',
    title: 'Lunch',
    amount: 1250.5,
    category: ExpenseCategory.food,
    date: DateTime(2026, 9, 29, 13, 30),
    note: 'With the team',
  );

  group('Expense', () {
    test('toMap and fromMap round-trip', () {
      final restored = Expense.fromMap(expense.id, expense.toMap());

      expect(restored, expense);
    });

    test('toMap stores category by name and date as Timestamp', () {
      final map = expense.toMap();

      expect(map['category'], 'food');
      expect(map['date'], isA<Timestamp>());
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('fromMap converts int amounts and reads server timestamps', () {
      final created = DateTime(2026, 9, 1);
      final restored = Expense.fromMap('id', {
        'title': 'Bus',
        'amount': 100,
        'category': 'transport',
        'date': Timestamp.fromDate(DateTime(2026, 9, 2)),
        'createdAt': Timestamp.fromDate(created),
      });

      expect(restored.amount, 100.0);
      expect(restored.category, ExpenseCategory.transport);
      expect(restored.createdAt, created);
      expect(restored.note, isNull);
    });

    test('fromMap treats a blank note as null', () {
      final restored = Expense.fromMap('id', {
        ...expense.toMap(),
        'note': '  ',
      });

      expect(restored.note, isNull);
    });

    test('fromMap falls back to Other for an unknown category', () {
      final restored = Expense.fromMap('id', {
        ...expense.toMap(),
        'category': 'travel',
      });

      expect(restored.category, ExpenseCategory.other);
    });

    test('copyWith updates fields and can clear the note', () {
      final updated = expense.copyWith(amount: 99, title: 'Dinner');
      final cleared = expense.copyWith(clearNote: true);

      expect(updated.amount, 99);
      expect(updated.title, 'Dinner');
      expect(updated.id, expense.id);
      expect(updated.note, expense.note);
      expect(cleared.note, isNull);
    });
  });
}
