import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_area.dart';
import 'chat_providers.dart';
import 'conversation_sidebar.dart';

/// Main chat screen: conversation sidebar + active chat area.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialConversationId});

  final int? initialConversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialConversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeConversationProvider.notifier).state =
            widget.initialConversationId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConvId = ref.watch(activeConversationProvider);

    return Row(
      children: [
        // Conversation sidebar — fixed 240px
        const SizedBox(
          width: 240,
          child: ConversationSidebar(),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        // Active chat area
        Expanded(
          child: activeConvId == null
              ? _WelcomeCard()
              : ChatArea(conversationId: activeConvId),
        ),
      ],
    );
  }
}

/// Shown when no conversation is selected.
class _WelcomeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Ollama GUI',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your local AI, beautifully presented',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Chat'),
                  onPressed: () =>
                      _showNewChatDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _NewChatDialog(),
    );
  }
}

class _NewChatDialog extends ConsumerWidget {
  const _NewChatDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Delegate to the sidebar's new chat dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      // Trigger new chat from provider
      ref.read(newChatTriggerProvider.notifier).state++;
    });
    return const SizedBox.shrink();
  }
}
