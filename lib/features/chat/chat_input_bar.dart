import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../settings/settings_providers.dart';
import 'chat_providers.dart';

/// Minimal, centered input bar for drafting messages with optional image attachments.
class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onStop,
  });

  final Future<void> Function(String text, List<String>? images) onSend;
  final VoidCallback onStop;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _attachedImages = [];
  bool _canSend = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newImages = <String>[];
        for (final file in result.files) {
          Uint8List? bytes = file.bytes;
          if (bytes == null && file.path != null) {
            bytes = await File(file.path!).readAsBytes();
          }
          if (bytes != null) {
            newImages.add(base64Encode(bytes));
          }
        }
        if (newImages.isNotEmpty) {
          setState(() {
            _attachedImages.addAll(newImages);
            _canSend = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
      _canSend = _textController.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    final images = List<String>.from(_attachedImages);
    setState(() {
      _attachedImages.clear();
      _canSend = false;
    });
    _textController.clear();
    widget.onSend(text, images.isNotEmpty ? images : null);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isStreaming = ref.watch(isStreamingProvider);
    final stats = ref.watch(streamingStatsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final sendOnEnter = settings.sendOnEnter;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streaming status
              if (isStreaming && stats != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generating · ${stats.tokensPerSec.toStringAsFixed(1)} tok/s (${stats.totalTokens} tokens)',
                        style: AppTypography.code(
                          size: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

              // Attached Images Preview Strip
              if (_attachedImages.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final bytes = base64Decode(_attachedImages[i]);
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.r8,
                            child: Image.memory(
                              bytes,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: colors.bg.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 12,
                                    color: colors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Input Container with 12px radius and 1px border that turns accent on focus
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.r12,
                  border: Border.all(
                    color: _isFocused ? colors.accent : colors.border,
                    width: _isFocused ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Column(
                  children: [
                    KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          final isModifierPressed =
                              HardwareKeyboard.instance.isControlPressed ||
                              HardwareKeyboard.instance.isMetaPressed;
                          final shouldSend = sendOnEnter
                              ? !HardwareKeyboard.instance.isShiftPressed
                              : isModifierPressed;

                          if (shouldSend) {
                            if (!isStreaming && _canSend) {
                              _handleSend();
                            }
                          }
                        }
                      },
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 7,
                        style: AppTypography.ui(
                          size: 14,
                          height: 1.5,
                          color: colors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: isStreaming
                              ? 'Model is replying...'
                              : 'Ask $selectedModel...',
                          hintStyle: AppTypography.ui(
                            size: 14,
                            color: colors.textMuted,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom Controls Row
                    Row(
                      children: [
                        // Image attachment button
                        HoverIconButton(
                          icon: Icons.image_outlined,
                          label: 'Image',
                          iconSize: 16,
                          tooltip: 'Attach images (Vision models)',
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          onTap: _pickImages,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          sendOnEnter ? '↵ send · ⇧↵ newline' : '⌘/Ctrl+↵ send · ↵ newline',
                          style: AppTypography.code(
                            size: 12,
                            color: colors.textMuted,
                          ),
                        ),

                        const Spacer(),

                        // Send / Stop button (turns into Stop button in accent when generating)
                        if (isStreaming)
                          _ComposerActionButton(
                            icon: Icons.stop_rounded,
                            label: 'Stop',
                            accentFill: true,
                            onTap: widget.onStop,
                          )
                        else
                          _ComposerActionButton(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Send',
                            enabled: _canSend,
                            accentFill: _canSend,
                            onTap: _canSend ? _handleSend : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatefulWidget {
  const _ComposerActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.accentFill = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool accentFill;
  final VoidCallback? onTap;

  @override
  State<_ComposerActionButton> createState() => _ComposerActionButtonState();
}

class _ComposerActionButtonState extends State<_ComposerActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Color bg;
    final Color fg;
    if (widget.accentFill) {
      bg = _hovered ? colors.accentHover : colors.accent;
      fg = colors.accentTextOn;
    } else {
      bg = _hovered ? colors.surfaceHover : Colors.transparent;
      fg = widget.enabled ? colors.text : colors.textMuted;
    }

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.enabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.enabled) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.r8,
              border: Border.all(
                color: widget.accentFill ? Colors.transparent : colors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fg),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: AppTypography.ui(
                    size: 13,
                    weight: FontWeight.w500,
                    color: fg,
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
