import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.conversationId));
    final isStreaming = ref.watch(isStreamingProvider);

    return messagesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error loading messages: $e')),
      data: (messages) {
        // Auto-scroll when messages arrive during streaming
        if (messages.length != _prevMessageCount || isStreaming) {
          _prevMessageCount = messages.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
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
