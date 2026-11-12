import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import 'chat_media_helper.dart';
import 'chat_providers.dart';

/// Represents token utilization metrics for the active conversation's context window.
class ContextUsage {
  const ContextUsage({
    required this.usedTokens,
    required this.maxTokens,
    required this.promptTokens,
    required this.responseTokens,
  });

  final int usedTokens;
  final int maxTokens;
  final int promptTokens;
  final int responseTokens;

  double get fraction => maxTokens > 0 ? (usedTokens / maxTokens).clamp(0.0, 1.0) : 0.0;
  int get percentage => (fraction * 100).round();
  int get remainingTokens => max(0, maxTokens - usedTokens);

  Color getStatusColor(ColorScheme colorScheme) {
    if (fraction > 0.88) {
      return const Color(0xFFEF4444); // Red/Coral alert
    } else if (fraction > 0.70) {
      return const Color(0xFFF59E0B); // Amber warning
    } else {
      return const Color(0xFF10B981); // Emerald safe
    }
  }

  String formatK(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).toStringAsFixed(1)}k';
    }
    return '$tokens';
  }
}

/// Provider calculating context window token usage for a given conversation.
final conversationContextUsageProvider =
    Provider.family<ContextUsage, int>((ref, convId) {
  final convAsync = ref.watch(conversationsStreamProvider);
  final messagesAsync = ref.watch(messagesStreamProvider(convId));
  final isStreaming = ref.watch(isStreamingProvider);
  final stats = ref.watch(streamingStatsProvider);

  final conv = convAsync.when(
    data: (list) => list.where((c) => c.id == convId).firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );

  int maxTokens = 4096; // Standard default context window in Ollama
  if (conv?.paramPreset != null && conv!.paramPreset!.isNotEmpty) {
    try {
      final json = jsonDecode(conv.paramPreset!) as Map<String, dynamic>;
      if (json['num_ctx'] is num) {
        maxTokens = (json['num_ctx'] as num).toInt();
      }
    } catch (_) {}
  }

  int promptTokens = 0;
  int responseTokens = 0;

  // Add system prompt if present
  if (conv?.systemPrompt != null && conv!.systemPrompt!.trim().isNotEmpty) {
    promptTokens += (conv.systemPrompt!.trim().length / 3.8).ceil();
  }

  final messages = messagesAsync.when(
    data: (list) => list,
    loading: () => <Message>[],
    error: (_, __) => <Message>[],
  );

  for (final m in messages) {
    if (m.role == 'assistant') {
      if (m.totalTokens != null && m.totalTokens! > 0) {
        responseTokens += m.totalTokens!;
      } else {
        responseTokens += (m.content.length / 3.8).ceil();
      }
    } else {
      final parsed = parseMessageContent(m.content);
      promptTokens += (parsed.text.length / 3.8).ceil();
      if (parsed.images != null && parsed.images!.isNotEmpty) {
        promptTokens += parsed.images!.length * 768; // Vision patch tokens
      }
    }
  }

  // If currently streaming, factor in in-flight tokens
  if (isStreaming && stats != null) {
    responseTokens += stats.totalTokens;
  }

  final totalUsed = promptTokens + responseTokens;

  return ContextUsage(
    usedTokens: totalUsed,
    maxTokens: maxTokens,
    promptTokens: promptTokens,
    responseTokens: responseTokens,
  );
});

/// A compact, interactive context window meter designed for the top chat toolbar.
class ChatContextBar extends ConsumerStatefulWidget {
  const ChatContextBar({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatContextBar> createState() => _ChatContextBarState();
}

class _ChatContextBarState extends ConsumerState<ChatContextBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usage = ref.watch(conversationContextUsageProvider(widget.conversationId));
    final statusColor = usage.getStatusColor(colorScheme);

    final tooltipMessage = 'Context Window Utilization:\n'
        '• Used: ${usage.usedTokens} tokens (${usage.percentage}%)\n'
        '• Prompt: ~${usage.promptTokens} tok | Response: ~${usage.responseTokens} tok\n'
        '• Headroom: ${usage.remainingTokens} tokens available\n'
        '• Limit: ${usage.maxTokens} tokens (num_ctx)\n\n'
        'Click to tune context limit in Parameters';

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final current = ref.read(showParamsPanelProvider);
            ref.read(showParamsPanelProvider.notifier).state = !current;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isHovered
                    ? statusColor.withValues(alpha: 0.6)
                    : colorScheme.outline.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Indicator Dot or Icon
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),

                // Micro Progress Bar
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    widthFactor: usage.fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Monospace Token Counter
                Text(
                  '${usage.formatK(usage.usedTokens)}/${usage.formatK(usage.maxTokens)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${usage.percentage}%)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A detailed context gauge card for the parameters drawer.
class DrawerContextGauge extends ConsumerWidget {
  const DrawerContextGauge({super.key, required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usage = ref.watch(conversationContextUsageProvider(conversationId));
    final statusColor = usage.getStatusColor(colorScheme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    'CONTEXT USAGE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${usage.percentage}% full',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Full width progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                widthFactor: usage.fraction,
                alignment: Alignment.centerLeft,
                child: Container(
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: ${usage.usedTokens} tokens',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Remaining: ${usage.remainingTokens} tok',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
