import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../chat/chat_providers.dart';
import 'model_card.dart';
import 'models_library.dart';
import 'models_providers.dart';
import 'pull_model_dialog.dart';

/// Models view featuring local installed models and an interactive Ollama registry library browser.
class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  int _selectedTab = 0; // 0 = Installed, 1 = Explore Library
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Reasoning',
    'Coding',
    'Vision',
    'General',
    'Embedding',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPullDialog(BuildContext context, {String? initialModel}) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => PullModelDialog(initialModelName: initialModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final modelsAsync = ref.watch(installedModelsProvider);
    final runningAsync = ref.watch(runningModelsProvider);

    final installedCount = modelsAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subheader Controls Bar
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerTheme.color ?? colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Segmented toggle between Installed and Explore Library
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TabPill(
                      label: 'Installed ($installedCount)',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabPill(
                      label: 'Explore Library (${ollamaModelCatalog.length})',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              if (_selectedTab == 0) ...[
                HoverIconButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  iconSize: 18,
                  onTap: () => ref.read(modelsNotifierProvider.notifier).refresh(),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Pull model', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _openPullDialog(context),
                ),
              ] else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: const Text('Custom pull', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _openPullDialog(context),
                ),
              ],
            ],
          ),
        ),

        // Body content
        Expanded(
          child: _selectedTab == 0
              ? _buildInstalledView(context, colorScheme, modelsAsync, runningAsync)
              : _buildLibraryView(context, colorScheme, modelsAsync),
        ),
      ],
    );
  }

  Widget _buildInstalledView(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<dynamic>> modelsAsync,
    AsyncValue<List<dynamic>> runningAsync,
  ) {
    return modelsAsync.when(
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
              onPressed: () => setState(() => _selectedTab = 1),
              child: const Text('Explore Model Library'),
            ),
          );
        }

        final totalBytes = models.fold<int>(0, (sum, m) => sum + (m.size as int));
        final totalGb = (totalBytes / 1e9).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: CustomScrollView(
            slivers: [
              // Storage & Host Metrics Strip
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                      Icon(Icons.storage_rounded, size: 15, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Local Storage: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$totalGb GB in use across ${models.length} model${models.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore 30+ Model Catalog',
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
                ),
              ),

              // VRAM status strip
              runningAsync.when(
                data: (running) {
                  if (running.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                              running
                                  .map((m) =>
                                      '${m.name} (${(m.vramSize / 1e9).toStringAsFixed(1)} GB)')
                                  .join(', '),
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

              // Grid of installed models
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

              // Suggested models banner if few installed models
              if (models.length < 3)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.45),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Expand Your Local AI Toolkit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.apps_rounded, size: 14),
                              label: const Text('Browse Full Catalog', style: TextStyle(fontSize: 12)),
                              onPressed: () => setState(() => _selectedTab = 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enhance reasoning, coding, and vision capabilities with popular open weights:',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _QuickPullChip(
                              name: 'deepseek-r1:7b',
                              tag: 'Reasoning',
                              onTap: () => _openPullDialog(context, initialModel: 'deepseek-r1:7b'),
                            ),
                            _QuickPullChip(
                              name: 'qwen2.5-coder:7b',
                              tag: 'Coding',
                              onTap: () => _openPullDialog(context, initialModel: 'qwen2.5-coder:7b'),
                            ),
                            _QuickPullChip(
                              name: 'llama3.2-vision:11b',
                              tag: 'Vision',
                              onTap: () => _openPullDialog(context, initialModel: 'llama3.2-vision:11b'),
                            ),
                            _QuickPullChip(
                              name: 'phi4-mini',
                              tag: 'Fast & Light',
                              onTap: () => _openPullDialog(context, initialModel: 'phi4-mini'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLibraryView(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<dynamic>> modelsAsync,
  ) {
    final installedModelNames = modelsAsync.when(
      data: (models) => models.map((m) => (m.name as String).toLowerCase()).toSet(),
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );

    final filtered = ollamaModelCatalog.where((m) {
      if (_selectedCategory != 'All' && m.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = m.name.toLowerCase().contains(q);
        final matchDesc = m.description.toLowerCase().contains(q);
        final matchPub = m.publisher.toLowerCase().contains(q);
        final matchSizes = m.sizes.any((s) => s.toLowerCase().contains(q));
        if (!matchName && !matchDesc && !matchPub && !matchSizes) {
          return false;
        }
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Category Filters Bar
          Row(
            children: [
              // Search input
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search models by name, category, or publisher...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Category filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Catalog Grid
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No models found',
                    subtitle: 'No models match your query "$_searchQuery".',
                    action: FilledButton.tonal(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _selectedCategory = 'All');
                      },
                      child: const Text('Reset filters'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 175,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isInstalled = installedModelNames.any(
                        (name) => name == item.name || name.startsWith('${item.name}:'),
                      );

                      return _LibraryModelCard(
                        model: item,
                        isInstalled: isInstalled,
                        onPull: () => _openPullDialog(context, initialModel: item.defaultTag),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatefulWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends State<_TabPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.surface
                : _hovered
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: widget.isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryModelCard extends StatefulWidget {
  const _LibraryModelCard({
    required this.model,
    required this.isInstalled,
    required this.onPull,
  });

  final LibraryModel model;
  final bool isInstalled;
  final VoidCallback onPull;

  @override
  State<_LibraryModelCard> createState() => _LibraryModelCardState();
}

class _LibraryModelCardState extends State<_LibraryModelCard> {
  bool _hovered = false;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Reasoning':
        return const Color(0xFF8B5CF6);
      case 'Coding':
        return const Color(0xFF0EA5E9);
      case 'Vision':
        return const Color(0xFFF59E0B);
      case 'Embedding':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final catColor = _getCategoryColor(widget.model.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Model name, Publisher, and Category badge
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.model.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${widget.model.publisher}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.4),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    widget.model.category,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: catColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description
            Expanded(
              child: Text(
                widget.model.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Bottom row: parameter size pills + Pull action
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.model.sizes.take(4).map((size) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          size,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 8),

                if (widget.isInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 0.6,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 3),
                        Text(
                          'Installed',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: Text(
                      'Pull ${widget.model.defaultTag.split(':').last}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: widget.onPull,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPullChip extends StatefulWidget {
  const _QuickPullChip({
    required this.name,
    required this.tag,
    required this.onTap,
  });

  final String name;
  final String tag;
  final VoidCallback onTap;

  @override
  State<_QuickPullChip> createState() => _QuickPullChipState();
}

class _QuickPullChipState extends State<_QuickPullChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 14,
                color: _hovered ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  widget.tag,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: colorScheme.onSurfaceVariant,
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

