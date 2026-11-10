import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../shared/widgets/model_badge.dart';
import '../chat/chat_providers.dart';
import 'models_providers.dart';

class ModelCard extends ConsumerWidget {
  const ModelCard({
    super.key,
    required this.model,
  });

  final OllamaModel model;

  void _showModelInfo(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(model.name),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Consumer(
              builder: (context, ref, _) {
                final infoAsync = ref.watch(modelInfoProvider(model.name));
                return infoAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed to load info: $e')),
                  data: (info) {
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Modelfile'),
                              Tab(text: 'Template'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  child: SelectableText(
                                    info.modelfile.isNotEmpty
                                        ? info.modelfile
                                        : 'No Modelfile details available.',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: SelectableText(
                                    info.template.isNotEmpty
                                        ? info.template
                                        : 'No template details available.',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: const Text(
          'This will permanently delete this model from disk. You can re-download it anytime.',
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
      await ref.read(modelsNotifierProvider.notifier).deleteModel(model.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${model.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model name & overflow menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'info') {
                      _showModelInfo(context, ref);
                    } else if (val == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Details & Modelfile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete model', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Metadata badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ModelBadge(
                  label: model.sizeGb,
                  color: colorScheme.primary,
                ),
                if (model.details.quantizationLevel.isNotEmpty)
                  ModelBadge(
                    label: model.details.quantizationLevel,
                    color: const Color(0xFF10B981),
                  ),
                if (model.details.parameterSize.isNotEmpty)
                  ModelBadge(
                    label: model.details.parameterSize,
                    color: const Color(0xFF8B5CF6),
                  ),
                if (model.details.family.isNotEmpty)
                  ModelBadge(
                    label: model.details.family,
                    color: const Color(0xFFF59E0B),
                  ),
              ],
            ),

            const Spacer(),

            // Modified date & Chat button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Updated ${dateFormat.format(model.modifiedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Chat'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    ref.read(selectedModelProvider.notifier).state = model.name;
                    context.go('/chat');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
