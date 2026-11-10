import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/system_usage.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usageAsync = ref.watch(systemUsageStreamProvider);

    final usage = usageAsync.when(
      data: (u) => u,
      loading: () => const SystemUsage.initial(),
      error: (_, __) => const SystemUsage.initial(),
    );

    final cpuColor = usage.cpuPercent > 85
        ? colorScheme.error
        : usage.cpuPercent > 65
            ? const Color(0xFFF59E0B)
            : const Color(0xFF0EA5E9);

    final ramColor = usage.ramPercent > 85
        ? colorScheme.error
        : usage.ramPercent > 70
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    const gpuColor = Color(0xFF8B5CF6);
    const vramColor = Color(0xFFF59E0B);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // CPU
        _MetricBadge(
          icon: Icons.developer_board_rounded,
          accentColor: cpuColor,
          label: 'CPU',
          value: '${usage.cpuPercent.toStringAsFixed(0)}%',
          tooltip: 'CPU Usage: ${usage.cpuPercent.toStringAsFixed(1)}%',
        ),

        const SizedBox(width: 4),

        // GPU
        _MetricBadge(
          icon: Icons.speed_rounded,
          accentColor: gpuColor,
          label: 'GPU',
          value: usage.gpuPercent != null
              ? '${usage.gpuPercent!.toStringAsFixed(0)}%'
              : '0%',
          tooltip: usage.gpuPercent != null
              ? 'GPU Usage: ${usage.gpuPercent!.toStringAsFixed(1)}% (${usage.gpuName ?? "Graphics"})'
              : 'GPU: ${usage.gpuName ?? "Idle"}',
        ),

        const SizedBox(width: 4),

        // RAM
        _MetricBadge(
          icon: Icons.memory_rounded,
          accentColor: ramColor,
          label: 'RAM',
          value: usage.ramTotalGb > 0
              ? '${usage.ramUsedGb.toStringAsFixed(1)}G'
              : '0G',
          tooltip: usage.ramTotalGb > 0
              ? 'RAM Usage: ${usage.ramUsedGb.toStringAsFixed(1)} / ${usage.ramTotalGb.toStringAsFixed(1)} GB (${usage.ramPercent.toStringAsFixed(0)}%)'
              : 'RAM Usage',
        ),

        const SizedBox(width: 4),

        // VRAM
        _MetricBadge(
          icon: Icons.grain_rounded,
          accentColor: vramColor,
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
          const SizedBox(width: 3),
          HoverIconButton(
            icon: Icons.eject_rounded,
            label: 'Eject',
            iconSize: 13,
            tooltip: 'Unload ${usage.loadedModels.join(", ")} from VRAM',
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
    required this.accentColor,
    required this.label,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final Color accentColor;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 11.5,
                color: widget.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
