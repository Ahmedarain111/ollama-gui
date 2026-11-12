import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
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
    final colors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
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
              // Segmented toggle between Installed and Explore Library
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: colors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: colors.border,
                    width: 1,
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
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Pull model', style: AppTypography.button(color: colors.accentTextOn)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentTextOn,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                  onPressed: () => _openPullDialog(context),
                ),
              ] else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text('Custom pull', style: AppTypography.button(color: colors.accentTextOn)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentTextOn,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
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
    final colors = context.appColors;

    return modelsAsync.when(
      loading: () => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Connection error',
        subtitle: err.toString(),
        action: FilledButton(
          onPressed: () => ref.read(modelsNotifierProvider.notifier).refresh(),
          style: FilledButton.styleFrom(
            backgroundColor: colors.surfaceHover,
            foregroundColor: colors.text,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              side: BorderSide(color: colors.border, width: 1),
            ),
          ),
          child: Text('Retry', style: AppTypography.button(color: colors.text)),
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
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.accentTextOn,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: Text('Explore Model Library', style: AppTypography.button(color: colors.accentTextOn)),
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
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storage_rounded, size: 16, color: colors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Local Storage: ',
                        style: AppTypography.ui(
                          size: 13,
                          weight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        '$totalGb GB in use across ${models.length} model${models.length == 1 ? '' : 's'}',
                        style: AppTypography.ui(
                          size: 13,
                          color: colors.textMuted,
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
                                style: AppTypography.ui(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: colors.accent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 13, color: colors.accent),
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
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: colors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loaded in VRAM: ',
                            style: AppTypography.ui(
                              size: 13,
                              weight: FontWeight.w500,
                              color: colors.text,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              running
                                  .map((m) =>
                                      '${m.name} (${(m.vramSize / 1e9).toStringAsFixed(1)} GB)')
                                  .join(', '),
                              style: AppTypography.code(
                                size: 12,
                                color: colors.textMuted,
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
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: colors.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16, color: colors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Expand Your Local AI Toolkit',
                              style: AppTypography.section(
                                size: 14,
                                color: colors.text,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.apps_rounded, size: 14),
                              label: Text(
                                'Browse Full Catalog',
                                style: AppTypography.ui(size: 12, color: colors.accent, weight: FontWeight.w500),
                              ),
                              onPressed: () => setState(() => _selectedTab = 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enhance reasoning, coding, and vision capabilities with popular open weights:',
                          style: AppTypography.ui(
                            size: 12,
                            color: colors.textMuted,
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
    final colors = context.appColors;
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
                    style: AppTypography.ui(size: 13, color: colors.text),
                    decoration: InputDecoration(
                      hintText: 'Search models by name, category, or publisher...',
                      hintStyle: AppTypography.ui(
                        size: 13,
                        color: colors.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
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
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
                            duration: AppMotion.shortDuration,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.accent.withValues(alpha: 0.15)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                              border: Border.all(
                                color: isSelected
                                    ? colors.accent
                                    : colors.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: AppTypography.ui(
                                size: 12,
                                weight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                color: isSelected ? colors.accent : colors.textMuted,
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
                    action: FilledButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _selectedCategory = 'All');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.surfaceHover,
                        foregroundColor: colors.text,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          side: BorderSide(color: colors.border, width: 1),
                        ),
                      ),
                      child: Text('Reset filters', style: AppTypography.button(color: colors.text)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 185,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return _LibraryModelCard(
                        model: item,
                        installedModelNames: installedModelNames,
                        onPull: (tag) => _openPullDialog(context, initialModel: tag),
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
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colors.surface
                : _hovered
                    ? colors.surfaceHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: widget.isSelected
                ? Border.all(color: colors.border, width: 1)
                : null,
          ),
          child: Text(
            widget.label,
            style: AppTypography.ui(
              size: 12,
              weight: widget.isSelected ? FontWeight.w500 : FontWeight.w400,
              color: widget.isSelected ? colors.text : colors.textMuted,
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
    required this.installedModelNames,
    required this.onPull,
  });

  final LibraryModel model;
  final Set<String> installedModelNames;
  final void Function(String tag) onPull;

  @override
  State<_LibraryModelCard> createState() => _LibraryModelCardState();
}

class _LibraryModelCardState extends State<_LibraryModelCard> {
  bool _hovered = false;
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _initSelectedSize();
  }

  @override
  void didUpdateWidget(covariant _LibraryModelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.name != widget.model.name) {
      _initSelectedSize();
    }
  }

  void _initSelectedSize() {
    final defaultParts = widget.model.defaultTag.split(':');
    final tagSize = defaultParts.length > 1 ? defaultParts.last : '';
    if (widget.model.sizes.contains(tagSize)) {
      _selectedSize = tagSize;
    } else if (widget.model.sizes.isNotEmpty) {
      _selectedSize = widget.model.sizes.first;
    } else {
      _selectedSize = 'latest';
    }
  }

  bool _isVariantInstalled(String size) {
    final fullTag = '${widget.model.name}:$size'.toLowerCase();
    final cleanName = widget.model.name.toLowerCase();
    return widget.installedModelNames.contains(fullTag) ||
        (size == 'latest' && widget.installedModelNames.contains(cleanName));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelectedInstalled = _isVariantInstalled(_selectedSize);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppMotion.shortDuration,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.surfaceHover
              : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: _hovered
                ? colors.accent.withValues(alpha: 0.5)
                : colors.border,
            width: 1,
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
                          style: AppTypography.ui(
                            size: 14,
                            weight: FontWeight.w600,
                            color: colors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${widget.model.publisher}',
                        style: AppTypography.caption(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Category pill
                Container(
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
                    widget.model.category,
                    style: AppTypography.code(
                      size: 10,
                      weight: FontWeight.w500,
                      color: colors.textMuted,
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
                style: AppTypography.ui(
                  size: 12,
                  height: 1.4,
                  color: colors.textMuted,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Bottom section: Weight Variant selector + Pull / Installed Action
            Row(
              children: [
                // Scrollable weight variant pills
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.model.sizes.map((size) {
                        final isSelected = size == _selectedSize;
                        final isInstalled = _isVariantInstalled(size);

                        return Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: _SizeVariantChip(
                            size: size,
                            isSelected: isSelected,
                            isInstalled: isInstalled,
                            onTap: () => setState(() => _selectedSize = size),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Pull or Installed Status
                if (isSelectedInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 13, color: colors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Installed',
                          style: AppTypography.code(
                            size: 11,
                            weight: FontWeight.w500,
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: Text(
                      'Pull $_selectedSize',
                      style: AppTypography.button(),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.surfaceHover,
                      foregroundColor: colors.text,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        side: BorderSide(color: colors.border, width: 1),
                      ),
                    ),
                    onPressed: () => widget.onPull('${widget.model.name}:$_selectedSize'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeVariantChip extends StatefulWidget {
  const _SizeVariantChip({
    required this.size,
    required this.isSelected,
    required this.isInstalled,
    required this.onTap,
  });

  final String size;
  final bool isSelected;
  final bool isInstalled;
  final VoidCallback onTap;

  @override
  State<_SizeVariantChip> createState() => _SizeVariantChipState();
}

class _SizeVariantChipState extends State<_SizeVariantChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Color bg;
    Color border;
    Color text;

    if (widget.isSelected) {
      bg = colors.accent.withValues(alpha: 0.15);
      border = colors.accent;
      text = colors.accent;
    } else if (_hovered) {
      bg = colors.surfaceHover;
      border = colors.accent.withValues(alpha: 0.5);
      text = colors.text;
    } else {
      bg = colors.surfaceHover;
      border = widget.isInstalled ? colors.success.withValues(alpha: 0.4) : colors.border;
      text = widget.isInstalled ? colors.success : colors.textMuted;
    }

    return Tooltip(
      message: widget.isInstalled ? '${widget.size} (Installed)' : 'Select ${widget.size} variant',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.shortDuration,
            curve: AppMotion.standardCurve,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isInstalled && !widget.isSelected) ...[
                  Icon(Icons.check_rounded, size: 10, color: colors.success),
                  const SizedBox(width: 3),
                ],
                Text(
                  widget.size,
                  style: AppTypography.code(
                    size: 11,
                    weight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: text,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.surfaceHover
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: _hovered
                  ? colors.accent.withValues(alpha: 0.6)
                  : colors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 14,
                color: _hovered ? colors.accent : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                widget.name,
                style: AppTypography.code(
                  size: 12,
                  weight: FontWeight.w500,
                  color: _hovered ? colors.accent : colors.text,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: colors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: colors.border, width: 1),
                ),
                child: Text(
                  widget.tag,
                  style: AppTypography.caption(
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

