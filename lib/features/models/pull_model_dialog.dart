import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'models_library.dart';
import 'models_providers.dart';

class PullModelDialog extends ConsumerStatefulWidget {
  const PullModelDialog({super.key, this.initialModelName});

  final String? initialModelName;

  @override
  ConsumerState<PullModelDialog> createState() => _PullModelDialogState();
}

class _PullModelDialogState extends ConsumerState<PullModelDialog> {
  late final TextEditingController _controller;
  bool _isPulling = false;
  String? _status;
  double? _progress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialModelName ?? '');
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  static const _popularModels = [
    'qwen3:8b',
    'qwen2.5:3b',
    'qwen2.5:7b',
    'deepseek-r1:7b',
    'llama3.2:3b',
    'llama3.2:1b',
    'mistral-small:24b',
    'mistral:latest',
    'nomic-embed-text',
  ];

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startPull() async {
    final modelName = _controller.text.trim();
    if (modelName.isEmpty) return;

    setState(() {
      _isPulling = true;
      _status = 'Initiating download...';
      _progress = null;
      _errorMessage = null;
    });

    try {
      final client = ref.read(ollamaClientProvider);
      await client.pullModel(
        modelName,
        onProgress: (PullProgress p) {
          if (!mounted) return;
          setState(() {
            _status = p.status;
            if (p.total != null && p.total! > 0 && p.completed != null) {
              _progress = p.completed! / p.total!;
            }
          });
        },
      );

      if (mounted) {
        ref.read(modelsNotifierProvider.notifier).refresh();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded $modelName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPulling = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final modelText = _controller.text.trim();
    final matchingModel = findLibraryModel(modelText);
    final currentParts = modelText.split(':');
    final currentVariant = currentParts.length > 1 ? currentParts.last.toLowerCase() : '';

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.border, width: 1),
      ),
      title: Text('Pull Model', style: AppTypography.section(color: colors.text, size: 16)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              enabled: !_isPulling,
              autofocus: true,
              style: AppTypography.code(size: 13, color: colors.text),
              decoration: InputDecoration(
                hintText: 'e.g. qwen3:8b, qwen2.5:3b, llama3.2:3b',
                hintStyle: AppTypography.code(size: 13, color: colors.textMuted),
                prefixIcon: Icon(Icons.download_rounded, size: 16, color: colors.textMuted),
                filled: true,
                fillColor: colors.surfaceHover,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              onSubmitted: (_) => _isPulling ? null : _startPull(),
            ),

            // Dynamic Weight Variant Selector
            if (matchingModel != null && matchingModel.sizes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Weight variant',
                    style: AppTypography.caption(
                      color: colors.textMuted,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${matchingModel.name})',
                    style: AppTypography.code(size: 11, color: colors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: matchingModel.sizes.map((size) {
                    final isSelected = currentVariant == size.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _VariantChip(
                        label: size,
                        isSelected: isSelected,
                        enabled: !_isPulling,
                        onTap: () {
                          final newTag = '${matchingModel.name}:$size';
                          _controller.text = newTag;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: newTag.length),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Text(
              'Suggestions',
              style: AppTypography.caption(
                color: colors.textMuted,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _popularModels.map((m) {
                return _SuggestionChip(
                  label: m,
                  enabled: !_isPulling,
                  onTap: () {
                    _controller.text = m;
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: m.length),
                    );
                  },
                );
              }).toList(),
            ),
            if (_isPulling) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 4,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _status ?? 'Downloading...',
                      style: AppTypography.caption(
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_progress != null)
                    Text(
                      '${(_progress! * 100).toStringAsFixed(1)}%',
                      style: AppTypography.code(
                        size: 11,
                        weight: FontWeight.w600,
                        color: colors.accent,
                      ),
                    ),
                ],
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTypography.ui(size: 12, color: colors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPulling ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: AppTypography.ui(size: 13, color: colors.textMuted)),
        ),
        FilledButton(
          onPressed: _isPulling ? null : _startPull,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.accentTextOn,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          child: Text(_isPulling ? 'Downloading...' : 'Download', style: AppTypography.button(color: colors.accentTextOn)),
        ),
      ],
    );
  }
}

class _VariantChip extends StatefulWidget {
  const _VariantChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_VariantChip> createState() => _VariantChipState();
}

class _VariantChipState extends State<_VariantChip> {
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
    } else if (_hovered && widget.enabled) {
      bg = colors.surfaceHover;
      border = colors.accent.withValues(alpha: 0.5);
      text = colors.text;
    } else {
      bg = colors.surfaceHover;
      border = colors.border;
      text = colors.textMuted;
    }

    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _hovered = false);
      },
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: border, width: 1),
          ),
          child: Text(
            widget.label,
            style: AppTypography.code(
              size: 11,
              weight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _hovered = false);
      },
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: AppMotion.shortDuration,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? colors.surfaceHover
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: _hovered && widget.enabled
                  ? colors.accent.withValues(alpha: 0.6)
                  : colors.border,
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTypography.code(
              size: 11,
              weight: _hovered ? FontWeight.w500 : FontWeight.w400,
              color: _hovered && widget.enabled
                  ? colors.accent
                  : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}
