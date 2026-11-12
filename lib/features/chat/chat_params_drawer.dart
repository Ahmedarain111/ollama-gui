import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/hover_icon_button.dart';
import 'chat_context_bar.dart';
import 'chat_providers.dart';

/// Right-side slide-over panel for tuning system prompts and model inference parameters.
class ChatParamsDrawer extends ConsumerStatefulWidget {
  const ChatParamsDrawer({
    super.key,
    required this.conversationId,
    required this.onClose,
  });

  final int conversationId;
  final VoidCallback onClose;

  @override
  ConsumerState<ChatParamsDrawer> createState() => _ChatParamsDrawerState();
}

class _ChatParamsDrawerState extends ConsumerState<ChatParamsDrawer> {
  late TextEditingController _systemPromptController;

  // Inference parameter defaults
  double _temperature = 0.7;
  double _topP = 0.9;
  double _repeatPenalty = 1.1;
  int _numCtx = 4096;

  bool _isInitialized = false;
  bool _isSaving = false;

  static const List<int> _contextWindowOptions = [
    2048,
    4096,
    8192,
    16384,
    32768,
    65536,
  ];

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController();
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  void _loadFromConversation(String? systemPrompt, String? paramPreset) {
    if (_isInitialized) return;

    if (systemPrompt != null) {
      _systemPromptController.text = systemPrompt;
    }

    if (paramPreset != null && paramPreset.isNotEmpty) {
      try {
        final map = jsonDecode(paramPreset) as Map<String, dynamic>;
        if (map['temperature'] is num) {
          _temperature = (map['temperature'] as num).toDouble();
        }
        if (map['top_p'] is num) {
          _topP = (map['top_p'] as num).toDouble();
        }
        if (map['repeat_penalty'] is num) {
          _repeatPenalty = (map['repeat_penalty'] as num).toDouble();
        }
        if (map['num_ctx'] is num) {
          final ctx = (map['num_ctx'] as num).toInt();
          if (_contextWindowOptions.contains(ctx)) {
            _numCtx = ctx;
          }
        }
      } catch (_) {}
    }

    _isInitialized = true;
  }

  Future<void> _saveParameters() async {
    setState(() => _isSaving = true);

    final paramMap = {
      'temperature': _temperature,
      'top_p': _topP,
      'repeat_penalty': _repeatPenalty,
      'num_ctx': _numCtx,
    };

    final systemPrompt = _systemPromptController.text.trim();

    await ref.read(appDatabaseProvider).updateConversationParameters(
          widget.conversationId,
          systemPrompt: Value(systemPrompt.isEmpty ? null : systemPrompt),
          paramPreset: Value(jsonEncode(paramMap)),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parameters saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _resetDefaults() {
    setState(() {
      _temperature = 0.7;
      _topP = 0.9;
      _repeatPenalty = 1.1;
      _numCtx = 4096;
      _systemPromptController.clear();
    });
    _saveParameters();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final convAsync = ref.watch(conversationDetailProvider(widget.conversationId));

    convAsync.whenData((conv) {
      if (conv != null && !_isInitialized) {
        _loadFromConversation(conv.systemPrompt, conv.paramPreset);
      }
    });

    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          left: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 16, color: colors.accent),
                const SizedBox(width: 8),
                Text(
                  'Inference & System',
                  style: AppTypography.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const Spacer(),
                HoverIconButton(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  iconSize: 16,
                  tooltip: 'Close panel',
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),

          // Scrollable Settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // System Prompt Section
                _buildSectionHeader(
                  title: 'SYSTEM PROMPT',
                  description: 'Root instruction guiding tone, role, and formatting.',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _systemPromptController,
                  maxLines: 5,
                  minLines: 3,
                  style: AppTypography.ui(size: 13, height: 1.5, color: colors.text),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. You are an expert code reviewer. Provide concise, production-ready analysis...',
                    hintStyle: AppTypography.ui(
                      size: 13,
                      color: colors.textMuted,
                    ),
                    filled: true,
                    fillColor: colors.surfaceHover,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.r8,
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.r8,
                      borderSide: BorderSide(color: colors.border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.r8,
                      borderSide: BorderSide(color: colors.accent, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 16),

                // Temperature Slider
                _buildSliderRow(
                  label: 'TEMPERATURE',
                  valueString: _temperature.toStringAsFixed(2),
                  caption: 'Lower is precise and logical; higher is creative.',
                  colors: colors,
                  child: Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 40,
                    onChanged: (val) => setState(() => _temperature = val),
                  ),
                ),

                const SizedBox(height: 16),

                // Live Context Gauge Card
                DrawerContextGauge(conversationId: widget.conversationId),

                const SizedBox(height: 16),

                // Context Window (num_ctx)
                _buildSectionHeader(
                  title: 'CONTEXT WINDOW (num_ctx)',
                  description: 'Maximum token memory allocated for this chat.',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceHover,
                    borderRadius: AppRadius.r8,
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _numCtx,
                      isExpanded: true,
                      style: AppTypography.code(
                        size: 12,
                        color: colors.text,
                        weight: FontWeight.w500,
                      ),
                      dropdownColor: colors.surface,
                      borderRadius: AppRadius.r12,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colors.textMuted),
                      items: _contextWindowOptions.map((ctx) {
                        return DropdownMenuItem<int>(
                          value: ctx,
                          child: Text(
                            '$ctx tokens (${(ctx / 1024).round()}k)',
                            style: AppTypography.code(size: 12, color: colors.text),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _numCtx = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Top P Slider
                _buildSliderRow(
                  label: 'TOP P (NUCLEUS)',
                  valueString: _topP.toStringAsFixed(2),
                  caption: 'Filters probability distribution of candidate tokens.',
                  colors: colors,
                  child: Slider(
                    value: _topP,
                    min: 0.05,
                    max: 1.0,
                    divisions: 19,
                    onChanged: (val) => setState(() => _topP = val),
                  ),
                ),

                const SizedBox(height: 16),

                // Repeat Penalty Slider
                _buildSliderRow(
                  label: 'REPEAT PENALTY',
                  valueString: _repeatPenalty.toStringAsFixed(2),
                  caption: 'Penalizes loops and repetitive verbiage.',
                  colors: colors,
                  child: Slider(
                    value: _repeatPenalty,
                    min: 1.0,
                    max: 2.0,
                    divisions: 20,
                    onChanged: (val) => setState(() => _repeatPenalty = val),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                  color: colors.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: _resetDefaults,
                  child: Text(
                    'Reset Defaults',
                    style: AppTypography.ui(size: 13, color: colors.textMuted),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isSaving ? null : _saveParameters,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentTextOn,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accentTextOn,
                          ),
                        )
                      : Text(
                          'Save Params',
                          style: AppTypography.ui(
                            size: 13,
                            weight: FontWeight.w500,
                            color: colors.accentTextOn,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String description,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.code(
            size: 12,
            weight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: AppTypography.ui(
            size: 12,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueString,
    required String caption,
    required AppColors colors,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.code(
                size: 12,
                weight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: AppRadius.r6,
                border: Border.all(
                  color: colors.border,
                  width: 1,
                ),
              ),
              child: Text(
                valueString,
                style: AppTypography.code(
                  size: 12,
                  weight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: AppTypography.ui(
            size: 12,
            color: colors.textMuted,
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: colors.accent,
            inactiveTrackColor: colors.border,
            thumbColor: colors.accent,
            overlayColor: colors.accent.withValues(alpha: 0.15),
          ),
          child: child,
        ),
      ],
    );
  }
}
