import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

class SettingsState {
  const SettingsState({
    required this.baseUrl,
    required this.themeMode,
  });

  final String baseUrl;
  final ThemeMode themeMode;

  SettingsState copyWith({
    String? baseUrl,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this.ref)
      : super(const SettingsState(
          baseUrl: 'http://localhost:11434',
          themeMode: ThemeMode.dark,
        )) {
    _loadSettings();
  }

  final Ref ref;

  static const _keyBaseUrl = 'ollama_base_url';
  static const _keyThemeMode = 'app_theme_mode';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_keyBaseUrl) ?? 'http://localhost:11434';
    final themeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;
    final themeMode = ThemeMode.values[themeIndex];

    state = SettingsState(baseUrl: baseUrl, themeMode: themeMode);
    ref.read(ollamaBaseUrlProvider.notifier).state = baseUrl;
    ref.read(themeModeProvider.notifier).state = themeMode;
  }

  Future<void> updateBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, trimmed);

    state = state.copyWith(baseUrl: trimmed);
    ref.read(ollamaBaseUrlProvider.notifier).state = trimmed;
    ref.invalidate(ollamaConnectionStatusProvider);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);

    state = state.copyWith(themeMode: mode);
    ref.read(themeModeProvider.notifier).state = mode;
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
