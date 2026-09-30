import 'package:intl/intl.dart';

import 'constants.dart';

/// Display formatting for amounts and dates.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );
  static final DateFormat _date = DateFormat.yMMMd();
  static final DateFormat _monthYear = DateFormat.yMMMM();

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime date) => _date.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String shortMonth(DateTime date) => DateFormat.MMM().format(date);

  static String percent(double share) => '${(share * 100).round()}%';

  /// `Sep 1 – 15, 2026`, `Aug 28 – Sep 3, 2026` or `Dec 30, 2025 – Jan 2, 2026`.
  static String dateRange(DateTime start, DateTime end) {
    if (start.year != end.year) return '${date(start)} – ${date(end)}';
    if (start.month != end.month) {
      return '${DateFormat.MMMd().format(start)} – ${date(end)}';
    }
    if (start.day == end.day) return date(start);
    return '${DateFormat.MMMd().format(start)} – ${end.day}, ${end.year}';
  }

  /// `Today`, `Yesterday` or the date, for list headers.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final difference = today.difference(_dateOnly(date)).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return Formatters.date(date);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
