import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
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
          _testResult = 'Connected successfully! Ollama v$version';
        } else {
          _testResult = 'Connection failed. Please ensure Ollama is running.';
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
        const SnackBar(content: Text('Server URL updated')),
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
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // -------------------------------------------------------------
              // Section 1: Ollama Server Connection
              // -------------------------------------------------------------
              Text(
                'Ollama Connection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                              size: 12,
                            ),
                            loading: () => const StatusDot(
                              status: ConnectionStatus.loading,
                              size: 12,
                            ),
                            error: (_, __) => const StatusDot(
                              status: ConnectionStatus.disconnected,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            connectionStatus.when(
                              data: (ok) => ok
                                  ? 'Connected to Ollama service'
                                  : 'Not reachable',
                              loading: () => 'Checking connection...',
                              error: (_, __) => 'Connection error',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Server URL',
                          hintText: 'http://localhost:11434',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_rounded),
                            tooltip: 'Save URL',
                            onPressed: _saveUrl,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (_) => _saveUrl(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Test Connection'),
                            onPressed: _isTesting ? null : _testConnection,
                          ),
                          const SizedBox(width: 12),
                          if (_testResult != null)
                            Expanded(
                              child: Text(
                                _testResult!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _testResult!.startsWith('Connected')
                                      ? const Color(0xFF22C55E)
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // -------------------------------------------------------------
              // Section 2: Appearance & Theme
              // -------------------------------------------------------------
              Text(
                'Appearance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text(
                            'Choose dark, light, or follow system theme',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto, size: 18),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: 18),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: 18),
                            label: Text('Dark'),
                          ),
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
              ),

              const SizedBox(height: 28),

              // -------------------------------------------------------------
              // Section 3: Keyboard Shortcuts
              // -------------------------------------------------------------
              Text(
                'Keyboard Shortcuts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _shortcutRow('Send Message', 'Enter'),
                      const Divider(height: 16),
                      _shortcutRow('New Line in Message', 'Shift + Enter'),
                      const Divider(height: 16),
                      _shortcutRow('Stop Generation', 'Stop button / Esc'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // -------------------------------------------------------------
              // Section 4: About
              // -------------------------------------------------------------
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ollama GUI',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A lightweight, cross-platform desktop interface for Ollama local models.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.code_rounded, size: 18),
                        label: const Text('GitHub Repository'),
                        onPressed: () {
                          launchUrl(
                            Uri.parse('https://github.com/Ahmedarain111/ollama-gui'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutRow(String action, String key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(action, style: const TextStyle(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
