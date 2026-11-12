import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../settings/settings_providers.dart';
import 'chat_message_bubble.dart';
import 'chat_providers.dart';

/// Scrollable list of chat messages that auto-scrolls to the bottom.
class ChatMessageList extends ConsumerStatefulWidget {
  const ChatMessageList({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatMessageList> createState() =>
      _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<ChatMessageList> {
  final _scrollController = ScrollController();
  int _prevMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool smooth = false}) {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;
    // Don't auto-scroll if user scrolled up to read earlier history
    final isNearBottom = pos.maxScrollExtent - pos.pixels <= 180;
    if (!isNearBottom && !smooth) return;

    final target = pos.maxScrollExtent;
    if (smooth) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      // Rapid micro-glide during token generation prevents animation cancel stutter
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 60),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.conversationId));
    final isStreaming = ref.watch(isStreamingProvider);
    final autoScroll = ref.watch(settingsNotifierProvider).autoScroll;

    return messagesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error loading messages: $e')),
      data: (messages) {
        // Auto-scroll when messages arrive or during streaming
        if (messages.length != _prevMessageCount) {
          final isNewMessage = messages.length > _prevMessageCount;
          _prevMessageCount = messages.length;
          if (autoScroll || isNewMessage) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(smooth: isNewMessage),
            );
          }
        } else if (isStreaming && autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(smooth: false),
          );
        }

        if (messages.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_outlined,
            title: 'No messages yet',
            subtitle: 'Send a message to start the conversation',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (ctx, i) {
            final msg = messages[i];
            final isLast = i == messages.length - 1;
            return ChatMessageBubble(
              message: msg,
              isStreaming: isStreaming && isLast && msg.role == 'assistant',
            );
          },
        );
      },
    );
  }
}
