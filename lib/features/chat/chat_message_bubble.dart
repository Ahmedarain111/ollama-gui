import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../database/database.dart';

/// Renders a single chat message bubble.
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
  bool get _isAssistant => widget.message.role == 'assistant';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Column(
          crossAxisAlignment: _isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Role label
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Text(
                _isUser ? 'You' : 'Assistant',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            // Message content
            if (_isUser)
              _UserBubble(
                content: widget.message.content,
                colorScheme: colorScheme,
              )
            else
              _AssistantBubble(
                content: widget.message.content,
                isStreaming: widget.isStreaming,
                isDark: isDark,
              ),
            // Footer row (hover actions + stats)
            if (_isAssistant && (_hovered || widget.isStreaming))
              _MessageFooter(
                message: widget.message,
                isStreaming: widget.isStreaming,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User bubble
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  const _UserBubble({
    required this.content,
    required this.colorScheme,
  });

  final String content;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: SelectableText(
        content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assistant bubble
// ---------------------------------------------------------------------------

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    required this.content,
    required this.isStreaming,
    required this.isDark,
  });

  final String content;
  final bool isStreaming;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Show cursor while streaming
    final displayContent =
        isStreaming ? '$content▍' : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: displayContent,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(
            Theme.of(context),
          ).copyWith(
            p: Theme.of(context).textTheme.bodyMedium,
            code: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              backgroundColor:
                  colorScheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            codeblockPadding: const EdgeInsets.all(16),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
          ),
          builders: {
            'code': _CodeBlockBuilder(isDark: isDark),
          },
          extensionSet: md.ExtensionSet(
            md.ExtensionSet.gitHubFlavored.blockSyntaxes,
            [
              md.EmojiSyntax(),
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Code block builder with syntax highlighting
// ---------------------------------------------------------------------------

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.isDark});

  final bool isDark;

  @override
  Widget? visitElementAfter(
      md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    // Try to extract language hint from the class name (e.g. "language-dart")
    String? language;
    final classes = element.attributes['class'];
    if (classes != null) {
      final match =
          RegExp(r'language-(\w+)').firstMatch(classes);
      language = match?.group(1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language label + copy button
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF282C34)
                  : const Color(0xFFEEEEEE),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  language ?? 'code',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: isDark
                        ? Colors.white54
                        : Colors.black54,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code),
              ],
            ),
          ),
          // Highlighted code
          HighlightView(
            code,
            language: language ?? 'plaintext',
            theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        setState(() => _copied = true);
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _copied ? Icons.check : Icons.copy,
            size: 14,
            color: _copied ? Colors.green : Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            _copied ? 'Copied!' : 'Copy',
            style: TextStyle(
              fontSize: 11,
              color: _copied ? Colors.green : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message footer
// ---------------------------------------------------------------------------

class _MessageFooter extends StatelessWidget {
  const _MessageFooter({
    required this.message,
    required this.isStreaming,
  });

  final Message message;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Copy message button
          _ActionChip(
            icon: Icons.copy_outlined,
            label: 'Copy',
            onTap: () => Clipboard.setData(
              ClipboardData(text: message.content),
            ),
          ),
          const SizedBox(width: 8),
          // Stats
          if (message.tokensPerSec != null && !isStreaming)
            Text(
              '${message.tokensPerSec!.toStringAsFixed(1)} tok/s'
              ' · ${message.totalTokens ?? 0} tokens',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.onSurface.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
