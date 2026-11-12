import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../database/database.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../settings/settings_providers.dart';
import 'chat_providers.dart';

/// Minimalist, high-density conversation sidebar (220px).
class ConversationSidebar extends ConsumerStatefulWidget {
  const ConversationSidebar({super.key});

  @override
  ConsumerState<ConversationSidebar> createState() =>
      _ConversationSidebarState();
}

class _ConversationSidebarState extends ConsumerState<ConversationSidebar> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(newChatTriggerProvider, (prev, next) {
        if (next > 0) _showNewChatDialog();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final convAsync = ref.watch(conversationsStreamProvider);
    final activeId = ref.watch(activeConversationProvider);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colors.bgSidebar,
        border: Border(
          right: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // New Chat Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _NewChatButton(onTap: _showNewChatDialog),
          ),

          // Conversation Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: AppTypography.ui(size: 13, color: colors.text),
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: AppTypography.ui(size: 13, color: colors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: colors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // Conversation List
          Expanded(
            child: convAsync.when(
              loading: () => Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error loading chats',
                  style: AppTypography.caption(color: colors.error),
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

                final filtered = _searchQuery.isEmpty
                    ? conversations
                    : conversations
                        .where((c) =>
                            c.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    subtitle: 'No chats matching "$_searchQuery"',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final conv = filtered[i];
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
    final colors = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.border, width: 1),
        ),
        title: Text('Delete conversation?', style: AppTypography.section(color: colors.text)),
        content: Text(
          'Delete "${conv.title}" and its messages permanently.',
          style: AppTypography.ui(size: 13, color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTypography.ui(size: 13, color: colors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.accentTextOn,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppTypography.button(color: colors.accentTextOn)),
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
    final colors = context.appColors;

    final isActive = widget.isSelected;
    final rowBg = isActive
        ? colors.surfaceHover
        : _hovered
            ? colors.surfaceHover.withValues(alpha: 0.6)
            : Colors.transparent;

    final shortModel = widget.conversation.model.split(':').first;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isActive
                  ? colors.accent.withValues(alpha: 0.4)
                  : (_hovered ? colors.border : Colors.transparent),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (isActive)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.ui(
                        size: 13,
                        weight: isActive ? FontWeight.w500 : FontWeight.w400,
                        color: isActive
                            ? colors.text
                            : colors.text.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          shortModel,
                          style: AppTypography.code(
                            size: 11,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${_relativeTime(widget.conversation.updatedAt)}',
                          style: AppTypography.caption(
                            color: colors.textMuted,
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
                  color: colors.textMuted,
                  hoverColor: colors.error,
                  hoverBackgroundColor: colors.error.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  borderRadius: AppRadius.chip,
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
    final colors = context.appColors;
    final modelsAsync = ref.watch(installedModelsProvider);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.border, width: 1),
      ),
      title: Text('New Conversation', style: AppTypography.section(color: colors.text)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              style: AppTypography.ui(size: 13, color: colors.text),
              decoration: InputDecoration(
                labelText: 'Conversation Title',
                labelStyle: AppTypography.ui(size: 13, color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Model',
              style: AppTypography.ui(size: 12, weight: FontWeight.w500, color: colors.text),
            ),
            const SizedBox(height: 6),
            modelsAsync.when(
              loading: () => LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
              error: (e, _) => Text('Error: $e', style: AppTypography.caption(color: colors.error)),
              data: (models) {
                if (models.isEmpty) {
                  return Text(
                    'No models installed. Go to Models tab to pull one.',
                    style: AppTypography.caption(color: colors.textMuted),
                  );
                }
                final defaultModel = ref.read(settingsNotifierProvider).defaultModel;
                if (_selectedModel == null) {
                  if (defaultModel != null && models.any((m) => m.name == defaultModel)) {
                    _selectedModel = defaultModel;
                  } else {
                    _selectedModel = models.first.name;
                  }
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedModel,
                  style: AppTypography.ui(size: 13, color: colors.text),
                  dropdownColor: colors.surface,
                  items: models
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.name,
                          child: Text(m.name, style: AppTypography.ui(size: 13, color: colors.text)),
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
          child: Text('Cancel', style: AppTypography.ui(size: 13, color: colors.textMuted)),
        ),
        FilledButton(
          onPressed: _selectedModel == null ? null : _create,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.accentTextOn,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          child: Text('Create', style: AppTypography.button(color: colors.accentTextOn)),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final db = ref.read(appDatabaseProvider);
    final settings = ref.read(settingsNotifierProvider);
    final now = DateTime.now();

    final paramPreset = jsonEncode({
      'temperature': settings.defaultTemperature,
      'top_p': settings.defaultTopP,
      'repeat_penalty': settings.defaultRepeatPenalty,
      'num_ctx': settings.defaultNumCtx,
    });
    final systemPrompt = settings.defaultSystemPrompt.trim().isEmpty
        ? null
        : settings.defaultSystemPrompt.trim();

    final id = await db.insertConversation(
      ConversationsCompanion(
        title: Value(_titleController.text.trim().isEmpty
            ? 'New Chat'
            : _titleController.text.trim()),
        model: Value(_selectedModel!),
        createdAt: Value(now),
        updatedAt: Value(now),
        systemPrompt: Value(systemPrompt),
        paramPreset: Value(paramPreset),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onCreated(id);
    }
  }
}

class _NewChatButton extends StatefulWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<_NewChatButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceHover : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: _hovered ? colors.accent.withValues(alpha: 0.6) : colors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: _hovered ? colors.accent : colors.text,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New chat',
                  style: AppTypography.ui(
                    size: 13,
                    weight: _hovered ? FontWeight.w600 : FontWeight.w500,
                    color: colors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.bgSidebar,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: colors.border, width: 1),
                ),
                child: Text(
                  'Ctrl N',
                  style: AppTypography.code(
                    size: 10,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

