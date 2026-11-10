import 'package:flutter/material.dart';

/// An interactive button that shows an icon by default, and smoothly
/// expands to display its label text alongside the icon when hovered over.
class HoverIconButton extends StatefulWidget {
  const HoverIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 16,
    this.fontSize = 12,
    this.color,
    this.hoverColor,
    this.textColor,
    this.hoverTextColor,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.borderColor,
    this.borderRadius = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final Color? color;
  final Color? hoverColor;
  final Color? textColor;
  final Color? hoverTextColor;
  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final bool enabled;

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseColor = widget.color ?? colorScheme.onSurfaceVariant;
    final activeHoverColor = widget.hoverColor ?? colorScheme.onSurface;
    final fgColor = widget.enabled
        ? (_isHovered ? activeHoverColor : baseColor)
        : baseColor.withValues(alpha: 0.35);

    final bg = widget.backgroundColor ?? Colors.transparent;
    final hoverBg = widget.hoverBackgroundColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final activeBg = widget.enabled && _isHovered ? hoverBg : bg;

    final border = widget.borderColor != null
        ? Border.all(
            color: _isHovered
                ? widget.borderColor!
                : widget.borderColor!.withValues(alpha: 0.5),
            width: 0.8,
          )
        : null;

    final resolvedTextColor = widget.enabled
        ? (_isHovered
            ? (widget.hoverTextColor ?? widget.textColor ?? activeHoverColor)
            : (widget.textColor ?? baseColor))
        : baseColor.withValues(alpha: 0.35);

    Widget button = MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _isHovered = false);
      },
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.iconSize,
                color: fgColor,
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: _isHovered && widget.enabled
                      ? Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w500,
                              color: resolvedTextColor,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        waitDuration: Duration.zero,
        child: button,
      );
    }

    return button;
  }
}
