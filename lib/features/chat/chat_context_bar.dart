import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
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

  Color getStatusColor(AppColors colors) {
    if (fraction > 0.88) {
      return colors.error;
    } else if (fraction > 0.70) {
      return colors.warning;
    } else {
      return colors.success;
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
    final colors = context.appColors;
    final usage = ref.watch(conversationContextUsageProvider(widget.conversationId));
    final statusColor = usage.getStatusColor(colors);

    final tooltipMessage = 'Context Window Utilization:\n'
        '• Used: ${usage.usedTokens} tokens (${usage.percentage}%)\n'
        '• Prompt: ~${usage.promptTokens} tok | Response: ~${usage.responseTokens} tok\n'
        '• Headroom: ${usage.remainingTokens} tokens available\n'
        '• Limit: ${usage.maxTokens} tokens (num_ctx)\n\n'
        'Click to tune context limit in Parameters';

    return Tooltip(
      message: tooltipMessage,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final current = ref.read(showParamsPanelProvider);
            ref.read(showParamsPanelProvider.notifier).state = !current;
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered ? colors.surfaceHover : colors.surface,
                borderRadius: AppRadius.r8,
                border: Border.all(
                  color: _isHovered ? colors.accent : colors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Indicator Dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Micro Progress Bar
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: AppMotion.fast,
                      curve: AppMotion.curve,
                      widthFactor: usage.fraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Monospace Token Counter
                  Text(
                    '${usage.formatK(usage.usedTokens)}/${usage.formatK(usage.maxTokens)}',
                    style: AppTypography.code(
                      size: 12,
                      weight: FontWeight.w500,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${usage.percentage}%)',
                    style: AppTypography.code(
                      size: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
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
    final colors = context.appColors;
    final usage = ref.watch(conversationContextUsageProvider(conversationId));
    final statusColor = usage.getStatusColor(colors);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        borderRadius: AppRadius.r12,
        border: Border.all(
          color: colors.border,
          width: 1,
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
                    style: AppTypography.code(
                      size: 12,
                      weight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '${usage.percentage}% full',
                style: AppTypography.code(
                  size: 12,
                  weight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Full width progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedFractionallySizedBox(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
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
                style: AppTypography.ui(
                  size: 12,
                  color: colors.textMuted,
                ),
              ),
              Text(
                'Remaining: ${usage.remainingTokens} tok',
                style: AppTypography.code(
                  size: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
