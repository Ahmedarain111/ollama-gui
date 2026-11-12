import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A compact, styled badge for displaying model metadata such as quantization or parameter size.
class ModelBadge extends StatelessWidget {
  const ModelBadge({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCustomColor = color != null;
    final badgeColor = color ?? colors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCustomColor ? badgeColor.withValues(alpha: 0.12) : colors.surfaceHover,
        borderRadius: AppRadius.r6,
        border: Border.all(
          color: isCustomColor ? badgeColor.withValues(alpha: 0.4) : colors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.code(
          size: 12,
          weight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }
}
