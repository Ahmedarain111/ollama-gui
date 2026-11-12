import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/status_dot.dart';

/// Clean navigation rail that smoothly expands to reveal text labels
/// when hovered over, maintaining a minimal footprint by default.
class AppNavRail extends ConsumerStatefulWidget {
  const AppNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  ConsumerState<AppNavRail> createState() => _AppNavRailState();
}

class _AppNavRailState extends ConsumerState<AppNavRail> {
  bool _isRailHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);

    final isExpanded = _isRailHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isRailHovered = true),
      onExit: (_) => setState(() => _isRailHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: isExpanded ? 168 : 56,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: theme.dividerTheme.color ?? colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),

            // Top Mark & Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: isExpanded
                  ? Row(
                      children: [
                        _buildAppMark(colorScheme),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ollama GUI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                      ],
                    )
                  : Center(child: _buildAppMark(colorScheme)),
            ),

            const SizedBox(height: 18),

            // Nav Items with icons that reveal text when hovered
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              selectedIcon: Icons.chat_bubble_rounded,
              label: 'Chat',
              isSelected: widget.selectedIndex == 0,
              isExpanded: isExpanded,
              onTap: () => widget.onDestinationSelected(0),
            ),
            const SizedBox(height: 4),
            _NavItem(
              icon: Icons.layers_outlined,
              selectedIcon: Icons.layers_rounded,
              label: 'Models',
              isSelected: widget.selectedIndex == 1,
              isExpanded: isExpanded,
              onTap: () => widget.onDestinationSelected(1),
            ),
            const SizedBox(height: 4),
            _NavItem(
              icon: Icons.code_rounded,
              selectedIcon: Icons.code_rounded,
              label: 'Modelfile',
              isSelected: widget.selectedIndex == 2,
              isExpanded: isExpanded,
              onTap: () => widget.onDestinationSelected(2),
            ),
            const SizedBox(height: 4),
            _NavItem(
              icon: Icons.tune_rounded,
              selectedIcon: Icons.tune_rounded,
              label: 'Settings',
              isSelected: widget.selectedIndex == 3,
              isExpanded: isExpanded,
              onTap: () => widget.onDestinationSelected(3),
            ),

            const Spacer(),

            // Connection status at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                mouseCursor: SystemMouseCursors.click,
                hoverColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                onTap: () => context.go('/settings'),
                child: Container(
                  height: 34,
                  padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10 : 0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: isExpanded
                      ? Row(
                          children: [
                            _buildStatusDot(connectionStatus),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                connectionStatus.when(
                                  data: (ok) =>
                                      ok ? 'Ollama running' : 'Disconnected',
                                  loading: () => 'Connecting...',
                                  error: (_, __) => 'Offline',
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.85),
                                ),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        )
                      : Center(child: _buildStatusDot(connectionStatus)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppMark(ColorScheme colorScheme) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.25),
            colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.terminal_rounded,
        size: 15,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildStatusDot(AsyncValue<bool> connectionStatus) {
    return connectionStatus.when(
      data: (ok) => StatusDot(
        status: ok ? ConnectionStatus.connected : ConnectionStatus.disconnected,
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
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _itemHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = widget.isSelected;
    final isHovered = _itemHovered;

    final iconColor = isActive
        ? colorScheme.onSurface
        : isHovered
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

    final textColor = isActive
        ? colorScheme.onSurface
        : isHovered
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

    final bgColor = isActive
        ? colorScheme.surfaceContainerHighest
        : isHovered
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
            : Colors.transparent;

    return Tooltip(
      message: widget.isExpanded ? '' : widget.label,
      waitDuration: const Duration(milliseconds: 800),
      child: MouseRegion(
        onEnter: (_) => setState(() => _itemHovered = true),
        onExit: (_) => setState(() => _itemHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 10 : 0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.8),
                      width: 0.8,
                    )
                  : (isHovered
                      ? Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                          width: 0.8,
                        )
                      : null),
            ),
            child: widget.isExpanded
                ? Row(
                    children: [
                      Icon(
                        isActive ? widget.selectedIcon : widget.icon,
                        size: 19,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: textColor,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      isActive ? widget.selectedIcon : widget.icon,
                      size: 19,
                      color: iconColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
