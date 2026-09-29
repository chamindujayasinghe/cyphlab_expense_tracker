import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Highlighted card showing the month's total spend and expense count.
class TotalCard extends StatelessWidget {
  const TotalCard({
    super.key,
    required this.label,
    required this.total,
    required this.count,
    this.isLoading = false,
  });

  final String label;
  final double total;
  final int count;
  final bool isLoading;

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
              isLoading
                  ? 'Loading…'
                  : '$count ${count == 1 ? 'expense' : 'expenses'}',
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
