import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/ollama_process_manager.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../database/database_provider.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../../shared/widgets/status_dot.dart';
import '../chat/chat_providers.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _systemPromptController;

  String? _testResult;
  int? _pingMs;
  bool _isTesting = false;

  String? _detectedBinaryPath;
  List<RunningModel>? _runningModels;
  bool _isLoadingRunning = false;

  int? _conversationCount;
  int? _messageCount;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _urlController = TextEditingController(text: settings.baseUrl);
    _systemPromptController =
        TextEditingController(text: settings.defaultSystemPrompt);

    _detectBinary();
    _refreshRunningModels();
    _loadDbStats();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _detectBinary() async {
    final path = await OllamaProcessManager().findOllamaBinary();
    if (mounted) {
      setState(() => _detectedBinaryPath = path);
    }
  }

  Future<void> _refreshRunningModels() async {
    setState(() => _isLoadingRunning = true);
    final client = ref.read(ollamaClientProvider);
    try {
      final running = await client.listRunning();
      if (mounted) {
        setState(() {
          _runningModels = running;
          _isLoadingRunning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _runningModels = [];
          _isLoadingRunning = false;
        });
      }
    }
  }

  Future<void> _unloadModel(String modelName) async {
    final client = ref.read(ollamaClientProvider);
    await client.unloadModel(modelName);
    await _refreshRunningModels();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unloaded "$modelName" from VRAM'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadDbStats() async {
    final db = ref.read(appDatabaseProvider);
    final convCount = await db.getConversationCount();
    final msgCount = await db.getMessageCount();
    if (mounted) {
      setState(() {
        _conversationCount = convCount;
        _messageCount = msgCount;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final stopwatch = Stopwatch()..start();
    final client = ref.read(ollamaClientProvider);
    final version = await client.getVersion();
    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isTesting = false;
        if (version != null) {
          _pingMs = stopwatch.elapsedMilliseconds;
          _testResult = 'Connected (Ollama v$version, ${_pingMs}ms)';
        } else {
          _pingMs = null;
          _testResult = 'Connection failed';
        }
      });
      ref.invalidate(ollamaConnectionStatusProvider);
      _refreshRunningModels();
    }
  }

  void _saveUrl() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      ref.read(settingsNotifierProvider.notifier).updateBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server address saved'),
          duration: Duration(seconds: 1),
        ),
      );
      _testConnection();
    }
  }

  Future<void> _clearAllChats() async {
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          side: BorderSide(color: colors.border, width: 1),
        ),
        title: Text(
          'Clear all chat history?',
          style: AppTypography.ui(size: 16, weight: FontWeight.w600, color: colors.text),
        ),
        content: Text(
          'This will permanently delete all conversations and messages from your local database. Installed Ollama models will not be affected.',
          style: AppTypography.ui(size: 13, color: colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTypography.ui(size: 13, color: colors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: Text('Clear All', style: AppTypography.button(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await db.clearAllData();
      ref.read(activeConversationProvider.notifier).state = null;
      await _loadDbStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chat history cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportChatHistory() async {
    final db = ref.read(appDatabaseProvider);
    final data = await db.exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${data.length} conversations to clipboard (JSON)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String get _modelsStoragePath {
    if (Platform.isWindows) {
      return r'%USERPROFILE%\.ollama\models';
    }
    return '~/.ollama/models';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);
    final daemonStatus = ref.watch(ollamaServiceStatusProvider);
    final modelsAsync = ref.watch(installedModelsProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            children: [
              // -----------------------------------------------------------
              // Section 1: Ollama Server Connection
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Ollama Server'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        connectionStatus.when(
                          data: (ok) => StatusDot(
                            status: ok
                                ? ConnectionStatus.connected
                                : ConnectionStatus.disconnected,
                            size: 8,
                          ),
                          loading: () => const StatusDot(
                            status: ConnectionStatus.loading,
                            size: 8,
                          ),
                          error: (_, __) => const StatusDot(
                            status: ConnectionStatus.disconnected,
                            size: 8,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          connectionStatus.when(
                            data: (ok) => ok ? 'Online' : 'Unreachable',
                            loading: () => 'Checking...',
                            error: (_, __) => 'Offline',
                          ),
                          style: AppTypography.ui(
                            size: 13,
                            weight: FontWeight.w600,
                            color: colors.text,
                          ),
                        ),
                        if (_pingMs != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${_pingMs}ms latency)',
                            style: AppTypography.code(
                              size: 11,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_testResult != null)
                          Text(
                            _testResult!,
                            style: AppTypography.code(
                              size: 11,
                              weight: FontWeight.w500,
                              color: _testResult!.startsWith('Connected')
                                  ? colors.success
                                  : colors.error,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: AppTypography.code(size: 13, color: colors.text),
                            decoration: InputDecoration(
                              hintText: 'http://localhost:11434',
                              hintStyle: AppTypography.code(
                                size: 13,
                                color: colors.textMuted,
                              ),
                              filled: true,
                              fillColor: colors.surfaceHover,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            onSubmitted: (_) => _saveUrl(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: _saveUrl,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.accentTextOn,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          ),
                          child: Text('Save', style: AppTypography.button(color: colors.accentTextOn)),
                        ),
                        const SizedBox(width: 6),
                        HoverIconButton(
                          icon: Icons.refresh_rounded,
                          label: 'Test',
                          iconSize: 16,
                          enabled: !_isTesting,
                          tooltip: 'Test connection',
                          borderColor: colors.border,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          onTap: _testConnection,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 2: Local Daemon Supervisor & System Diagnostics
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Local Daemon & VRAM Inspector'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal_rounded, size: 16, color: colors.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Background Process: ollama serve',
                          style: AppTypography.ui(
                            size: 13,
                            weight: FontWeight.w600,
                            color: colors.text,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surfaceHover,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(
                              color: colors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            daemonStatus == OllamaServiceStatus.running
                                ? 'ACTIVE'
                                : (daemonStatus == OllamaServiceStatus.starting
                                    ? 'STARTING...'
                                    : 'STANDBY'),
                            style: AppTypography.code(
                              size: 10,
                              weight: FontWeight.w600,
                              color: daemonStatus == OllamaServiceStatus.running
                                  ? colors.success
                                  : colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'The application supervises the local Ollama daemon so models are immediately available upon launch.',
                      style: AppTypography.ui(
                        size: 12,
                        color: colors.textMuted,
                      ),
                    ),
                    if (_detectedBinaryPath != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text('Binary: ', style: AppTypography.caption(color: colors.textMuted)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                              border: Border.all(color: colors.border, width: 1),
                            ),
                            child: Text(
                              _detectedBinaryPath!,
                              style: AppTypography.code(size: 11, color: colors.text),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded, size: 15),
                          label: Text('Start / Recheck Daemon', style: AppTypography.button(color: colors.text)),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.surfaceHover,
                            foregroundColor: colors.text,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              side: BorderSide(color: colors.border, width: 1),
                            ),
                          ),
                          onPressed: () async {
                            final ok = await OllamaProcessManager().startIfNeeded(ref: ref);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Ollama daemon is running and reachable'
                                      : 'Could not connect to Ollama daemon'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                            _detectBinary();
                            _refreshRunningModels();
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        HoverIconButton(
                          icon: Icons.refresh_rounded,
                          label: _isLoadingRunning ? 'Loading...' : 'Scan VRAM',
                          iconSize: 15,
                          enabled: !_isLoadingRunning,
                          borderColor: colors.border,
                          tooltip: 'Check models loaded in VRAM',
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          onTap: _refreshRunningModels,
                        ),
                      ],
                    ),

                    // Running models in VRAM list
                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Models Loaded in VRAM (/api/ps):',
                      style: AppTypography.ui(size: 12, weight: FontWeight.w600, color: colors.text),
                    ),
                    const SizedBox(height: 6),
                    if (_runningModels == null || _runningModels!.isEmpty)
                      Text(
                        'No models currently residing in VRAM (Ollama unloads idle models automatically).',
                        style: AppTypography.caption(size: 12, color: colors.textMuted),
                      )
                    else
                      Column(
                        children: _runningModels!.map((m) {
                          final sizeGb = (m.size / (1024 * 1024 * 1024)).toStringAsFixed(1);
                          return Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                              border: Border.all(color: colors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.memory_rounded, size: 14, color: colors.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: AppTypography.code(size: 12, weight: FontWeight.w600, color: colors.text),
                                      ),
                                      Text(
                                        'Size: ${sizeGb}GB · Expires: ${m.expiresAt.toLocal().toString().split('.').first}',
                                        style: AppTypography.caption(size: 11, color: colors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  icon: const Icon(Icons.eject_rounded, size: 13),
                                  label: Text('Unload', style: AppTypography.caption(size: 11, color: colors.text)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.text,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.chip),
                                      side: BorderSide(color: colors.border, width: 1),
                                    ),
                                  ),
                                  onPressed: () => _unloadModel(m.name),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    // Model storage path hint
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text('Models Storage:', style: AppTypography.caption(color: colors.textMuted)),
                        const SizedBox(width: 6),
                        SelectableText(
                          _modelsStoragePath,
                          style: AppTypography.code(size: 11, color: colors.text),
                        ),
                        const SizedBox(width: 8),
                        HoverIconButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          iconSize: 13,
                          tooltip: 'Copy storage path',
                          borderColor: colors.border,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _modelsStoragePath));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied models path to clipboard'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 3: Model & Inference Defaults
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Model & Generation Defaults'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Default Model Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Default Model', style: AppTypography.ui(size: 13, weight: FontWeight.w600, color: colors.text)),
                              const SizedBox(height: 2),
                              Text('Preferred model chosen automatically for new chats', style: AppTypography.caption(color: colors.textMuted)),
                            ],
                          ),
                        ),
                        modelsAsync.when(
                          data: (models) {
                            return DropdownButton<String?>(
                              value: (settings.defaultModel != null && models.any((m) => m.name == settings.defaultModel))
                                  ? settings.defaultModel
                                  : null,
                              dropdownColor: colors.surface,
                              style: AppTypography.ui(size: 13, color: colors.text),
                              hint: Text('Auto (First Available)', style: AppTypography.ui(size: 13, color: colors.textMuted)),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Auto (First Available)', style: AppTypography.ui(size: 13, color: colors.textMuted)),
                                ),
                                ...models.map(
                                  (m) => DropdownMenuItem<String?>(
                                    value: m.name,
                                    child: Text(m.name, style: AppTypography.ui(size: 13, color: colors.text)),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                notifier.updateDefaultModel(val);
                              },
                            );
                          },
                          loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => Text('No models', style: AppTypography.caption(color: colors.error)),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: AppSpacing.md),

                    // Default System Prompt
                    Text('Global System Prompt', style: AppTypography.ui(size: 13, weight: FontWeight.w600, color: colors.text)),
                    const SizedBox(height: 2),
                    Text(
                      'Prepended to all newly created conversations as the base instruction persona.',
                      style: AppTypography.caption(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _systemPromptController,
                      maxLines: 3,
                      style: AppTypography.ui(size: 13, color: colors.text),
                      decoration: InputDecoration(
                        hintText: 'e.g. You are a helpful, respectful, and concise assistant...',
                        hintStyle: AppTypography.ui(size: 13, color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surfaceHover,
                        contentPadding: const EdgeInsets.all(12),
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
                      onChanged: (val) => notifier.updateDefaultSystemPrompt(val),
                    ),
                    const SizedBox(height: 8),

                    // Preset Quick Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _presetChip(context, 'Senior Developer', 'You are an expert senior software engineer. Provide concise, clean, production-ready code with explanations.'),
                        _presetChip(context, 'Concise & Direct', 'Answer directly and concisely. Omit conversational filler, disclaimers, and unnecessary preamble.'),
                        _presetChip(context, 'Creative Writer', 'You are an imaginative creative writer with an engaging, vivid prose style.'),
                        _presetChip(context, 'Clear Prompt', ''),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: AppSpacing.md),

                    // Inference Parameters
                    Text('Inference Parameters (Defaults)', style: AppTypography.ui(size: 13, weight: FontWeight.w600, color: colors.text)),
                    const SizedBox(height: AppSpacing.sm),

                    // Temperature Slider
                    Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text('Temperature: ${settings.defaultTemperature.toStringAsFixed(2)}', style: AppTypography.ui(size: 12, color: colors.text)),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.defaultTemperature,
                            min: 0.0,
                            max: 2.0,
                            divisions: 40,
                            activeColor: colors.accent,
                            onChanged: (v) => notifier.updateDefaultTemperature(double.parse(v.toStringAsFixed(2))),
                          ),
                        ),
                      ],
                    ),

                    // Top-P Slider
                    Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text('Top P: ${settings.defaultTopP.toStringAsFixed(2)}', style: AppTypography.ui(size: 12, color: colors.text)),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.defaultTopP,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            activeColor: colors.accent,
                            onChanged: (v) => notifier.updateDefaultTopP(double.parse(v.toStringAsFixed(2))),
                          ),
                        ),
                      ],
                    ),

                    // Repeat Penalty Slider
                    Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text('Repeat Penalty: ${settings.defaultRepeatPenalty.toStringAsFixed(2)}', style: AppTypography.ui(size: 12, color: colors.text)),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.defaultRepeatPenalty,
                            min: 1.0,
                            max: 1.5,
                            divisions: 20,
                            activeColor: colors.accent,
                            onChanged: (v) => notifier.updateDefaultRepeatPenalty(double.parse(v.toStringAsFixed(2))),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Context Window & Keep-Alive Dropdowns Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Context Window (num_ctx)', style: AppTypography.caption(color: colors.textMuted)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                initialValue: settings.defaultNumCtx,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: colors.surfaceHover,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide(color: colors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide(color: colors.border)),
                                ),
                                dropdownColor: colors.surface,
                                style: AppTypography.ui(size: 13, color: colors.text),
                                items: const [
                                  DropdownMenuItem(value: 2048, child: Text('2,048 tokens')),
                                  DropdownMenuItem(value: 4096, child: Text('4,096 tokens (Default)')),
                                  DropdownMenuItem(value: 8192, child: Text('8,192 tokens')),
                                  DropdownMenuItem(value: 16384, child: Text('16,384 tokens')),
                                  DropdownMenuItem(value: 32768, child: Text('32,768 tokens')),
                                  DropdownMenuItem(value: 65536, child: Text('65,536 tokens')),
                                ],
                                onChanged: (v) {
                                  if (v != null) notifier.updateDefaultNumCtx(v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Keep-Alive in VRAM', style: AppTypography.caption(color: colors.textMuted)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: settings.keepAlive,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: colors.surfaceHover,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide(color: colors.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input), borderSide: BorderSide(color: colors.border)),
                                ),
                                dropdownColor: colors.surface,
                                style: AppTypography.ui(size: 13, color: colors.text),
                                items: const [
                                  DropdownMenuItem(value: '5m', child: Text('5 minutes (Default)')),
                                  DropdownMenuItem(value: '15m', child: Text('15 minutes')),
                                  DropdownMenuItem(value: '30m', child: Text('30 minutes')),
                                  DropdownMenuItem(value: '1h', child: Text('1 hour')),
                                  DropdownMenuItem(value: '-1', child: Text('Forever (keep loaded)')),
                                  DropdownMenuItem(value: '0', child: Text('0 (unload immediately)')),
                                ],
                                onChanged: (v) {
                                  if (v != null) notifier.updateKeepAlive(v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded, size: 14),
                        label: Text('Reset to Defaults', style: AppTypography.caption(color: colors.textMuted)),
                        onPressed: () {
                          notifier.resetInferenceDefaults();
                          _systemPromptController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inference parameters reset to defaults'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 4: Chat & Composer Behavior
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Chat & Composer Behavior'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  children: [
                    // Send message shortcut preference
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send Message Keybinding', style: AppTypography.ui(size: 13, color: colors.text)),
                              const SizedBox(height: 2),
                              Text(
                                settings.sendOnEnter
                                    ? 'Enter sends message · Shift+Enter adds newline'
                                    : '⌘/Ctrl+Enter sends message · Enter adds newline',
                                style: AppTypography.caption(color: colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
                            textStyle: AppTypography.ui(size: 12, weight: FontWeight.w500),
                            selectedBackgroundColor: colors.accent.withValues(alpha: 0.15),
                            selectedForegroundColor: colors.accent,
                            side: BorderSide(color: colors.border, width: 1),
                          ),
                          segments: const [
                            ButtonSegment(value: true, label: Text('Enter')),
                            ButtonSegment(value: false, label: Text('Ctrl+Enter')),
                          ],
                          selected: {settings.sendOnEnter},
                          onSelectionChanged: (val) => notifier.updateSendOnEnter(val.first),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: colors.border),

                    // Live Token Streaming Toggle
                    _settingSwitchRow(
                      title: 'Live Token Streaming',
                      subtitle: 'Stream generated words in real-time token-by-token',
                      value: settings.streamResponse,
                      colors: colors,
                      onChanged: (val) => notifier.updateStreamResponse(val),
                    ),

                    Divider(height: 20, color: colors.border),

                    // Show Generation Statistics Toggle
                    _settingSwitchRow(
                      title: 'Show Performance Statistics',
                      subtitle: 'Display tokens/second speed and token count badges under responses',
                      value: settings.showGenerationStats,
                      colors: colors,
                      onChanged: (val) => notifier.updateShowGenerationStats(val),
                    ),

                    Divider(height: 20, color: colors.border),

                    // Auto-scroll toggle
                    _settingSwitchRow(
                      title: 'Auto-Scroll During Generation',
                      subtitle: 'Smoothly glide viewport to follow stream as new tokens appear',
                      value: settings.autoScroll,
                      colors: colors,
                      onChanged: (val) => notifier.updateAutoScroll(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 5: Appearance & Personalization
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Appearance & Personalization'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  children: [
                    // Theme Mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Theme Mode', style: AppTypography.ui(size: 13, color: colors.text)),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
                            textStyle: AppTypography.ui(size: 12, weight: FontWeight.w500),
                            selectedBackgroundColor: colors.accent.withValues(alpha: 0.15),
                            selectedForegroundColor: colors.accent,
                            side: BorderSide(color: colors.border, width: 1),
                          ),
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, label: Text('System')),
                            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                          ],
                          selected: {settings.themeMode},
                          onSelectionChanged: (modes) => notifier.updateThemeMode(modes.first),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: colors.border),

                    // Accent Color Palette
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Accent Color', style: AppTypography.ui(size: 13, color: colors.text)),
                            const Spacer(),
                            Text(settings.accentColor.label, style: AppTypography.caption(color: colors.accent)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: kAccentColors.map((opt) {
                            final isSelected = opt.key == settings.accentColorKey;
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => notifier.updateAccentColor(opt.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? opt.darkColor.withValues(alpha: 0.15) : colors.surfaceHover,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? opt.darkColor : colors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: opt.darkColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      opt.label,
                                      style: AppTypography.ui(
                                        size: 12,
                                        weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? colors.text : colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: colors.border),

                    // Chat Font Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chat Message Text Size', style: AppTypography.ui(size: 13, color: colors.text)),
                            const SizedBox(height: 2),
                            Text('${settings.chatFontSize.toInt()}px body prose', style: AppTypography.caption(color: colors.textMuted)),
                          ],
                        ),
                        SegmentedButton<double>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
                            textStyle: AppTypography.ui(size: 12, weight: FontWeight.w500),
                            selectedBackgroundColor: colors.accent.withValues(alpha: 0.15),
                            selectedForegroundColor: colors.accent,
                            side: BorderSide(color: colors.border, width: 1),
                          ),
                          segments: const [
                            ButtonSegment(value: 13.0, label: Text('Compact (13px)')),
                            ButtonSegment(value: 15.0, label: Text('Standard (15px)')),
                            ButtonSegment(value: 17.0, label: Text('Comfortable (17px)')),
                          ],
                          selected: {settings.chatFontSize},
                          onSelectionChanged: (sizes) => notifier.updateChatFontSize(sizes.first),
                        ),
                      ],
                    ),

                    Divider(height: 20, color: colors.border),

                    // Top Bar System Usage Monitor Toggle
                    _settingSwitchRow(
                      title: 'Top Bar Resource Monitor',
                      subtitle: 'Display real-time CPU, GPU, RAM, and VRAM monitors in the persistent top bar',
                      value: settings.showSystemUsageBar,
                      colors: colors,
                      onChanged: (val) => notifier.updateShowSystemUsage(val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 6: Data & Storage Management
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Data & Storage Management'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                              border: Border.all(color: colors.border, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Conversations', style: AppTypography.caption(color: colors.textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_conversationCount ?? '—'}',
                                  style: AppTypography.ui(size: 18, weight: FontWeight.w700, color: colors.text),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceHover,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                              border: Border.all(color: colors.border, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stored Messages', style: AppTypography.caption(color: colors.textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_messageCount ?? '—'}',
                                  style: AppTypography.ui(size: 18, weight: FontWeight.w700, color: colors.text),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'All chats and message history are kept securely on this device in local SQLite storage.',
                      style: AppTypography.caption(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 15),
                          label: Text('Export All Chats (JSON)', style: AppTypography.button(color: colors.text)),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.surfaceHover,
                            foregroundColor: colors.text,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              side: BorderSide(color: colors.border, width: 1),
                            ),
                          ),
                          onPressed: _exportChatHistory,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        OutlinedButton.icon(
                          icon: Icon(Icons.delete_sweep_rounded, size: 15, color: colors.error),
                          label: Text('Clear All History', style: AppTypography.button(color: colors.error)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                            side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          ),
                          onPressed: _clearAllChats,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 7: Keyboard Shortcuts Cheat Sheet
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Shortcuts Reference'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Column(
                  children: [
                    _shortcutRow(context, 'Send message', settings.sendOnEnter ? '↵' : '⌘/Ctrl + ↵', colors),
                    Divider(height: 14, color: colors.border),
                    _shortcutRow(context, 'New line', settings.sendOnEnter ? '⇧ ↵' : '↵', colors),
                    Divider(height: 14, color: colors.border),
                    _shortcutRow(context, 'Stop generation', 'Esc', colors),
                    Divider(height: 14, color: colors.border),
                    _shortcutRow(context, 'New chat', '⌘/Ctrl + N', colors),
                    Divider(height: 14, color: colors.border),
                    _shortcutRow(context, 'Open models library', '⌘/Ctrl + M', colors),
                    Divider(height: 14, color: colors.border),
                    _shortcutRow(context, 'Open settings', '⌘/Ctrl + ,', colors),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // -----------------------------------------------------------
              // Section 8: About & Links
              // -----------------------------------------------------------
              const _SectionTitle(title: 'About'),
              const SizedBox(height: AppSpacing.sm),
              _CardContainer(
                colors: colors,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ollama Desktop v0.1.0',
                            style: AppTypography.ui(size: 14, weight: FontWeight.w600, color: colors.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A native, minimalist desktop workstation for local AI models.',
                            style: AppTypography.caption(
                              size: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: colors.surfaceHover,
                      onTap: () {
                        launchUrl(
                          Uri.parse('https://ollama.com/library'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ollama Library',
                              style: AppTypography.ui(
                                size: 12,
                                weight: FontWeight.w500,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_outward_rounded, size: 12, color: colors.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: colors.surfaceHover,
                      onTap: () {
                        launchUrl(
                          Uri.parse('https://github.com/Ahmedarain111/ollama-gui'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GitHub',
                              style: AppTypography.ui(
                                size: 12,
                                weight: FontWeight.w500,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_outward_rounded, size: 12, color: colors.accent),
                          ],
                        ),
                      ),
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

  Widget _presetChip(BuildContext context, String label, String prompt) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.chip),
      onTap: () {
        _systemPromptController.text = prompt;
        ref.read(settingsNotifierProvider.notifier).updateDefaultSystemPrompt(prompt);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceHover,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.caption(size: 11, color: colors.text),
        ),
      ),
    );
  }

  Widget _settingSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required AppColors colors,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.ui(size: 13, color: colors.text)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption(color: colors.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: colors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _shortcutRow(BuildContext context, String action, String key, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(action, style: AppTypography.ui(size: 13, color: colors.text)),
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
            key,
            style: AppTypography.code(
              size: 11,
              weight: FontWeight.w500,
              color: colors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.child, required this.colors});

  final Widget child;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      title,
      style: AppTypography.ui(
        size: 12,
        weight: FontWeight.w600,
        color: colors.textMuted,
        letterSpacing: -0.1,
      ),
    );
  }
}
