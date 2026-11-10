import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_controller.dart';
import 'chat_input_bar.dart';
import 'chat_message_list.dart';
import 'chat_providers.dart';
import 'chat_toolbar.dart';

/// The active chat area showing toolbar, messages, and input.
class ChatArea extends ConsumerWidget {
  const ChatArea({super.key, required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(chatControllerProvider(conversationId));

    return Column(
      children: [
        // Toolbar
        ChatToolbar(conversationId: conversationId),
        const Divider(height: 1),
        // Message list
        Expanded(
          child: ChatMessageList(conversationId: conversationId),
        ),
        // Input bar
        ChatInputBar(
          onSend: (text) async {
            final model = ref.read(selectedModelProvider);
            await controller.sendMessage(text, model);
          },
          onStop: controller.cancelStream,
        ),
      ],
    );
  }
}
