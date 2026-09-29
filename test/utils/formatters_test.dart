import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/utils/formatters.dart';

void main() {
  test('currency formats with symbol, separators and 2 decimals', () {
    expect(Formatters.currency(1250.5), 'LKR 1,250.50');
  });

  test('monthYear', () {
    expect(Formatters.monthYear(DateTime(2026, 9, 29)), 'September 2026');
  });

  test('dateRange shortens shared month and year', () {
    expect(
      Formatters.dateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 15)),
      'Sep 1 – 15, 2026',
    );
    expect(
      Formatters.dateRange(DateTime(2026, 8, 28), DateTime(2026, 9, 3)),
      'Aug 28 – Sep 3, 2026',
    );
    expect(
      Formatters.dateRange(DateTime(2025, 12, 30), DateTime(2026, 1, 2)),
      'Dec 30, 2025 – Jan 2, 2026',
    );
    expect(
      Formatters.dateRange(DateTime(2026, 9, 5), DateTime(2026, 9, 5)),
      'Sep 5, 2026',
    );
  });

  test('relativeDay returns Today, Yesterday, or a date', () {
    final now = DateTime(2026, 9, 29, 9);

    expect(
      Formatters.relativeDay(DateTime(2026, 9, 29, 23), now: now),
      'Today',
    );
    expect(
      Formatters.relativeDay(DateTime(2026, 9, 28, 1), now: now),
      'Yesterday',
    );
    expect(
      Formatters.relativeDay(DateTime(2026, 9, 20), now: now),
      'Sep 20, 2026',
    );
  });
}
