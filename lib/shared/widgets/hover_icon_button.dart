import 'package:flutter/material.dart';

import '../../core/theme.dart';

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
    this.borderRadius = AppRadius.k8,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final baseColor = widget.color ?? colors.textMuted;
    final activeHoverColor = widget.hoverColor ?? colors.text;
    final fgColor = widget.enabled
        ? ((_isHovered || _isFocused) ? activeHoverColor : baseColor)
        : baseColor.withValues(alpha: 0.4);

    final bg = widget.backgroundColor ?? Colors.transparent;
    final hoverBg = widget.hoverBackgroundColor ?? colors.surfaceHover;
    final activeBg = widget.enabled && (_isHovered || _isFocused) ? hoverBg : bg;

    final Border border;
    if (_isFocused && widget.enabled) {
      border = Border.all(color: colors.accent, width: 2);
    } else if (widget.borderColor != null) {
      border = Border.all(color: widget.borderColor!, width: 1);
    } else if (_isHovered && widget.enabled) {
      border = Border.all(color: colors.border, width: 1);
    } else {
      border = Border.all(color: Colors.transparent, width: 1);
    }

    final resolvedTextColor = widget.enabled
        ? ((_isHovered || _isFocused)
            ? (widget.hoverTextColor ?? widget.textColor ?? activeHoverColor)
            : (widget.textColor ?? baseColor))
        : baseColor.withValues(alpha: 0.4);

    Widget button = FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.enabled) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: border,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: fgColor,
                  ),
                  ClipRect(
                    child: AnimatedSize(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      alignment: Alignment.centerLeft,
                      child: (_isHovered || _isFocused) && widget.enabled
                          ? Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                widget.label,
                                style: AppTypography.ui(
                                  size: widget.fontSize,
                                  weight: FontWeight.w500,
                                  color: resolvedTextColor,
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
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
