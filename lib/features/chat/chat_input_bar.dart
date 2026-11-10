import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';

/// The bottom input bar for typing and sending messages or stopping generation.
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
    final colorScheme = Theme.of(context).colorScheme;
    final isStreaming = ref.watch(isStreamingProvider);
    final stats = ref.watch(streamingStatsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Streaming stats indicator bar
          if (isStreaming && stats != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generating: ${stats.tokensPerSec.toStringAsFixed(1)} tok/s · ${stats.totalTokens} tokens',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message text input
              Expanded(
                child: KeyboardListener(
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
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isStreaming
                          ? 'Model is replying...'
                          : 'Message Ollama (Enter to send, Shift+Enter for new line)...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Action button: Stop or Send
              if (isStreaming)
                IconButton.filled(
                  icon: const Icon(Icons.stop_rounded),
                  tooltip: 'Stop generation',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: widget.onStop,
                )
              else
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward_rounded),
                  tooltip: 'Send message',
                  style: IconButton.styleFrom(
                    backgroundColor: _canSend
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: _canSend
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: _canSend ? _handleSend : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
