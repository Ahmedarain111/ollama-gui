import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../shared/widgets/status_dot.dart';

/// Clean navigation rail that smoothly expands to reveal text labels
/// when hovered over, maintaining anchored icon positions and seamless transitions.
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

class _AppNavRailState extends ConsumerState<AppNavRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _widthAnimation;
  late final Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _widthAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );

    _textOpacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final width = Tween<double>(begin: 56.0, end: 172.0).evaluate(_widthAnimation);
          final textOpacity = _textOpacityAnimation.value.clamp(0.0, 1.0);
          final isExpanded = _controller.value > 0.5;

          return ClipRect(
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: colors.bgSidebar,
                border: Border(
                  right: BorderSide(
                    color: colors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),

                  // Top Mark & Title (Mark is anchored at center of 56px width)
                  SizedBox(
                    height: 32,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 14,
                          top: 2,
                          bottom: 2,
                          width: 28,
                          child: _buildAppMark(colors),
                        ),
                        if (textOpacity > 0)
                          Positioned(
                            left: 52,
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Opacity(
                                opacity: textOpacity,
                                child: Text(
                                  'Ollama GUI',
                                  style: AppTypography.ui(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: colors.text,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Nav Items with anchored icon positions and smoothly revealed text
                  _NavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    isSelected: widget.selectedIndex == 0,
                    textOpacity: textOpacity,
                    showTooltip: !isExpanded,
                    onTap: () => widget.onDestinationSelected(0),
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.layers_outlined,
                    selectedIcon: Icons.layers_rounded,
                    label: 'Models',
                    isSelected: widget.selectedIndex == 1,
                    textOpacity: textOpacity,
                    showTooltip: !isExpanded,
                    onTap: () => widget.onDestinationSelected(1),
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.code_rounded,
                    selectedIcon: Icons.code_rounded,
                    label: 'Modelfile',
                    isSelected: widget.selectedIndex == 2,
                    textOpacity: textOpacity,
                    showTooltip: !isExpanded,
                    onTap: () => widget.onDestinationSelected(2),
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.tune_rounded,
                    selectedIcon: Icons.tune_rounded,
                    label: 'Settings',
                    isSelected: widget.selectedIndex == 3,
                    textOpacity: textOpacity,
                    showTooltip: !isExpanded,
                    onTap: () => widget.onDestinationSelected(3),
                  ),

                  const Spacer(),

                  // Connection status at bottom
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: colors.surfaceHover,
                      onTap: () => context.go('/settings'),
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          border: Border.all(
                            color: colors.border,
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 38,
                              child: Center(
                                child: _buildStatusDot(connectionStatus),
                              ),
                            ),
                            if (textOpacity > 0)
                              Positioned(
                                left: 36,
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Opacity(
                                    opacity: textOpacity,
                                    child: Text(
                                      connectionStatus.when(
                                        data: (ok) =>
                                            ok ? 'Ollama running' : 'Disconnected',
                                        loading: () => 'Connecting...',
                                        error: (_, __) => 'Offline',
                                      ),
                                      style: AppTypography.code(
                                        size: 11,
                                        weight: FontWeight.w500,
                                        color: colors.textMuted,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppMark(AppColors colors) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.terminal_rounded,
        size: 16,
        color: colors.accent,
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
    required this.textOpacity,
    required this.showTooltip,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final double textOpacity;
  final bool showTooltip;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _itemHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final isActive = widget.isSelected;
    final isHovered = _itemHovered;

    final iconColor = isActive
        ? colors.accent
        : isHovered
            ? colors.text
            : colors.textMuted;

    final textColor = isActive
        ? colors.text
        : isHovered
            ? colors.text
            : colors.textMuted;

    final bgColor = isActive
        ? colors.surfaceHover
        : isHovered
            ? colors.surfaceHover.withValues(alpha: 0.6)
            : Colors.transparent;

    Widget itemContent = MouseRegion(
      onEnter: (_) => setState(() => _itemHovered = true),
      onExit: (_) => setState(() => _itemHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isActive
                  ? colors.accent.withValues(alpha: 0.35)
                  : (isHovered ? colors.border : Colors.transparent),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              if (isActive)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 38,
                child: Center(
                  child: Icon(
                    isActive ? widget.selectedIcon : widget.icon,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ),
              if (widget.textOpacity > 0)
                Positioned(
                  left: 38,
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: widget.textOpacity,
                      child: Text(
                        widget.label,
                        style: AppTypography.ui(
                          size: 13,
                          weight: isActive ? FontWeight.w500 : FontWeight.w400,
                          color: textColor,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.showTooltip) {
      return Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 500),
        child: itemContent,
      );
    }

    return itemContent;
  }
}
