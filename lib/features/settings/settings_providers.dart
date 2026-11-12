import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

/// Predefined accent color options for the user interface.
class AccentColorOption {
  final String key;
  final String label;
  final Color darkColor;
  final Color lightColor;
  final Color darkHover;
  final Color lightHover;

  const AccentColorOption({
    required this.key,
    required this.label,
    required this.darkColor,
    required this.lightColor,
    required this.darkHover,
    required this.lightHover,
  });
}

const List<AccentColorOption> kAccentColors = [
  AccentColorOption(
    key: 'iris',
    label: 'Iris Violet',
    darkColor: Color(0xFF7C83FF),
    lightColor: Color(0xFF5B63F0),
    darkHover: Color(0xFF9197FF),
    lightHover: Color(0xFF4A52E0),
  ),
  AccentColorOption(
    key: 'emerald',
    label: 'Emerald Green',
    darkColor: Color(0xFF10B981),
    lightColor: Color(0xFF059669),
    darkHover: Color(0xFF34D399),
    lightHover: Color(0xFF047857),
  ),
  AccentColorOption(
    key: 'cyan',
    label: 'Ocean Cyan',
    darkColor: Color(0xFF06B6D4),
    lightColor: Color(0xFF0891B2),
    darkHover: Color(0xFF22D3EE),
    lightHover: Color(0xFF0E7490),
  ),
  AccentColorOption(
    key: 'amber',
    label: 'Amber Gold',
    darkColor: Color(0xFFF59E0B),
    lightColor: Color(0xFFD97706),
    darkHover: Color(0xFFFBBF24),
    lightHover: Color(0xFFB45309),
  ),
  AccentColorOption(
    key: 'rose',
    label: 'Coral Rose',
    darkColor: Color(0xFFF43F5E),
    lightColor: Color(0xFFE11D48),
    darkHover: Color(0xFFFB7185),
    lightHover: Color(0xFFBE123C),
  ),
  AccentColorOption(
    key: 'blue',
    label: 'Royal Blue',
    darkColor: Color(0xFF3B82F6),
    lightColor: Color(0xFF2563EB),
    darkHover: Color(0xFF60A5FA),
    lightHover: Color(0xFF1D4ED8),
  ),
];

class SettingsState {
  const SettingsState({
    required this.baseUrl,
    required this.themeMode,
    this.accentColorKey = 'iris',
    this.chatFontSize = 15.0,
    this.showSystemUsageBar = true,
    this.defaultModel,
    this.defaultSystemPrompt = '',
    this.defaultTemperature = 0.7,
    this.defaultTopP = 0.9,
    this.defaultRepeatPenalty = 1.1,
    this.defaultNumCtx = 4096,
    this.keepAlive = '5m',
    this.sendOnEnter = true,
    this.streamResponse = true,
    this.showGenerationStats = true,
    this.autoScroll = true,
  });

  final String baseUrl;
  final ThemeMode themeMode;
  final String accentColorKey;
  final double chatFontSize;
  final bool showSystemUsageBar;
  final String? defaultModel;
  final String defaultSystemPrompt;
  final double defaultTemperature;
  final double defaultTopP;
  final double defaultRepeatPenalty;
  final int defaultNumCtx;
  final String keepAlive;
  final bool sendOnEnter;
  final bool streamResponse;
  final bool showGenerationStats;
  final bool autoScroll;

  AccentColorOption get accentColor => kAccentColors.firstWhere(
        (c) => c.key == accentColorKey,
        orElse: () => kAccentColors.first,
      );

  SettingsState copyWith({
    String? baseUrl,
    ThemeMode? themeMode,
    String? accentColorKey,
    double? chatFontSize,
    bool? showSystemUsageBar,
    ValueGetter<String?>? defaultModel,
    String? defaultSystemPrompt,
    double? defaultTemperature,
    double? defaultTopP,
    double? defaultRepeatPenalty,
    int? defaultNumCtx,
    String? keepAlive,
    bool? sendOnEnter,
    bool? streamResponse,
    bool? showGenerationStats,
    bool? autoScroll,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      themeMode: themeMode ?? this.themeMode,
      accentColorKey: accentColorKey ?? this.accentColorKey,
      chatFontSize: chatFontSize ?? this.chatFontSize,
      showSystemUsageBar: showSystemUsageBar ?? this.showSystemUsageBar,
      defaultModel: defaultModel != null ? defaultModel() : this.defaultModel,
      defaultSystemPrompt: defaultSystemPrompt ?? this.defaultSystemPrompt,
      defaultTemperature: defaultTemperature ?? this.defaultTemperature,
      defaultTopP: defaultTopP ?? this.defaultTopP,
      defaultRepeatPenalty: defaultRepeatPenalty ?? this.defaultRepeatPenalty,
      defaultNumCtx: defaultNumCtx ?? this.defaultNumCtx,
      keepAlive: keepAlive ?? this.keepAlive,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
      streamResponse: streamResponse ?? this.streamResponse,
      showGenerationStats: showGenerationStats ?? this.showGenerationStats,
      autoScroll: autoScroll ?? this.autoScroll,
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
  static const _keyAccentColor = 'app_accent_color';
  static const _keyChatFontSize = 'app_chat_font_size';
  static const _keyShowSystemUsage = 'app_show_system_usage';
  static const _keyDefaultModel = 'ollama_default_model';
  static const _keyDefaultSystemPrompt = 'ollama_default_system_prompt';
  static const _keyDefaultTemperature = 'ollama_default_temperature';
  static const _keyDefaultTopP = 'ollama_default_top_p';
  static const _keyDefaultRepeatPenalty = 'ollama_default_repeat_penalty';
  static const _keyDefaultNumCtx = 'ollama_default_num_ctx';
  static const _keyKeepAlive = 'ollama_keep_alive';
  static const _keySendOnEnter = 'app_send_on_enter';
  static const _keyStreamResponse = 'app_stream_response';
  static const _keyShowGenerationStats = 'app_show_generation_stats';
  static const _keyAutoScroll = 'app_auto_scroll';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_keyBaseUrl) ?? 'http://localhost:11434';
    final themeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.dark.index;
    final themeMode = ThemeMode.values[themeIndex];
    final accentKey = prefs.getString(_keyAccentColor) ?? 'iris';
    final chatFontSize = prefs.getDouble(_keyChatFontSize) ?? 15.0;
    final showSystemUsage = prefs.getBool(_keyShowSystemUsage) ?? true;
    final defaultModel = prefs.getString(_keyDefaultModel);
    final defaultSystemPrompt = prefs.getString(_keyDefaultSystemPrompt) ?? '';
    final defaultTemp = prefs.getDouble(_keyDefaultTemperature) ?? 0.7;
    final defaultTopP = prefs.getDouble(_keyDefaultTopP) ?? 0.9;
    final defaultRepeat = prefs.getDouble(_keyDefaultRepeatPenalty) ?? 1.1;
    final defaultNumCtx = prefs.getInt(_keyDefaultNumCtx) ?? 4096;
    final keepAlive = prefs.getString(_keyKeepAlive) ?? '5m';
    final sendOnEnter = prefs.getBool(_keySendOnEnter) ?? true;
    final streamResponse = prefs.getBool(_keyStreamResponse) ?? true;
    final showGenStats = prefs.getBool(_keyShowGenerationStats) ?? true;
    final autoScroll = prefs.getBool(_keyAutoScroll) ?? true;

    state = SettingsState(
      baseUrl: baseUrl,
      themeMode: themeMode,
      accentColorKey: accentKey,
      chatFontSize: chatFontSize,
      showSystemUsageBar: showSystemUsage,
      defaultModel: defaultModel,
      defaultSystemPrompt: defaultSystemPrompt,
      defaultTemperature: defaultTemp,
      defaultTopP: defaultTopP,
      defaultRepeatPenalty: defaultRepeat,
      defaultNumCtx: defaultNumCtx,
      keepAlive: keepAlive,
      sendOnEnter: sendOnEnter,
      streamResponse: streamResponse,
      showGenerationStats: showGenStats,
      autoScroll: autoScroll,
    );

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

  Future<void> updateAccentColor(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccentColor, key);
    state = state.copyWith(accentColorKey: key);
  }

  Future<void> updateChatFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyChatFontSize, size);
    state = state.copyWith(chatFontSize: size);
  }

  Future<void> updateShowSystemUsage(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSystemUsage, show);
    state = state.copyWith(showSystemUsageBar: show);
  }

  Future<void> updateDefaultModel(String? model) async {
    final prefs = await SharedPreferences.getInstance();
    if (model == null || model.isEmpty) {
      await prefs.remove(_keyDefaultModel);
      state = state.copyWith(defaultModel: () => null);
    } else {
      await prefs.setString(_keyDefaultModel, model);
      state = state.copyWith(defaultModel: () => model);
    }
  }

  Future<void> updateDefaultSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultSystemPrompt, prompt);
    state = state.copyWith(defaultSystemPrompt: prompt);
  }

  Future<void> updateDefaultTemperature(double temp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultTemperature, temp);
    state = state.copyWith(defaultTemperature: temp);
  }

  Future<void> updateDefaultTopP(double topP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultTopP, topP);
    state = state.copyWith(defaultTopP: topP);
  }

  Future<void> updateDefaultRepeatPenalty(double penalty) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultRepeatPenalty, penalty);
    state = state.copyWith(defaultRepeatPenalty: penalty);
  }

  Future<void> updateDefaultNumCtx(int numCtx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultNumCtx, numCtx);
    state = state.copyWith(defaultNumCtx: numCtx);
  }

  Future<void> updateKeepAlive(String keepAlive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyKeepAlive, keepAlive);
    state = state.copyWith(keepAlive: keepAlive);
  }

  Future<void> updateSendOnEnter(bool sendOnEnter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySendOnEnter, sendOnEnter);
    state = state.copyWith(sendOnEnter: sendOnEnter);
  }

  Future<void> updateStreamResponse(bool stream) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreamResponse, stream);
    state = state.copyWith(streamResponse: stream);
  }

  Future<void> updateShowGenerationStats(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowGenerationStats, show);
    state = state.copyWith(showGenerationStats: show);
  }

  Future<void> updateAutoScroll(bool autoScroll) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoScroll, autoScroll);
    state = state.copyWith(autoScroll: autoScroll);
  }

  Future<void> resetInferenceDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDefaultSystemPrompt);
    await prefs.remove(_keyDefaultTemperature);
    await prefs.remove(_keyDefaultTopP);
    await prefs.remove(_keyDefaultRepeatPenalty);
    await prefs.remove(_keyDefaultNumCtx);
    await prefs.remove(_keyKeepAlive);

    state = state.copyWith(
      defaultSystemPrompt: '',
      defaultTemperature: 0.7,
      defaultTopP: 0.9,
      defaultRepeatPenalty: 1.1,
      defaultNumCtx: 4096,
      keepAlive: '5m',
    );
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
