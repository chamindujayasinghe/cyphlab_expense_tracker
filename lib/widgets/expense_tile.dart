import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../utils/formatters.dart';

/// Colored circle with the category icon.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.radius = 22});

  final ExpenseCategory category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: category.color.withValues(alpha: 0.15),
      child: Icon(category.icon, color: category.color, size: radius),
    );
  }
}

/// One expense row. Tap to edit; swipe left to delete (after confirmation).
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onTap,
    required this.confirmDelete,
    required this.onDeleted,
  });

  final Expense expense;
  final VoidCallback onTap;

  /// Asks the user to confirm; the tile is only removed if this returns true.
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = expense.note;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(),
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CategoryAvatar(category: expense.category),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          note == null
              ? expense.category.label
              : '${expense.category.label} · $note',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Large amounts or big system text would otherwise push the title
        // out of the row, so the amount shrinks to fit instead.
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.35,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              Formatters.currency(expense.amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
