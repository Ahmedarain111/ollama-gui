import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/status_dot.dart';

/// Custom NavigationRail with app logo, main destinations, and connection dot.
class AppNavRail extends ConsumerWidget {
  const AppNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);

    return Container(
      width: 72,
      color: colorScheme.surfaceContainer,
      child: Column(
        children: [
          // App icon / logo
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Icon(
              Icons.auto_awesome,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          // Navigation destinations
          Expanded(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.none,
              useIndicator: true,
              indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
              backgroundColor: Colors.transparent,
              minWidth: 72,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: Text('Chat'),
                  padding: EdgeInsets.symmetric(vertical: 4),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage_rounded),
                  label: Text('Models'),
                  padding: EdgeInsets.symmetric(vertical: 4),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit_note_outlined),
                  selectedIcon: Icon(Icons.edit_note),
                  label: Text('Modelfile'),
                  padding: EdgeInsets.symmetric(vertical: 4),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Settings'),
                  padding: EdgeInsets.symmetric(vertical: 4),
                ),
              ],
            ),
          ),
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Tooltip(
              message: connectionStatus.when(
                data: (ok) => ok ? 'Ollama connected' : 'Ollama not reachable',
                loading: () => 'Checking connection…',
                error: (_, __) => 'Connection error',
              ),
              child: GestureDetector(
                onTap: () => context.go('/settings'),
                child: connectionStatus.when(
                  data: (ok) => StatusDot(
                    status: ok
                        ? ConnectionStatus.connected
                        : ConnectionStatus.disconnected,
                  ),
                  loading: () =>
                      const StatusDot(status: ConnectionStatus.loading),
                  error: (_, __) =>
                      const StatusDot(status: ConnectionStatus.disconnected),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
