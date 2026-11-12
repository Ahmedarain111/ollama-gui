import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/app.dart';
import 'package:ollama_gui/core/providers.dart';
import 'package:ollama_gui/core/system_usage.dart';
import 'package:ollama_gui/core/theme.dart';
import 'package:ollama_gui/features/chat/chat_providers.dart';
import 'package:ollama_gui/features/models/models_library.dart';

void main() {
  test('Catalog contains qwen3 and weight variants can be resolved', () {
    final qwen3 = ollamaModelCatalog.firstWhere((m) => m.name == 'qwen3');
    expect(qwen3.sizes, contains('8b'));
    expect(qwen3.sizes, contains('4b'));

    final qwen25 = ollamaModelCatalog.firstWhere((m) => m.name == 'qwen2.5');
    expect(qwen25.sizes, contains('3b'));
    expect(qwen25.sizes, contains('7b'));

    final matched = findLibraryModel('qwen2.5:3b');
    expect(matched, isNotNull);
    expect(matched!.name, 'qwen2.5');

    final matchedQwen3 = findLibraryModel('qwen3');
    expect(matchedQwen3, isNotNull);
    expect(matchedQwen3!.name, 'qwen3');
  });
  test('Token specifications verify correctly', () {
    const dark = AppColors.dark;
    expect(dark.bg, const Color(0xFF0F1115));
    expect(dark.bgSidebar, const Color(0xFF14171C));
    expect(dark.surface, const Color(0xFF1A1E25));
    expect(dark.surfaceHover, const Color(0xFF212630));
    expect(dark.border, const Color(0xFF2A2F38));
    expect(dark.text, const Color(0xFFE6E8EB));
    expect(dark.textMuted, const Color(0xFF8B93A1));
    expect(dark.accent, const Color(0xFF7C83FF));
    expect(dark.accentHover, const Color(0xFF9197FF));
    expect(dark.accentTextOn, const Color(0xFF0F1115));
    expect(dark.codeBg, const Color(0xFF0B0D10));
    expect(dark.success, const Color(0xFF3DDC97));
    expect(dark.warning, const Color(0xFFF5B84B));
    expect(dark.error, const Color(0xFFF0616D));

    const light = AppColors.light;
    expect(light.bg, const Color(0xFFFAFAFB));
    expect(light.bgSidebar, const Color(0xFFF2F3F6));
    expect(light.surface, const Color(0xFFFFFFFF));
    expect(light.surfaceHover, const Color(0xFFF0F2F5));
    expect(light.border, const Color(0xFFE3E6EB));
    expect(light.text, const Color(0xFF16181D));
    expect(light.textMuted, const Color(0xFF5F6877));
    expect(light.accent, const Color(0xFF5B63F0));
    expect(light.accentHover, const Color(0xFF4A52E0));
    expect(light.accentTextOn, const Color(0xFFFFFFFF));
    expect(light.codeBg, const Color(0xFFF3F4F7));
    expect(light.success, const Color(0xFF14A06A));
    expect(light.warning, const Color(0xFFC98A12));
    expect(light.error, const Color(0xFFD63F4C));

    expect(AppRadius.chip, 6.0);
    expect(AppRadius.button, 8.0);
    expect(AppRadius.input, 8.0);
    expect(AppRadius.card, 12.0);
    expect(AppRadius.dialog, 12.0);
  });

  testWidgets('OllamaApp smoke test in Dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.dark),
          ollamaConnectionStatusProvider.overrideWith((ref) async => false),
          installedModelsProvider.overrideWith((ref) async => []),
          conversationsStreamProvider.overrideWith((ref) => Stream.value([])),
          systemUsageStreamProvider.overrideWith((ref) => Stream.value(const SystemUsage.initial())),
        ],
        child: const OllamaApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(OllamaApp), findsOneWidget);
  });

  testWidgets('OllamaApp smoke test in Light mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeMode.light),
          ollamaConnectionStatusProvider.overrideWith((ref) async => false),
          installedModelsProvider.overrideWith((ref) async => []),
          conversationsStreamProvider.overrideWith((ref) => Stream.value([])),
          systemUsageStreamProvider.overrideWith((ref) => Stream.value(const SystemUsage.initial())),
        ],
        child: const OllamaApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(OllamaApp), findsOneWidget);
  });
}
