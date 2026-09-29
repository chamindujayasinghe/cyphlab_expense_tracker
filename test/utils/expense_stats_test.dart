import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/models/expense.dart';
import 'package:cyphlab_expense_tracker/models/expense_category.dart';
import 'package:cyphlab_expense_tracker/utils/expense_stats.dart';

Expense _expense(double amount, ExpenseCategory category, DateTime date) =>
    Expense(
      id: '$amount$category$date',
      title: 't',
      amount: amount,
      category: category,
      date: date,
    );

void main() {
  group('ExpenseStats.byCategory', () {
    test('sums per category, sorted largest first, with shares', () {
      final totals = ExpenseStats.byCategory([
        _expense(100, ExpenseCategory.food, DateTime(2026, 9, 1)),
        _expense(300, ExpenseCategory.bills, DateTime(2026, 9, 2)),
        _expense(100, ExpenseCategory.food, DateTime(2026, 9, 3)),
      ]);

      expect(totals.map((t) => t.category), [
        ExpenseCategory.bills,
        ExpenseCategory.food,
      ]);
      expect(totals.map((t) => t.total), [300, 200]);
      expect(totals.map((t) => t.share), [0.6, 0.4]);
    });

    test('returns an empty list for no expenses', () {
      expect(ExpenseStats.byCategory([]), isEmpty);
    });
  });

  group('ExpenseStats.byMonth', () {
    test('zero-fills months and ignores dates outside the range', () {
      final months = ExpenseStats.byMonth(
        [
          _expense(50, ExpenseCategory.food, DateTime(2025, 11, 30)),
          _expense(100, ExpenseCategory.food, DateTime(2025, 12, 5)),
          _expense(40, ExpenseCategory.food, DateTime(2026, 2, 1)),
          _expense(60, ExpenseCategory.food, DateTime(2026, 2, 28)),
          _expense(99, ExpenseCategory.food, DateTime(2026, 3, 1)),
        ],
        firstMonth: DateTime(2025, 12),
        count: 3,
      );

      expect(months.map((m) => m.month), [
        DateTime(2025, 12),
        DateTime(2026, 1),
        DateTime(2026, 2),
      ]);
      expect(months.map((m) => m.total), [100, 0, 100]);
    });
  });
}
