import '../models/expense.dart';
import '../models/expense_category.dart';

/// Total spent in one category, with its share of the overall total.
class CategoryTotal {
  const CategoryTotal(this.category, this.total, this.share);

  final ExpenseCategory category;
  final double total;

  /// Fraction of the overall total, 0..1.
  final double share;
}

/// Total spent in one calendar month.
class MonthTotal {
  const MonthTotal(this.month, this.total);

  final DateTime month;
  final double total;
}

/// Aggregations for the summary screen.
class ExpenseStats {
  ExpenseStats._();

  /// Per-category totals, largest first.
  static List<CategoryTotal> byCategory(List<Expense> expenses) {
    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final grandTotal = totals.values.fold(0.0, (sum, total) => sum + total);
    if (grandTotal == 0) return const [];

    return totals.entries
        .map(
          (entry) =>
              CategoryTotal(entry.key, entry.value, entry.value / grandTotal),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Totals for [count] months from [firstMonth], zero-filled.
  static List<MonthTotal> byMonth(
    List<Expense> expenses, {
    required DateTime firstMonth,
    required int count,
  }) {
    final totals = List<double>.filled(count, 0);
    for (final expense in expenses) {
      final index =
          (expense.date.year - firstMonth.year) * 12 +
          expense.date.month -
          firstMonth.month;
      if (index >= 0 && index < count) totals[index] += expense.amount;
    }
    return [
      for (var i = 0; i < count; i++)
        MonthTotal(DateTime(firstMonth.year, firstMonth.month + i), totals[i]),
    ];
  }
}
