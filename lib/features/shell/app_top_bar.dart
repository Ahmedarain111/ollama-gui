import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../shared/widgets/status_dot.dart';
import '../../shared/widgets/system_usage_bar.dart';
import '../settings/settings_providers.dart';

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
    final colors = context.appColors;
    final path = GoRouterState.of(context).uri.path;
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);
    final baseUrl = ref.watch(ollamaBaseUrlProvider);

    final title = _getTitleForRoute(path);
    final icon = _getIconForRoute(path);
    final showSystemUsage = ref.watch(settingsNotifierProvider).showSystemUsageBar;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Current route icon and title
          Icon(
            icon,
            size: 15,
            color: colors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.ui(
              size: 13,
              weight: FontWeight.w600,
              letterSpacing: -0.1,
              color: colors.text,
            ),
          ),

          const SizedBox(width: 12),

          // Ollama connection indicator
          connectionStatus.when(
            data: (ok) => Tooltip(
              message: ok
                  ? 'Ollama online at $baseUrl'
                  : 'Cannot reach Ollama at $baseUrl',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusDot(
                    status: ok ? ConnectionStatus.connected : ConnectionStatus.disconnected,
                    size: 7,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    ok ? 'Online' : 'Offline',
                    style: AppTypography.code(
                      size: 11,
                      weight: FontWeight.w500,
                      color: ok ? colors.success : colors.error,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusDot(status: ConnectionStatus.loading, size: 7),
                const SizedBox(width: 5),
                Text(
                  'Connecting',
                  style: AppTypography.code(
                    size: 11,
                    weight: FontWeight.w500,
                    color: colors.warning,
                  ),
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
                  style: AppTypography.code(
                    size: 11,
                    weight: FontWeight.w500,
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ),

          if (showSystemUsage) ...[
            const Spacer(),
            const SystemUsageBar(),
          ],
        ],
      ),
    );
  }
}
