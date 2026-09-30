import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

/// Search field plus date-range and category filter chips.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.controller,
    required this.onClearAll,
  });

  final TextEditingController controller;
  final VoidCallback onClearAll;

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final now = DateTime.now();
    final start = provider.rangeStart;
    final end = provider.rangeEnd;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: start != null && end != null
          ? DateTimeRange(start: start, end: end)
          : null,
      helpText: 'Filter by date',
    );
    if (picked == null) return;
    provider.setDateRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final rangeStart = provider.rangeStart;
    final rangeEnd = provider.rangeEnd;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search title or note',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: controller.clear,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              if (provider.hasAnyFilter)
                ActionChip(
                  avatar: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear'),
                  onPressed: onClearAll,
                ),
              if (rangeStart != null && rangeEnd != null)
                InputChip(
                  selected: true,
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(Formatters.dateRange(rangeStart, rangeEnd)),
                  onPressed: () => _pickDateRange(context),
                  onDeleted: provider.clearDateRange,
                  deleteButtonTooltipMessage: 'Clear date range',
                )
              else
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: const Text('Date range'),
                  onPressed: () => _pickDateRange(context),
                ),
              for (final category in ExpenseCategory.values)
                FilterChip(
                  avatar: provider.selectedCategories.contains(category)
                      ? null
                      : Icon(category.icon, size: 18, color: category.color),
                  label: Text(category.label),
                  selected: provider.selectedCategories.contains(category),
                  selectedColor: colorScheme.secondaryContainer,
                  onSelected: (_) => provider.toggleCategory(category),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
