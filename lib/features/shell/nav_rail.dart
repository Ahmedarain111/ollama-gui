import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/status_dot.dart';

/// Ultra-clean, slender navigation rail (54px).
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);

    return Container(
      width: 54,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerTheme.color ?? colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          // App Mark
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'O',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nav Items
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            isSelected: selectedIndex == 0,
            tooltip: 'Chat',
            onTap: () => onDestinationSelected(0),
          ),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.layers_outlined,
            selectedIcon: Icons.layers_rounded,
            isSelected: selectedIndex == 1,
            tooltip: 'Models',
            onTap: () => onDestinationSelected(1),
          ),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.code_rounded,
            selectedIcon: Icons.code_rounded,
            isSelected: selectedIndex == 2,
            tooltip: 'Modelfile',
            onTap: () => onDestinationSelected(2),
          ),
          const SizedBox(height: 6),
          _NavItem(
            icon: Icons.tune_rounded,
            selectedIcon: Icons.tune_rounded,
            isSelected: selectedIndex == 3,
            tooltip: 'Settings',
            onTap: () => onDestinationSelected(3),
          ),

          const Spacer(),

          // Connection status pill at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Tooltip(
              message: connectionStatus.when(
                data: (ok) => ok ? 'Ollama running' : 'Ollama disconnected',
                loading: () => 'Connecting to Ollama...',
                error: (_, __) => 'Connection failed',
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.go('/settings'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: connectionStatus.when(
                    data: (ok) => StatusDot(
                      status: ok
                          ? ConnectionStatus.connected
                          : ConnectionStatus.disconnected,
                      size: 8,
                    ),
                    loading: () => const StatusDot(
                      status: ConnectionStatus.loading,
                      size: 8,
                    ),
                    error: (_, __) => const StatusDot(
                      status: ConnectionStatus.disconnected,
                      size: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = widget.isSelected;
    final iconColor = isActive
        ? colorScheme.onSurface
        : _hovered
            ? colorScheme.onSurface.withValues(alpha: 0.85)
            : colorScheme.onSurfaceVariant;

    final bgColor = isActive
        ? colorScheme.surfaceContainerHighest
        : _hovered
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.8),
                      width: 0.8,
                    )
                  : null,
            ),
            child: Icon(
              isActive ? widget.selectedIcon : widget.icon,
              size: 19,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
