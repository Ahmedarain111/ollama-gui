import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/database.dart';
import '../../database/database_provider.dart';
import 'chat_area.dart';
import 'chat_controller.dart';
import 'chat_input_bar.dart';
import 'chat_providers.dart';
import 'conversation_sidebar.dart';

/// Main chat screen: slim conversation sidebar + active chat workspace.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialConversationId});

  final int? initialConversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialConversationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeConversationProvider.notifier).state =
            widget.initialConversationId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConvId = ref.watch(activeConversationProvider);

    return Row(
      children: [
        // Sidebar (220px)
        const ConversationSidebar(),

        // Main Stage
        Expanded(
          child: activeConvId != null
              ? ChatArea(conversationId: activeConvId)
              : const _EmptyWorkspace(),
        ),
      ],
    );
  }
}

class _EmptyWorkspace extends ConsumerWidget {
  const _EmptyWorkspace();

  Future<void> _startConversation(
    BuildContext context,
    WidgetRef ref,
    String text, {
    List<String>? images,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (images == null || images.isEmpty)) return;

    final db = ref.read(appDatabaseProvider);
    final model = ref.read(selectedModelProvider);
    final now = DateTime.now();
    final title = trimmed.length > 36
        ? '${trimmed.substring(0, 36).trim()}...'
        : (trimmed.isNotEmpty ? trimmed : 'Image Analysis');

    final convId = await db.insertConversation(
      ConversationsCompanion(
        title: Value(title),
        model: Value(model),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    ref.read(activeConversationProvider.notifier).state = convId;
    final controller = ref.read(chatControllerProvider(convId));
    await controller.sendMessage(trimmed, model, images: images);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedModel = ref.watch(selectedModelProvider);
    final modelsAsync = ref.watch(installedModelsProvider);

    final installedList = modelsAsync.when(
      data: (m) => m,
      loading: () => [],
      error: (_, __) => [],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stylized Brand Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.surfaceContainerHighest,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 26,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 18),

                // Greeting Headline
                Text(
                  'Where shall we begin?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Interactive Model Selector Pill
                PopupMenuButton<String>(
                  tooltip: 'Select active model',
                  onSelected: (modelName) {
                    ref.read(selectedModelProvider.notifier).state = modelName;
                  },
                  itemBuilder: (context) {
                    if (installedList.isEmpty) {
                      return [
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('No models installed', style: TextStyle(fontSize: 12)),
                        ),
                      ];
                    }
                    return installedList.map((m) {
                      final isSelected = m.name == selectedModel;
                      return PopupMenuItem<String>(
                        value: m.name,
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_rounded : Icons.lens_blur_rounded,
                              size: 14,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            Text(
                              m.sizeGb,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.memory_rounded,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedModel,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 2x2 Prompt Starter Cards Grid
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _PromptStarterCard(
                              icon: Icons.lightbulb_outline_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              title: 'Explain Concept',
                              prompt:
                                  'Explain how local LLM quantization (Q4_K_M vs Q8_0) balances VRAM usage and perplexity.',
                              onTap: (prompt) =>
                                  _startConversation(context, ref, prompt),
                            ),
                            const SizedBox(height: 10),
                            _PromptStarterCard(
                              icon: Icons.code_rounded,
                              iconColor: const Color(0xFF38BDF8),
                              title: 'Code & Debug',
                              prompt:
                                  'Write a robust Dart streaming client that parses Ollama NDJSON tokens into real-time UI text.',
                              onTap: (prompt) =>
                                  _startConversation(context, ref, prompt),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _PromptStarterCard(
                                  icon: Icons.lightbulb_outline_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  title: 'Explain Concept',
                                  prompt:
                                      'Explain how local LLM quantization (Q4_K_M vs Q8_0) balances VRAM usage and perplexity.',
                                  onTap: (prompt) =>
                                      _startConversation(context, ref, prompt),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PromptStarterCard(
                                  icon: Icons.code_rounded,
                                  iconColor: const Color(0xFF38BDF8),
                                  title: 'Code & Debug',
                                  prompt:
                                      'Write a robust Dart streaming client that parses Ollama NDJSON tokens into real-time UI text.',
                                  onTap: (prompt) =>
                                      _startConversation(context, ref, prompt),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _PromptStarterCard(
                                  icon: Icons.edit_note_rounded,
                                  iconColor: const Color(0xFF818CF8),
                                  title: 'Draft & Summarize',
                                  prompt:
                                      'Draft a concise architectural brief highlighting the latency and privacy advantages of local AI models.',
                                  onTap: (prompt) =>
                                      _startConversation(context, ref, prompt),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PromptStarterCard(
                                  icon: Icons.architecture_rounded,
                                  iconColor: const Color(0xFFA78BFA),
                                  title: 'System Design',
                                  prompt:
                                      'Design an offline RAG pipeline architecture using local vector embeddings and SQLite.',
                                  onTap: (prompt) =>
                                      _startConversation(context, ref, prompt),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // Instant Prompt Input Field
                ChatInputBar(
                  onSend: (text, images) =>
                      _startConversation(context, ref, text, images: images),
                  onStop: () {},
                ),

                const SizedBox(height: 12),

                // Quick Hint / Library Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'Press Enter to start chat · or explore',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/models'),
                        child: Text(
                          '30+ Model Catalog',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptStarterCard extends StatefulWidget {
  const _PromptStarterCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String prompt;
  final ValueChanged<String> onTap;

  @override
  State<_PromptStarterCard> createState() => _PromptStarterCardState();
}

class _PromptStarterCardState extends State<_PromptStarterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.prompt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.5),
              width: 0.8,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 15,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: _isHovered ? colorScheme.primary : colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: _isHovered
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prompt,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

