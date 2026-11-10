import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/hover_icon_button.dart';
import 'chat_providers.dart';

/// Minimal, centered input bar for drafting messages (max-width 780px).
class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onStop,
  });

  final Future<void> Function(String text) onSend;
  final VoidCallback onStop;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isStreaming = ref.watch(isStreamingProvider);
    final stats = ref.watch(streamingStatsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streaming status
              if (isStreaming && stats != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generating · ${stats.tokensPerSec.toStringAsFixed(1)} tok/s (${stats.totalTokens} tokens)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Container
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                child: Column(
                  children: [
                    KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          if (!isStreaming && _canSend) {
                            _handleSend();
                          }
                        }
                      },
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 7,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                        decoration: InputDecoration(
                          hintText: isStreaming
                              ? 'Model is replying...'
                              : 'Ask $selectedModel...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            fontSize: 13.5,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom Controls Row
                    Row(
                      children: [
                        Text(
                          '↵ send · ⇧↵ newline',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),

                        const Spacer(),

                        if (isStreaming)
                          _StopButton(onTap: widget.onStop)
                        else
                          HoverIconButton(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Send',
                            iconSize: 16,
                            enabled: _canSend,
                            color: _canSend
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            hoverColor: colorScheme.onPrimary,
                            textColor: colorScheme.onPrimary,
                            backgroundColor: _canSend
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            hoverBackgroundColor: _canSend
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            borderRadius: 6,
                            tooltip: 'Send (↵)',
                            onTap: _handleSend,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatefulWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.error.withValues(alpha: 0.22)
                : colorScheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? colorScheme.error.withValues(alpha: 0.75)
                  : colorScheme.error.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stop_rounded, size: 14, color: colorScheme.error),
              const SizedBox(width: 4),
              Text(
                'Stop',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

