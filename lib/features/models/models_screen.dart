import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../chat/chat_providers.dart';
import 'model_card.dart';
import 'models_providers.dart';
import 'pull_model_dialog.dart';

/// Minimalist local models inventory.
class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  void _openPullDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => const PullModelDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modelsAsync = ref.watch(installedModelsProvider);
    final runningAsync = ref.watch(runningModelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Models'),
        actions: [
          HoverIconButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            iconSize: 18,
            onTap: () => ref.read(modelsNotifierProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Pull model', style: TextStyle(fontSize: 12.5)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => _openPullDialog(context),
            ),
          ),
        ],
      ),
      body: modelsAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Connection error',
          subtitle: err.toString(),
          action: FilledButton.tonal(
            onPressed: () => ref.read(modelsNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
        data: (models) {
          if (models.isEmpty) {
            return EmptyState(
              icon: Icons.layers_outlined,
              title: 'No models installed',
              subtitle: 'Pull models from the Ollama library to get started.',
              action: FilledButton(
                onPressed: () => _openPullDialog(context),
                child: const Text('Pull a model'),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: CustomScrollView(
              slivers: [
                // VRAM status strip
                runningAsync.when(
                  data: (running) {
                    if (running.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loaded in VRAM: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                running.map((m) => '${m.name} (${(m.vramSize / 1e9).toStringAsFixed(1)} GB)').join(', '),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Grid of models
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 145,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ModelCard(model: models[index]),
                    childCount: models.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
