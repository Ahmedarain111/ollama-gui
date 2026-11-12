import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/system_usage.dart';
import '../../core/theme.dart';
import '../widgets/hover_icon_button.dart';

/// Minimalist top-bar system resource monitor displaying CPU, GPU, RAM, and VRAM.
class SystemUsageBar extends ConsumerWidget {
  const SystemUsageBar({super.key});

  Future<void> _unloadModels(BuildContext context, WidgetRef ref, List<String> models) async {
    try {
      final client = ref.read(ollamaClientProvider);
      for (final model in models) {
        await client.unloadModel(model);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unloaded ${models.join(", ")} from VRAM'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Color _getStatusColor(AppColors colors, double percent) {
    if (percent > 85) return colors.error;
    if (percent > 70) return colors.warning;
    return colors.text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final usageAsync = ref.watch(systemUsageStreamProvider);

    final usage = usageAsync.when(
      data: (u) => u,
      loading: () => const SystemUsage.initial(),
      error: (_, __) => const SystemUsage.initial(),
    );

    final cpuColor = _getStatusColor(colors, usage.cpuPercent);
    final ramColor = _getStatusColor(colors, usage.ramPercent);
    final gpuColor = usage.gpuPercent != null
        ? _getStatusColor(colors, usage.gpuPercent!)
        : colors.text;
    final vramPercent = usage.vramTotalGb != null && usage.vramTotalGb! > 0
        ? (usage.vramUsedGb / usage.vramTotalGb!) * 100
        : 0.0;
    final vramColor = _getStatusColor(colors, vramPercent);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CPU
        _MetricBadge(
          icon: Icons.developer_board_rounded,
          valueColor: cpuColor,
          label: 'CPU',
          value: '${usage.cpuPercent.toStringAsFixed(0)}%',
          tooltip: 'CPU Usage: ${usage.cpuPercent.toStringAsFixed(1)}%',
        ),

        const SizedBox(width: AppSpacing.xs),

        // GPU
        _MetricBadge(
          icon: Icons.speed_rounded,
          valueColor: gpuColor,
          label: 'GPU',
          value: usage.gpuPercent != null
              ? '${usage.gpuPercent!.toStringAsFixed(0)}%'
              : '0%',
          tooltip: usage.gpuPercent != null
              ? 'GPU Usage: ${usage.gpuPercent!.toStringAsFixed(1)}% (${usage.gpuName ?? "Graphics"})'
              : 'GPU: ${usage.gpuName ?? "Idle"}',
        ),

        const SizedBox(width: AppSpacing.xs),

        // RAM
        _MetricBadge(
          icon: Icons.memory_rounded,
          valueColor: ramColor,
          label: 'RAM',
          value: usage.ramTotalGb > 0
              ? '${usage.ramUsedGb.toStringAsFixed(1)}G'
              : '0G',
          tooltip: usage.ramTotalGb > 0
              ? 'RAM Usage: ${usage.ramUsedGb.toStringAsFixed(1)} / ${usage.ramTotalGb.toStringAsFixed(1)} GB (${usage.ramPercent.toStringAsFixed(0)}%)'
              : 'RAM Usage',
        ),

        const SizedBox(width: AppSpacing.xs),

        // VRAM
        _MetricBadge(
          icon: Icons.grain_rounded,
          valueColor: vramColor,
          label: 'VRAM',
          value: usage.vramUsedGb > 0
              ? '${usage.vramUsedGb.toStringAsFixed(1)}G'
              : '0G',
          tooltip: usage.vramTotalGb != null
              ? 'VRAM: ${usage.vramUsedGb.toStringAsFixed(1)} / ${usage.vramTotalGb!.toStringAsFixed(1)} GB'
              : usage.loadedModels.isNotEmpty
                  ? 'VRAM: ${usage.vramUsedGb.toStringAsFixed(1)} GB (Ollama: ${usage.loadedModels.join(", ")})'
                  : 'VRAM: No models currently loaded in memory',
        ),

        // Quick Unload VRAM button if models are active
        if (usage.loadedModels.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          HoverIconButton(
            icon: Icons.eject_rounded,
            label: 'Eject',
            iconSize: 13,
            tooltip: 'Unload ${usage.loadedModels.join(", ")} from VRAM',
            color: colors.textMuted,
            hoverColor: colors.error,
            hoverBackgroundColor: colors.error.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            borderRadius: AppRadius.chip,
            onTap: () => _unloadModels(context, ref, usage.loadedModels),
          ),
        ],
      ],
    );
  }
}

class _MetricBadge extends StatefulWidget {
  const _MetricBadge({
    required this.icon,
    required this.valueColor,
    required this.label,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final Color valueColor;
  final String label;
  final String value;
  final String tooltip;

  @override
  State<_MetricBadge> createState() => _MetricBadgeState();
}

class _MetricBadgeState extends State<_MetricBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAlert = widget.valueColor == colors.error || widget.valueColor == colors.warning;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceHover : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: isAlert
                  ? widget.valueColor.withValues(alpha: 0.5)
                  : (_hovered ? colors.border : colors.border.withValues(alpha: 0.6)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 12,
                color: isAlert ? widget.valueColor : colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: AppTypography.code(
                  size: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.value,
                style: AppTypography.code(
                  size: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
