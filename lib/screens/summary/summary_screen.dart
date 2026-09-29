import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../services/expense_repository.dart' show ExpenseRepositoryException;
import '../../utils/expense_stats.dart';
import '../../utils/formatters.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/state_views.dart';

/// Spending breakdown for the period shown on the home screen, plus a
/// six-month trend.
///
/// The category breakdown uses the whole period (ignoring the home screen's
/// category and search filters), so it matches the unfiltered month total.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final rangeStart = provider.rangeStart;
    final rangeEnd = provider.rangeEnd;
    final periodLabel = rangeStart != null && rangeEnd != null
        ? Formatters.dateRange(rangeStart, rangeEnd)
        : Formatters.monthYear(provider.selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionCard(
                  title: 'Spending by category',
                  subtitle: periodLabel,
                  child: const _CategoryBreakdown(),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Last 6 months',
                  subtitle:
                      'Up to ${Formatters.monthYear(provider.selectedMonth)}',
                  child: const _MonthlyTrend(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatefulWidget {
  const _CategoryBreakdown();

  @override
  State<_CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<_CategoryBreakdown> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);

    if (provider.isLoading && provider.expenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.hasError) {
      return ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.retry,
      );
    }

    final totals = ExpenseStats.byCategory(provider.expenses);
    if (totals.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'Nothing to show yet',
        message: 'Add expenses to see where your money goes.',
      );
    }

    final grandTotal = totals.fold(0.0, (sum, t) => sum + t.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 62,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      setState(() {
                        _touchedIndex =
                            event.isInterestedForInteractions &&
                                index != null &&
                                index >= 0
                            ? index
                            : null;
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < totals.length; i++)
                      PieChartSectionData(
                        value: totals[i].total,
                        color: totals[i].category.color,
                        radius: i == _touchedIndex ? 52 : 44,
                        // Hide labels on thin slices so they don't overlap.
                        title: totals[i].share >= 0.08
                            ? Formatters.percent(totals[i].share)
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Formatters.currency(grandTotal),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final total in totals) _CategoryRow(total: total),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.total});

  final CategoryTotal total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = total.category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CategoryAvatar(category: total.category, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        total.category.label,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      Formatters.currency(total.total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total.share,
                          minHeight: 6,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        Formatters.percent(total.share),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrend extends StatefulWidget {
  const _MonthlyTrend();

  @override
  State<_MonthlyTrend> createState() => _MonthlyTrendState();
}

class _MonthlyTrendState extends State<_MonthlyTrend> {
  Stream<List<MonthTotal>>? _stream;
  DateTime? _month;

  void _retry() {
    setState(() {
      _stream = context.read<ExpenseProvider>().watchMonthlyTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This tab stays alive in the shell, so re-query whenever the selected
    // month changes on the Expenses tab.
    final month = context.select<ExpenseProvider, DateTime>(
      (provider) => provider.selectedMonth,
    );
    if (month != _month || _stream == null) {
      _month = month;
      _stream = context.read<ExpenseProvider>().watchMonthlyTotals();
    }

    return StreamBuilder<List<MonthTotal>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ErrorState(
            message: error is ExpenseRepositoryException
                ? error.message
                : 'Please try again.',
            onRetry: _retry,
          );
        }
        final months = snapshot.data;
        if (months == null) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _TrendChart(months: months);
      },
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.months});

  /// Oldest first; the last entry is the selected month.
  final List<MonthTotal> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxTotal = months.fold(0.0, (m, t) => t.total > m ? t.total : m);
    final sum = months.fold(0.0, (s, t) => s + t.total);

    if (maxTotal == 0) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No spending yet',
        message: 'Your monthly totals will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxTotal * 1.15,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxTotal * 1.15 / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          Formatters.shortMonth(months[index].month),
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        '${Formatters.monthYear(months[groupIndex].month)}\n'
                        '${Formatters.currency(rod.toY)}',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: months[i].total,
                        width: 22,
                        color: i == months.length - 1
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Average ${Formatters.currency(sum / months.length)} per month',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
