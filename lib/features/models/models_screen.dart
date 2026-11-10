import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../chat/chat_providers.dart';
import 'model_card.dart';
import 'models_providers.dart';
import 'pull_model_dialog.dart';

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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh models',
            onPressed: () {
              ref.read(modelsNotifierProvider.notifier).refresh();
            },
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Pull Model'),
            onPressed: () => _openPullDialog(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: modelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to connect to Ollama',
          subtitle: err.toString(),
          action: FilledButton(
            onPressed: () => ref.read(modelsNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
        data: (models) {
          if (models.isEmpty) {
            return EmptyState(
              icon: Icons.storage_outlined,
              title: 'No models installed yet',
              subtitle: 'Pull models like llama3.2, qwen2.5, or mistral to get started.',
              action: FilledButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Pull your first model'),
                onPressed: () => _openPullDialog(context),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: CustomScrollView(
              slivers: [
                // Running in VRAM section
                runningAsync.when(
                  data: (running) {
                    if (running.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.memory, size: 18, color: Color(0xFF22C55E)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loaded in VRAM / Memory (${running.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: running.map((rm) {
                                  return Chip(
                                    avatar: const Icon(Icons.circle, size: 10, color: Color(0xFF22C55E)),
                                    label: Text(
                                      '${rm.name} (${(rm.vramSize / 1e9).toStringAsFixed(1)} GB VRAM)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                // Installed models grid
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 180,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
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
