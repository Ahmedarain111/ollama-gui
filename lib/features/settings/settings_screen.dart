import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../shared/widgets/hover_icon_button.dart';
import '../../shared/widgets/status_dot.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  String? _testResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(ollamaBaseUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final client = ref.read(ollamaClientProvider);
    final version = await client.getVersion();

    if (mounted) {
      setState(() {
        _isTesting = false;
        if (version != null) {
          _testResult = 'Connected (Ollama v$version)';
        } else {
          _testResult = 'Connection failed';
        }
      });
      ref.invalidate(ollamaConnectionStatusProvider);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentTheme = ref.watch(themeModeProvider);
    final connectionStatus = ref.watch(ollamaConnectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              // -----------------------------------------------------------
              // Section: Server Connection
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Ollama Server'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(16),
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
                        const SizedBox(width: 8),
                        Text(
                          connectionStatus.when(
                            data: (ok) => ok ? 'Online' : 'Unreachable',
                            loading: () => 'Checking...',
                            error: (_, __) => 'Offline',
                          ),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_testResult != null)
                          Text(
                            _testResult!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: _testResult!.startsWith('Connected')
                                  ? const Color(0xFF10B981)
                                  : colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'http://localhost:11434',
                            ),
                            onSubmitted: (_) => _saveUrl(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _saveUrl,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Save', style: TextStyle(fontSize: 12.5)),
                        ),
                        const SizedBox(width: 6),
                        HoverIconButton(
                          icon: Icons.refresh_rounded,
                          label: 'Test',
                          iconSize: 16,
                          enabled: !_isTesting,
                          tooltip: 'Test connection',
                          borderColor: colorScheme.outline,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          onTap: _testConnection,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // -----------------------------------------------------------
              // Section: Appearance
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Theme'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Interface mode', style: TextStyle(fontSize: 13)),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {currentTheme},
                      onSelectionChanged: (modes) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .updateThemeMode(modes.first);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // -----------------------------------------------------------
              // Section: Keyboard Shortcuts
              // -----------------------------------------------------------
              const _SectionTitle(title: 'Shortcuts'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    _shortcutRow('Send message', '↵'),
                    Divider(height: 14, color: colorScheme.outline.withValues(alpha: 0.3)),
                    _shortcutRow('New line', '⇧ ↵'),
                    Divider(height: 14, color: colorScheme.outline.withValues(alpha: 0.3)),
                    _shortcutRow('Stop generation', 'Esc'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // -----------------------------------------------------------
              // Section: About
              // -----------------------------------------------------------
              const _SectionTitle(title: 'About'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ollama Desktop',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A lightweight native GUI for local LLMs.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_outward_rounded, size: 12, color: colorScheme.primary),
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

  Widget _shortcutRow(String action, String key) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(action, style: const TextStyle(fontSize: 12.5)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        letterSpacing: -0.1,
      ),
    );
  }
}
