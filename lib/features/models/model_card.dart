import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../chat/chat_providers.dart';
import 'models_providers.dart';

/// Clean technical card for an installed Ollama model.
class ModelCard extends ConsumerWidget {
  const ModelCard({super.key, required this.model});

  final OllamaModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.6),
          width: 0.8,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  const PopupMenuItem(
                    value: 'info',
                    height: 32,
                    child: Text('Inspect Modelfile', style: TextStyle(fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    height: 32,
                    child: Text('Delete model', style: TextStyle(fontSize: 12.5, color: Colors.red)),
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
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  ref.read(selectedModelProvider.notifier).state = model.name;
                  context.go('/chat');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start chat',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(model.name, style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 480,
            height: 360,
            child: Consumer(
              builder: (context, ref, _) {
                final infoAsync = ref.watch(modelInfoProvider(model.name));
                return infoAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (info) => SingleChildScrollView(
                    child: SelectableText(
                      info.modelfile.isNotEmpty ? info.modelfile : info.template,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: const Text(
          'This model will be removed from local storage.',
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
            child: const Text('Delete'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10.5,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        onSelected: widget.onSelected,
        itemBuilder: widget.itemBuilder,
        tooltip: '',
        padding: EdgeInsets.zero,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                size: 15,
                color: _hovered
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: _hovered
                      ? Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            'Options',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
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

