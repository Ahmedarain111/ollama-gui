import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_controller.dart';
import 'chat_input_bar.dart';
import 'chat_message_list.dart';
import 'chat_params_drawer.dart';
import 'chat_providers.dart';
import 'chat_toolbar.dart';

/// The active chat area showing toolbar, messages, input, and optional parameters side panel.
class ChatArea extends ConsumerWidget {
  const ChatArea({super.key, required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(chatControllerProvider(conversationId));
    final showParams = ref.watch(showParamsPanelProvider);

    return Row(
      children: [
        // Main conversation view
        Expanded(
          child: Column(
            children: [
              // Toolbar
              ChatToolbar(conversationId: conversationId),
              // Message list
              Expanded(
                child: ChatMessageList(conversationId: conversationId),
              ),
              // Input bar with vision/image support
              ChatInputBar(
                onSend: (text, images) async {
                  final model = ref.read(selectedModelProvider);
                  await controller.sendMessage(text, model, images: images);
                },
                onStop: controller.cancelStream,
              ),
            ],
          ),
        ),

        // Smoothly animated slide-over drawer for inference parameters & system prompt
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            child: showParams
                ? ChatParamsDrawer(
                    conversationId: conversationId,
                    onClose: () {
                      ref.read(showParamsPanelProvider.notifier).state = false;
                    },
                  )
                : const SizedBox(width: 0, height: double.infinity),
          ),
        ),
      ],
    );
  }
}
