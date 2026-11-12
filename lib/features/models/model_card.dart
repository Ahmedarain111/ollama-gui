import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../chat/chat_providers.dart';
import 'models_providers.dart';

/// Clean technical card for an installed Ollama model.
class ModelCard extends ConsumerWidget {
  const ModelCard({super.key, required this.model});

  final OllamaModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Menu
          Row(
            children: [
              Expanded(
                child: Text(
                  model.name,
                  style: AppTypography.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: colors.text,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _HoverCardMenu(
                onSelected: (val) {
                  if (val == 'info') {
                    _showInfo(context, ref);
                  } else if (val == 'delete') {
                    _delete(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    height: 32,
                    child: Text('Inspect Modelfile', style: AppTypography.ui(size: 13, color: colors.text)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    height: 32,
                    child: Text('Delete model', style: AppTypography.ui(size: 13, color: colors.error)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Monospace Technical Tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Tag(label: model.sizeGb),
              if (model.details.quantizationLevel.isNotEmpty)
                _Tag(label: model.details.quantizationLevel.toLowerCase()),
              if (model.details.parameterSize.isNotEmpty)
                _Tag(label: model.details.parameterSize),
              if (model.details.family.isNotEmpty)
                _Tag(label: model.details.family),
            ],
          ),

          const Spacer(),

          // Footer: Timestamp & Chat action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(model.modifiedAt),
                style: AppTypography.caption(
                  color: colors.textMuted,
                ),
              ),
              _StartChatButton(
                onTap: () {
                  ref.read(selectedModelProvider.notifier).state = model.name;
                  context.go('/chat');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: colors.border, width: 1),
          ),
          title: Text(model.name, style: AppTypography.section(color: colors.text)),
          content: SizedBox(
            width: 480,
            height: 360,
            child: Consumer(
              builder: (context, ref, _) {
                final infoAsync = ref.watch(modelInfoProvider(model.name));
                return infoAsync.when(
                  loading: () => Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(colors.accent)),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e', style: AppTypography.caption(color: colors.error))),
                  data: (info) => Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.codeBg,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        info.modelfile.isNotEmpty ? info.modelfile : info.template,
                        style: AppTypography.code(
                          size: 12,
                          color: colors.text,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: AppTypography.ui(size: 13, color: colors.textMuted)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final colors = context.appColors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.border, width: 1),
        ),
        title: Text('Delete ${model.name}?', style: AppTypography.section(color: colors.text)),
        content: Text(
          'This model will be removed from local storage.',
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
      await ref.read(modelsNotifierProvider.notifier).deleteModel(model.name);
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceHover,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.code(
          size: 11,
          color: colors.textMuted,
        ),
      ),
    );
  }
}

class _HoverCardMenu extends StatefulWidget {
  const _HoverCardMenu({
    required this.onSelected,
    required this.itemBuilder,
  });

  final PopupMenuItemSelected<String> onSelected;
  final PopupMenuItemBuilder<String> itemBuilder;

  @override
  State<_HoverCardMenu> createState() => _HoverCardMenuState();
}

class _HoverCardMenuState extends State<_HoverCardMenu> {
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
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.border, width: 1),
        ),
        padding: EdgeInsets.zero,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.surfaceHover
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: _hovered
                  ? colors.border
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                size: 15,
                color: _hovered
                    ? colors.text
                    : colors.textMuted,
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: AppMotion.shortDuration,
                  curve: AppMotion.standardCurve,
                  alignment: Alignment.centerLeft,
                  child: _hovered
                      ? Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            'Options',
                            style: AppTypography.ui(
                              size: 11,
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
    );
  }
}

class _StartChatButton extends StatefulWidget {
  const _StartChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_StartChatButton> createState() => _StartChatButtonState();
}

class _StartChatButtonState extends State<_StartChatButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.accent.withValues(alpha: 0.15)
                : colors.surfaceHover,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: _hovered
                  ? colors.accent
                  : colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start chat',
                style: AppTypography.ui(
                  size: 12,
                  weight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}


