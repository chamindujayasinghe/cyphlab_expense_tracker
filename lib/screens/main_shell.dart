import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'summary/summary_screen.dart';

/// Signed-in tabs: bottom bar on phones, side rail on wide screens.
/// Tabs stay alive in an IndexedStack and are built on first visit.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

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
    (
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
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
    return switch (index) {
      0 => const HomeScreen(),
      1 => const SummaryScreen(),
      _ => const SettingsScreen(),
    };
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
