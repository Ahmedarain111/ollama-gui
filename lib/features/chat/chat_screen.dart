import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
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
    final colors = context.appColors;
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean App Mark
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.r12,
                    border: Border.all(
                      color: colors.border,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 24,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 16),

                // Greeting Headline
                Text(
                  'Where shall we begin?',
                  style: AppTypography.ui(
                    size: 22,
                    weight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),

                // Interactive Model Selector Pill
                PopupMenuButton<String>(
                  tooltip: 'Select active model',
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.r12,
                    side: BorderSide(color: colors.border, width: 1),
                  ),
                  onSelected: (modelName) {
                    ref.read(selectedModelProvider.notifier).state = modelName;
                  },
                  itemBuilder: (context) {
                    if (installedList.isEmpty) {
                      return [
                        PopupMenuItem(
                          enabled: false,
                          child: Text(
                            'No models installed',
                            style: AppTypography.ui(size: 13, color: colors.textMuted),
                          ),
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
                              color: isSelected ? colors.accent : colors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m.name,
                                style: AppTypography.ui(
                                  size: 13,
                                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? colors.accent : colors.text,
                                ),
                              ),
                            ),
                            Text(
                              m.sizeGb,
                              style: AppTypography.code(
                                size: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadius.r8,
                      border: Border.all(
                        color: colors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.memory_rounded,
                          size: 14,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedModel,
                          style: AppTypography.code(
                            size: 12,
                            weight: FontWeight.w500,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: colors.textMuted,
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
                              title: 'Explain Concept',
                              prompt:
                                  'Explain how local LLM quantization (Q4_K_M vs Q8_0) balances VRAM usage and perplexity.',
                              onTap: (prompt) =>
                                  _startConversation(context, ref, prompt),
                            ),
                            const SizedBox(height: 12),
                            _PromptStarterCard(
                              icon: Icons.code_rounded,
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

                const SizedBox(height: 24),

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
                      style: AppTypography.ui(
                        size: 12,
                        color: colors.textMuted,
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/models'),
                        child: Text(
                          '30+ Model Catalog',
                          style: AppTypography.ui(
                            size: 12,
                            weight: FontWeight.w500,
                            color: colors.accent,
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
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  final IconData icon;
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
    final colors = context.appColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(widget.prompt),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? colors.surfaceHover : colors.surface,
            borderRadius: AppRadius.r12,
            border: Border.all(
              color: _isHovered ? colors.accent : colors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.surfaceHover,
                      borderRadius: AppRadius.r6,
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 15,
                      color: _isHovered ? colors.accent : colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: _isHovered ? colors.accent : colors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: _isHovered ? colors.accent : colors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prompt,
                style: AppTypography.ui(
                  size: 13,
                  height: 1.4,
                  color: colors.textMuted,
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
