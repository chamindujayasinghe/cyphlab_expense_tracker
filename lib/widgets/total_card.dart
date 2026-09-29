import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Highlighted card showing the total spend and expense count for the period.
class TotalCard extends StatelessWidget {
  const TotalCard({
    super.key,
    required this.label,
    required this.total,
    required this.count,
    this.totalCount,
    this.isLoading = false,
  });

  final String label;
  final double total;

  /// Number of expenses included in [total].
  final int count;

  /// Number of expenses before filtering; shown as "3 of 10" when different.
  final int? totalCount;
  final bool isLoading;

  String get _countText {
    final noun = (totalCount ?? count) == 1 ? 'expense' : 'expenses';
    final all = totalCount;
    if (all != null && all != count) return '$count of $all $noun';
    return '$count $noun';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onPrimaryContainer;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: onColor),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                isLoading ? '—' : Formatters.currency(total),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: onColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading ? 'Loading…' : _countText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
