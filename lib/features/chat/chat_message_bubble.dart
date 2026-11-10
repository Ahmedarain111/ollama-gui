import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../database/database.dart';
import 'chat_media_helper.dart';

/// Minimalist, document-like message presentation.
/// Assistant responses are rendered as clean editorial prose.
class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
  });

  final Message message;
  final bool isStreaming;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _hovered = false;

  bool get _isUser => widget.message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _isUser
                ? _UserMessage(content: widget.message.content)
                : _AssistantMessage(
                    content: widget.message.content,
                    message: widget.message,
                    isStreaming: widget.isStreaming,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    isHovered: _hovered,
                  ),
          ),
        ),
      ),
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsed = parseMessageContent(content);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 0.8,
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
                      borderRadius: BorderRadius.circular(6),
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
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: colorScheme.onSurface,
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
    required this.isDark,
    required this.colorScheme,
    required this.isHovered,
  });

  final String content;
  final Message message;
  final bool isStreaming;
  final bool isDark;
  final ColorScheme colorScheme;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final displayContent = isStreaming ? '$content▍' : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editorial Markdown Prose
        MarkdownBody(
          data: displayContent,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: colorScheme.onSurface,
            ),
            h1: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
            ),
            h2: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: colorScheme.onSurface,
            ),
            h3: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            code: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1F26) : const Color(0xFFF6F6F8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            codeblockPadding: const EdgeInsets.all(14),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  width: 2.5,
                ),
              ),
            ),
            blockquotePadding: const EdgeInsets.only(left: 14),
            tableBorder: TableBorder.all(
              color: colorScheme.outline.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          builders: {
            'code': _CodeBlockBuilder(isDark: isDark, colorScheme: colorScheme),
          },
        ),

        // Monospace Metadata & Quick Copy
        if (!isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                if (message.tokensPerSec != null)
                  Text(
                    '${message.tokensPerSec!.toStringAsFixed(1)} tok/s · ${message.totalTokens ?? 0} tokens',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),

                const Spacer(),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: isHovered ? 1.0 : 0.0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    mouseCursor: SystemMouseCursors.click,
                    hoverColor: colorScheme.surfaceContainerHighest,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied response'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.isDark, required this.colorScheme});

  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final raw = element.textContent.trimRight();
    final isBlock = element.attributes['class'] != null || raw.contains('\n');

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          raw,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: colorScheme.onSurface,
          ),
        ),
      );
    }

    final language = _parseLanguage(element.attributes['class'] ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F26) : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Language tag and Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language.isNotEmpty ? language : 'code',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: colorScheme.surfaceContainerHighest,
                  onTap: () => Clipboard.setData(ClipboardData(text: raw)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Syntax Highlighted Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              raw,
              language: language.isNotEmpty ? language : 'plaintext',
              theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
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
