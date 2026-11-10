import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'nav_rail.dart';

/// Persistent shell wrapping all screens with the navigation rail.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForLocation(location);

    return Scaffold(
      body: Row(
        children: [
          AppNavRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _navigate(context, index),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith('/models')) return 1;
    if (location.startsWith('/modelfile')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // /chat
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/chat');
      case 1:
        context.go('/models');
      case 2:
        context.go('/modelfile');
      case 3:
        context.go('/settings');
    }
  }
}
