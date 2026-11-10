import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/hover_icon_button.dart';
import 'chat_providers.dart';

/// Minimalist, high-density conversation sidebar (220px).
class ConversationSidebar extends ConsumerStatefulWidget {
  const ConversationSidebar({super.key});

  @override
  ConsumerState<ConversationSidebar> createState() =>
      _ConversationSidebarState();
}

class _ConversationSidebarState extends ConsumerState<ConversationSidebar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(newChatTriggerProvider, (prev, next) {
        if (next > 0) _showNewChatDialog();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final convAsync = ref.watch(conversationsStreamProvider);
    final activeId = ref.watch(activeConversationProvider);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerTheme.color ?? colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // New Chat Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _showNewChatDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'New chat',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      'Ctrl N',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: convAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading chats',
                  style: TextStyle(fontSize: 11, color: colorScheme.error),
                ),
              ),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversations',
                    subtitle: 'Press "New chat" to begin.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  itemCount: conversations.length,
                  itemBuilder: (ctx, i) {
                    final conv = conversations[i];
                    return _ConversationRow(
                      conversation: conv,
                      isSelected: conv.id == activeId,
                      onTap: () {
                        ref.read(activeConversationProvider.notifier).state = conv.id;
                        context.go('/chat?id=${conv.id}');
                      },
                      onDelete: () => _deleteConversation(conv),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _NewChatDialog(
        onCreated: (convId) {
          ref.read(activeConversationProvider.notifier).state = convId;
          context.go('/chat?id=$convId');
        },
      ),
    );
  }

  Future<void> _deleteConversation(Conversation conv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          'Delete "${conv.title}" and its messages permanently.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(appDatabaseProvider).deleteConversation(conv.id);
      if (ref.read(activeConversationProvider) == conv.id) {
        ref.read(activeConversationProvider.notifier).state = null;
      }
    }
  }
}

class _ConversationRow extends StatefulWidget {
  const _ConversationRow({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<_ConversationRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = widget.isSelected;
    final rowBg = isActive
        ? colorScheme.surfaceContainerHighest
        : _hovered
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.transparent;

    final shortModel = widget.conversation.model.split(':').first;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  )
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          shortModel,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${_relativeTime(widget.conversation.updatedAt)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_hovered || isActive)
                HoverIconButton(
                  icon: Icons.close_rounded,
                  label: 'Delete',
                  iconSize: 13,
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  hoverColor: colorScheme.error,
                  hoverBackgroundColor: colorScheme.error.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  borderRadius: 4,
                  onTap: widget.onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.MMMd().format(dt);
  }
}

class _NewChatDialog extends ConsumerStatefulWidget {
  const _NewChatDialog({required this.onCreated});

  final ValueChanged<int> onCreated;

  @override
  ConsumerState<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<_NewChatDialog> {
  final _titleController = TextEditingController(text: 'New Chat');
  String? _selectedModel;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(installedModelsProvider);

    return AlertDialog(
      title: const Text('New Conversation'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Conversation Title',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Model',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            modelsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(fontSize: 12)),
              data: (models) {
                if (models.isEmpty) {
                  return const Text(
                    'No models installed. Go to Models tab to pull one.',
                    style: TextStyle(fontSize: 12),
                  );
                }
                _selectedModel ??= models.first.name;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedModel,
                  style: const TextStyle(fontSize: 13),
                  items: models
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.name,
                          child: Text(m.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedModel = v),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedModel == null ? null : _create,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final id = await db.insertConversation(
      ConversationsCompanion(
        title: Value(_titleController.text.trim().isEmpty
            ? 'New Chat'
            : _titleController.text.trim()),
        model: Value(_selectedModel!),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onCreated(id);
    }
  }
}
