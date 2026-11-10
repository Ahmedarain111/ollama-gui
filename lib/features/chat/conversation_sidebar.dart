import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;

import '../../database/database.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import 'chat_providers.dart';

/// Left sidebar showing the list of conversations.
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
    // Listen for new chat triggers from the welcome card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(newChatTriggerProvider, (prev, next) {
        if (next > 0) _showNewChatDialog();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final convAsync = ref.watch(conversationsStreamProvider);
    final activeId = ref.watch(activeConversationProvider);

    return Column(
      children: [
        // Header
        _SidebarHeader(onNewChat: _showNewChatDialog),
        const Divider(height: 1),
        // Conversation list
        Expanded(
          child: convAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e')),
            data: (conversations) {
              if (conversations.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations yet',
                  subtitle: 'Start a new chat!',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                itemBuilder: (ctx, i) {
                  final conv = conversations[i];
                  return _ConversationTile(
                    conversation: conv,
                    isSelected: conv.id == activeId,
                    onTap: () {
                      ref.read(activeConversationProvider.notifier).state =
                          conv.id;
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
            'This will permanently delete "${conv.title}" and all its messages.'),
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

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'Chats',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: onNewChat,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({
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
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onSecondaryTapUp: (_) => widget.onDelete(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : _hovered
                    ? colorScheme.onSurface.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              widget.conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: widget.isSelected
                    ? colorScheme.primary
                    : null,
              ),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    _relativeTime(widget.conversation.updatedAt),
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.conversation.model.split(':').first,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            onTap: widget.onTap,
            trailing: _hovered
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// New Chat Dialog
// ---------------------------------------------------------------------------

class _NewChatDialog extends ConsumerStatefulWidget {
  const _NewChatDialog({required this.onCreated});

  final void Function(int convId) onCreated;

  @override
  ConsumerState<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<_NewChatDialog> {
  String? _selectedModel;
  final _titleController = TextEditingController(text: 'New Chat');

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(installedModelsProvider);

    return AlertDialog(
      title: const Text('New Chat'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Chat title',
                hintText: 'New Chat',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Model',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            modelsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load models: $e'),
              data: (models) {
                if (models.isEmpty) {
                  return const Text(
                    'No models installed. Pull one from the Models screen.',
                  );
                }
                _selectedModel ??= models.first.name;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedModel,
                  decoration: const InputDecoration(),
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
