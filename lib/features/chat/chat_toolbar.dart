import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/hover_icon_button.dart';
import 'chat_context_bar.dart';
import 'chat_media_helper.dart';
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
    final colors = context.appColors;
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: 1,
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
                    style: AppTypography.ui(size: 13, weight: FontWeight.w500, color: colors.text),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: colors.surfaceHover,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.r8,
                        borderSide: BorderSide(color: colors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.r8,
                        borderSide: BorderSide(color: colors.accent, width: 2),
                      ),
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
                : Tooltip(
                    message: 'Double-click to rename',
                    waitDuration: const Duration(milliseconds: 500),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onDoubleTap: () => setState(() => _editingTitle = true),
                        child: Text(
                          conv?.title ?? 'Conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.ui(
                            size: 13,
                            weight: FontWeight.w500,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 8),

          // Context Window Utilization Meter
          ChatContextBar(conversationId: widget.conversationId),

          const SizedBox(width: 8),

          // Sleek Model Selector with hover highlight and click cursor
          modelsAsync.when(
            data: (models) {
              if (models.isEmpty) return const SizedBox.shrink();
              return _ModelSelectorDropdown(
                models: models,
                selectedModel: selectedModel,
                onChanged: (newModel) {
                  if (newModel != null) {
                    ref.read(selectedModelProvider.notifier).state = newModel;
                  }
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(width: 8),

          // Inference Parameters & System Prompt Toggle
          HoverIconButton(
            icon: Icons.tune_rounded,
            label: 'Params',
            iconSize: 16,
            tooltip: 'Tuning & System prompt',
            onTap: () {
              final current = ref.read(showParamsPanelProvider);
              ref.read(showParamsPanelProvider.notifier).state = !current;
            },
          ),

          const SizedBox(width: 4),

          // Actions Menu with text revealed on hover
          _HoverActionsMenu(
            onSelected: (val) {
              if (val == 'rename') {
                setState(() => _editingTitle = true);
              } else if (val == 'export') {
                _exportMarkdown(context);
              } else if (val == 'clear') {
                _clearMessages(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                height: 36,
                child: Text('Rename chat', style: AppTypography.ui(size: 13, color: colors.text)),
              ),
              PopupMenuItem(
                value: 'export',
                height: 36,
                child: Text('Export as Markdown', style: AppTypography.ui(size: 13, color: colors.text)),
              ),
              PopupMenuItem(
                value: 'clear',
                height: 36,
                child: Text('Clear history', style: AppTypography.ui(size: 13, color: colors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportMarkdown(BuildContext context) async {
    final db = ref.read(appDatabaseProvider);
    final conv = await db.getConversation(widget.conversationId);
    final msgs = await db.getMessages(widget.conversationId);

    final buffer = StringBuffer();
    final title = conv?.title ?? 'Conversation';
    buffer.writeln('# $title\n');
    buffer.writeln('**Model:** `${conv?.model ?? "Ollama"}`  ');
    buffer.writeln('**Date:** ${DateFormat.yMMMd().add_jm().format(conv?.createdAt ?? DateTime.now())}  ');
    if (conv?.systemPrompt != null && conv!.systemPrompt!.trim().isNotEmpty) {
      buffer.writeln('\n> **System Prompt:** ${conv.systemPrompt!.trim()}\n');
    }
    buffer.writeln('\n---\n');

    for (final m in msgs) {
      final parsed = parseMessageContent(m.content);
      if (m.role == 'user') {
        buffer.writeln('### User\n');
        if (parsed.images != null && parsed.images!.isNotEmpty) {
          buffer.writeln('*[Attached: ${parsed.images!.length} image(s)]*\n');
        }
        buffer.writeln('${parsed.text}\n');
      } else {
        buffer.writeln('### Assistant\n');
        buffer.writeln('${parsed.text}\n');
        if (m.tokensPerSec != null && m.tokensPerSec! > 0) {
          buffer.writeln('*(Speed: ${m.tokensPerSec!.toStringAsFixed(1)} tok/s · Tokens: ${m.totalTokens ?? 0})*\n');
        }
      }
      buffer.writeln('---\n');
    }

    final mdContent = buffer.toString();
    final sanitizedTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_')
        .toLowerCase();

    try {
      final filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Chat as Markdown',
        fileName: '$sanitizedTitle.md',
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (filePath != null) {
        final file = File(filePath);
        await file.writeAsString(mdContent);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported to ${file.path.split('/').last}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback if desktop save dialog fails
    }

    await Clipboard.setData(ClipboardData(text: mdContent));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat exported: Markdown copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearMessages(BuildContext context) async {
    final colors = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: Text(
          'All messages in this session will be deleted.',
          style: AppTypography.ui(size: 13, color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
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

class _HoverActionsMenu extends StatefulWidget {
  const _HoverActionsMenu({
    required this.onSelected,
    required this.itemBuilder,
  });

  final PopupMenuItemSelected<String> onSelected;
  final PopupMenuItemBuilder<String> itemBuilder;

  @override
  State<_HoverActionsMenu> createState() => _HoverActionsMenuState();
}

class _HoverActionsMenuState extends State<_HoverActionsMenu> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        onSelected: widget.onSelected,
        itemBuilder: widget.itemBuilder,
        tooltip: '',
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered ? colors.surfaceHover : Colors.transparent,
              borderRadius: AppRadius.r8,
              border: Border.all(
                color: _hovered ? colors.border : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: _hovered ? colors.text : colors.textMuted,
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    alignment: Alignment.centerLeft,
                    child: _hovered
                        ? Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Actions',
                              style: AppTypography.ui(
                                size: 12,
                                weight: FontWeight.w500,
                                color: colors.text,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelSelectorDropdown extends StatefulWidget {
  const _ModelSelectorDropdown({
    required this.models,
    required this.selectedModel,
    required this.onChanged,
  });

  final List<OllamaModel> models;
  final String selectedModel;
  final ValueChanged<String?> onChanged;

  @override
  State<_ModelSelectorDropdown> createState() => _ModelSelectorDropdownState();
}

class _ModelSelectorDropdownState extends State<_ModelSelectorDropdown> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final current = widget.models.any((m) => m.name == widget.selectedModel)
        ? widget.selectedModel
        : (widget.models.isNotEmpty ? widget.models.first.name : '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? colors.surfaceHover : colors.surface,
            borderRadius: AppRadius.r8,
            border: Border.all(
              color: _hovered ? colors.accent : colors.border,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.isNotEmpty ? current : null,
              isDense: true,
              dropdownColor: colors.surface,
              borderRadius: AppRadius.r12,
              icon: Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: _hovered ? colors.text : colors.textMuted,
              ),
              style: AppTypography.code(
                size: 12,
                color: colors.text,
                weight: FontWeight.w500,
              ),
              items: widget.models.map((m) {
                final isSelected = m.name == current;
                return DropdownMenuItem<String>(
                  value: m.name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.name,
                        style: AppTypography.code(
                          size: 12,
                          weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? colors.accent : colors.text,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${m.sizeGb}${m.details.parameterSize.isNotEmpty ? ' · ${m.details.parameterSize}' : ''}',
                        style: AppTypography.code(
                          size: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
