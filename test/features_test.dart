import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/features/chat/chat_media_helper.dart';
import 'package:ollama_gui/features/models/models_library.dart';
import 'package:ollama_gui/features/settings/settings_providers.dart';

void main() {
  group('ChatMediaHelper', () {
    test('handles plain text without images', () {
      const raw = 'Hello Ollama!';
      final parsed = parseMessageContent(raw);
      expect(parsed.text, 'Hello Ollama!');
      expect(parsed.images, isNull);
    });

    test('serializes and deserializes multimodal images', () {
      final base64Images = ['dGVzdDE=', 'dGVzdDI='];
      final formatted = formatMessageWithImages('Describe these images', base64Images);

      expect(formatted.startsWith(imageMarkerPrefix), isTrue);

      final parsed = parseMessageContent(formatted);
      expect(parsed.text, 'Describe these images');
      expect(parsed.images, isNotNull);
      expect(parsed.images!.length, 2);
      expect(parsed.images![0], 'dGVzdDE=');
      expect(parsed.images![1], 'dGVzdDI=');
    });

    test('gracefully falls back if image marker is corrupt', () {
      const corrupt = '<!--ollama_images:NOT_JSON-->\nHello';
      final parsed = parseMessageContent(corrupt);
      expect(parsed.text, corrupt);
    });
  });

  group('OllamaModelCatalog', () {
    test('contains comprehensive catalog of 30+ models', () {
      expect(ollamaModelCatalog.length, greaterThanOrEqualTo(30));
    });

    test('has models across all primary categories', () {
      final categories = ollamaModelCatalog.map((m) => m.category).toSet();
      expect(categories, containsAll(['Reasoning', 'Coding', 'Vision', 'General', 'Embedding']));
    });

    test('deepseek-r1 exists and is in Reasoning category', () {
      final r1 = ollamaModelCatalog.firstWhere((m) => m.name == 'deepseek-r1');
      expect(r1.category, 'Reasoning');
      expect(r1.publisher, 'DeepSeek');
      expect(r1.sizes, contains('7b'));
    });

    test('qwen2.5-coder exists and is in Coding category', () {
      final coder = ollamaModelCatalog.firstWhere((m) => m.name == 'qwen2.5-coder');
      expect(coder.category, 'Coding');
      expect(coder.sizes, contains('7b'));
    });

    test('llama3.2-vision exists and is in Vision category', () {
      final vision = ollamaModelCatalog.firstWhere((m) => m.name == 'llama3.2-vision');
      expect(vision.category, 'Vision');
      expect(vision.isVision, isTrue);
    });
  });

  group('SettingsState', () {
    test('initializes with expected default values', () {
      const state = SettingsState(
        baseUrl: 'http://localhost:11434',
        themeMode: ThemeMode.dark,
      );

      expect(state.baseUrl, 'http://localhost:11434');
      expect(state.themeMode, ThemeMode.dark);
      expect(state.accentColorKey, 'iris');
      expect(state.chatFontSize, 15.0);
      expect(state.showSystemUsageBar, isTrue);
      expect(state.defaultModel, isNull);
      expect(state.defaultSystemPrompt, '');
      expect(state.defaultTemperature, 0.7);
      expect(state.defaultTopP, 0.9);
      expect(state.defaultRepeatPenalty, 1.1);
      expect(state.defaultNumCtx, 4096);
      expect(state.keepAlive, '5m');
      expect(state.sendOnEnter, isTrue);
      expect(state.streamResponse, isTrue);
      expect(state.showGenerationStats, isTrue);
      expect(state.autoScroll, isTrue);
      expect(state.accentColor.label, 'Iris Violet');
    });

    test('supports comprehensive accent color palettes', () {
      expect(kAccentColors.length, greaterThanOrEqualTo(6));
      final keys = kAccentColors.map((c) => c.key).toList();
      expect(keys, containsAll(['iris', 'emerald', 'cyan', 'amber', 'rose', 'blue']));
    });

    test('copyWith updates fields and clears nullable values properly', () {
      const state = SettingsState(
        baseUrl: 'http://localhost:11434',
        themeMode: ThemeMode.dark,
      );

      final updated = state.copyWith(
        accentColorKey: 'emerald',
        chatFontSize: 17.0,
        sendOnEnter: false,
        defaultModel: () => 'deepseek-r1:7b',
        keepAlive: '1h',
      );

      expect(updated.accentColorKey, 'emerald');
      expect(updated.accentColor.label, 'Emerald Green');
      expect(updated.chatFontSize, 17.0);
      expect(updated.sendOnEnter, isFalse);
      expect(updated.defaultModel, 'deepseek-r1:7b');
      expect(updated.keepAlive, '1h');

      final cleared = updated.copyWith(defaultModel: () => null);
      expect(cleared.defaultModel, isNull);
    });
  });
}
