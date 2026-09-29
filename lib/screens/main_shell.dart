import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'summary/summary_screen.dart';

/// Signed-in shell with labeled Expenses / Summary destinations: a bottom
/// navigation bar on phones and a side rail on wide screens.
///
/// Tabs are kept alive in an [IndexedStack] so switching back preserves
/// state such as the search text. Each tab is only built once first visited,
/// so the summary's extra query doesn't run until it's opened.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Width at which the bottom bar is replaced by a navigation rail.
  static const double railBreakpoint = 840;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  static const _destinations = [
    (
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    (
      label: 'Summary',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
    ),
  ];

  void _select(int index) {
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return index == 0 ? const HomeScreen() : const SummaryScreen();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = IndexedStack(
      index: _index,
      children: [for (var i = 0; i < _destinations.length; i++) _buildTab(i)],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= MainShell.railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: tabs),
              ],
            ),
          );
        }

        return Scaffold(
          body: tabs,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}
