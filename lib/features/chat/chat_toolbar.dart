import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import 'chat_providers.dart';

/// Compact, minimal top toolbar for active chat (44px).
class ChatToolbar extends ConsumerStatefulWidget {
  const ChatToolbar({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<ChatToolbar> createState() => _ChatToolbarState();
}

class _ChatToolbarState extends ConsumerState<ChatToolbar> {
  bool _editingTitle = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final convAsync = ref.watch(conversationsStreamProvider);
    final modelsAsync = ref.watch(installedModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    final conv = convAsync.when(
      data: (list) =>
          list.where((c) => c.id == widget.conversationId).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    if (conv != null && !_editingTitle) {
      _titleController.text = conv.title;
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          // Editable Conversation Title
          Expanded(
            child: _editingTitle
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    ),
                    onSubmitted: (newTitle) async {
                      if (newTitle.trim().isNotEmpty) {
                        await ref
                            .read(appDatabaseProvider)
                            .updateConversationTitle(
                              widget.conversationId,
                              newTitle.trim(),
                            );
                      }
                      setState(() => _editingTitle = false);
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => setState(() => _editingTitle = true),
                    child: Text(
                      conv?.title ?? 'Conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Sleek Model Selector
          modelsAsync.when(
            data: (models) {
              if (models.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: models.any((m) => m.name == selectedModel)
                        ? selectedModel
                        : models.first.name,
                    isDense: true,
                    icon: Icon(
                      Icons.unfold_more_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    items: models.map((m) {
                      return DropdownMenuItem(
                        value: m.name,
                        child: Text(m.name),
                      );
                    }).toList(),
                    onChanged: (newModel) {
                      if (newModel != null) {
                        ref.read(selectedModelProvider.notifier).state = newModel;
                      }
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(width: 6),

          // Actions Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Actions',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onSelected: (val) {
              if (val == 'rename') {
                setState(() => _editingTitle = true);
              } else if (val == 'clear') {
                _clearMessages(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                height: 32,
                child: Text('Rename chat', style: TextStyle(fontSize: 12.5)),
              ),
              const PopupMenuItem(
                value: 'clear',
                height: 32,
                child: Text('Clear history', style: TextStyle(fontSize: 12.5, color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clearMessages(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'All messages in this session will be deleted.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(appDatabaseProvider).deleteMessagesForConversation(widget.conversationId);
    }
  }
}
