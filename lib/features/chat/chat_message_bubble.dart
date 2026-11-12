import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../database/database.dart';
import '../settings/settings_providers.dart';
import 'chat_media_helper.dart';

/// Minimalist, document-like message presentation.
/// Assistant responses are rendered as clean editorial prose.
class ChatMessageBubble extends ConsumerStatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  final Message message;
  final bool isStreaming;

  @override
  ConsumerState<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends ConsumerState<ChatMessageBubble> {
  bool _hovered = false;

  bool get _isUser => widget.message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final fontSize = settings.chatFontSize;
    final showStats = settings.showGenerationStats;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _isUser
                ? _UserMessage(
                    content: widget.message.content,
                    fontSize: fontSize,
                  )
                : _AssistantMessage(
                    content: widget.message.content,
                    message: widget.message,
                    isStreaming: widget.isStreaming,
                    isHovered: _hovered,
                    fontSize: fontSize,
                    showStats: showStats,
                  ),
          ),
        ),
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({
    required this.content,
    required this.fontSize,
  });

  final String content;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final parsed = parseMessageContent(content);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.r12,
          border: Border.all(
            color: colors.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (parsed.images != null && parsed.images!.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parsed.images!.map((imgBase64) {
                  try {
                    final bytes = base64Decode(imgBase64);
                    return ClipRRect(
                      borderRadius: AppRadius.r8,
                      child: Image.memory(
                        bytes,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                }).toList(),
              ),
              if (parsed.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (parsed.text.isNotEmpty)
              SelectableText(
                parsed.text,
                style: AppTypography.ui(
                  size: fontSize,
                  height: 1.6,
                  color: colors.text,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({
    required this.content,
    required this.message,
    required this.isStreaming,
    required this.isHovered,
    required this.fontSize,
    required this.showStats,
  });

  final String content;
  final Message message;
  final bool isStreaming;
  final bool isHovered;
  final double fontSize;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Markdown Prose
        MarkdownBody(
          data: content,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: AppTypography.ui(
              size: fontSize,
              height: 1.6,
              color: colors.text,
            ),
            h1: AppTypography.ui(
              size: 22,
              weight: FontWeight.w600,
              color: colors.text,
            ),
            h2: AppTypography.ui(
              size: 18,
              weight: FontWeight.w600,
              color: colors.text,
            ),
            h3: AppTypography.ui(
              size: fontSize,
              weight: FontWeight.w600,
              color: colors.text,
            ),
            listBullet: AppTypography.ui(
              size: fontSize,
              color: colors.text,
            ),
            a: TextStyle(
              fontFamily: AppTypography.uiFontFamily,
              fontSize: 15,
              color: colors.accent,
              decoration: TextDecoration.underline,
            ),
            code: AppTypography.code(
              size: 13,
              color: colors.text,
              letterSpacing: -0.2,
            ),
            codeblockDecoration: BoxDecoration(
              color: colors.codeBg,
              borderRadius: AppRadius.r12,
              border: Border.all(
                color: colors.border,
                width: 1,
              ),
            ),
            codeblockPadding: const EdgeInsets.all(16),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colors.border,
                  width: 3,
                ),
              ),
            ),
            blockquotePadding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            blockquote: AppTypography.ui(
              size: 15,
              height: 1.6,
              color: colors.textMuted,
            ),
            tableBorder: TableBorder.all(
              color: colors.border,
              width: 1,
            ),
            tableHead: AppTypography.ui(
              size: 13,
              weight: FontWeight.w600,
              color: colors.text,
            ),
            tableBody: AppTypography.ui(
              size: 13,
              color: colors.text,
            ),
            tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          builders: {
            'code': _CodeBlockBuilder(isDark: isDark, colors: colors),
          },
        ),

        // Subtle blinking caret when streaming
        if (isStreaming)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: _BlinkingCaret(),
          ),

        // Monospace Metadata & Hover Actions
        if (!isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (showStats && message.tokensPerSec != null && message.tokensPerSec! > 0)
                  Text(
                    '${message.tokensPerSec!.toStringAsFixed(1)} tok/s · ${message.totalTokens ?? 0} tokens',
                    style: AppTypography.code(
                      size: 12,
                      color: colors.textMuted,
                    ),
                  ),

                const Spacer(),

                AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: isHovered ? 1.0 : 0.0,
                  child: FocusableActionDetector(
                    mouseCursor: SystemMouseCursors.click,
                    child: InkWell(
                      borderRadius: AppRadius.r6,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied response to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.r6,
                          border: Border.all(color: colors.border, width: 1),
                          color: colors.surface,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Copy',
                              style: AppTypography.ui(
                                size: 12,
                                color: colors.textMuted,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Subtle blinking caret indicator for streaming assistant output.
class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret();

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 7,
        height: 15,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.isDark, required this.colors});

  final bool isDark;
  final AppColors colors;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final raw = element.textContent.trimRight();
    final isBlock = element.attributes['class'] != null || raw.contains('\n');

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.codeBg,
          borderRadius: AppRadius.r6,
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Text(
          raw,
          style: AppTypography.code(
            size: 13,
            color: colors.text,
          ),
        ),
      );
    }

    final language = _parseLanguage(element.attributes['class'] ?? '');

    final baseHighlightTheme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final highlightTheme = Map<String, TextStyle>.from(baseHighlightTheme)
      ..['root'] = TextStyle(
        backgroundColor: colors.codeBg,
        color: colors.text,
      );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colors.codeBg,
        borderRadius: AppRadius.r12,
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Language tag and Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                Text(
                  language.isNotEmpty ? language : 'code',
                  style: AppTypography.code(
                    size: 12,
                    color: colors.textMuted,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: AppRadius.r6,
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: raw));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: AppTypography.ui(
                            size: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal scrollable syntax-highlighted code body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: HighlightView(
              raw,
              language: language.isNotEmpty ? language : 'plaintext',
              theme: highlightTheme,
              textStyle: AppTypography.code(
                size: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _parseLanguage(String classAttr) {
    const prefix = 'language-';
    final parts = classAttr.split(' ');
    for (final part in parts) {
      if (part.startsWith(prefix)) {
        return part.substring(prefix.length);
      }
    }
    return '';
  }
}
