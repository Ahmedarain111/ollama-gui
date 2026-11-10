import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import 'chat_providers.dart';

/// Top toolbar: conversation title, model selector, overflow menu.
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          // Editable conversation title
          Expanded(
            child: _editingTitle
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _saveTitle(value),
                    onEditingComplete: () =>
                        _saveTitle(_titleController.text),
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editingTitle = true),
                    child: Text(
                      conv?.title ?? 'Chat',
                      style:
                          Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Model selector dropdown
          modelsAsync.when(
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (models) {
              if (models.isEmpty) return const SizedBox.shrink();
              final val = models.any((m) => m.name == selectedModel)
                  ? selectedModel
                  : models.first.name;
              return DropdownButton<String>(
                value: val,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(10),
                items: models
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.name,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_outlined,
                                size: 16),
                            const SizedBox(width: 6),
                            Text(m.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(selectedModelProvider.notifier).state =
                        v;
                  }
                },
              );
            },
          ),
          const SizedBox(width: 4),
          // Overflow menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download_outlined),
                  title: Text('Export as Markdown'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep_outlined),
                  title: Text('Clear messages'),
                  dense: true,
                ),
              ),
            ],
            onSelected: (action) => _handleMenuAction(action),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTitle(String value) async {
    if (value.trim().isNotEmpty) {
      await ref
          .read(appDatabaseProvider)
          .updateConversationTitle(widget.conversationId, value.trim());
    }
    setState(() => _editingTitle = false);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showSnackbar('Export coming soon');
      case 'clear':
        _showSnackbar('Clear messages coming soon');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
