import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/status_dot.dart';
import '../../shared/widgets/system_usage_bar.dart';

/// App-wide persistent top status bar housing the active view title,
/// connection status, and real-time CPU, GPU, RAM, and VRAM monitors.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  String _getTitleForRoute(String path) {
    if (path.startsWith('/models')) return 'Models & Library';
    if (path.startsWith('/modelfile')) return 'Modelfile Studio';
    if (path.startsWith('/settings')) return 'Preferences';
    return 'Chat Workspace';
  }

  IconData _getIconForRoute(String path) {
    if (path.startsWith('/models')) return Icons.layers_outlined;
    if (path.startsWith('/modelfile')) return Icons.code_rounded;
    if (path.startsWith('/settings')) return Icons.tune_rounded;
    return Icons.chat_bubble_outline_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final path = GoRouterState.of(context).uri.path;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);
    final baseUrl = ref.watch(ollamaBaseUrlProvider);

    final title = _getTitleForRoute(path);
    final icon = _getIconForRoute(path);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Current route icon and title
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(width: 8),

          // Ollama connection indicator
          connectionStatus.when(
            data: (ok) => Tooltip(
              message: ok
                  ? 'Ollama online at $baseUrl'
                  : 'Cannot reach Ollama at $baseUrl',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusDot(status: ok ? ConnectionStatus.connected : ConnectionStatus.disconnected, size: 7),
                  const SizedBox(width: 5),
                  Text(
                    ok ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: ok
                          ? const Color(0xFF10B981)
                          : colorScheme.error.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusDot(status: ConnectionStatus.loading, size: 7),
                SizedBox(width: 5),
                Text(
                  'Connecting',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ],
            ),
            error: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusDot(status: ConnectionStatus.disconnected, size: 7),
                const SizedBox(width: 5),
                Text(
                  'Offline',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // System Resource Monitors (CPU, GPU, RAM, VRAM)
          const SystemUsageBar(),
        ],
      ),
    );
  }
}
