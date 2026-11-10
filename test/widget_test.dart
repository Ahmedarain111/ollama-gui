import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/app.dart';
import 'package:ollama_gui/core/providers.dart';
import 'package:ollama_gui/core/system_usage.dart';
import 'package:ollama_gui/features/chat/chat_providers.dart';

void main() {
  testWidgets('OllamaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override async connection check and model list to return immediately without pending network timers
          ollamaConnectionStatusProvider.overrideWith((ref) async => false),
          installedModelsProvider.overrideWith((ref) async => []),
          conversationsStreamProvider.overrideWith((ref) => Stream.value([])),
          systemUsageStreamProvider.overrideWith((ref) => Stream.value(const SystemUsage.initial())),
        ],
        child: const OllamaApp(),
      ),
    );

    // Pump and settle frames
    await tester.pump();

    // Verify app mounts successfully
    expect(find.byType(OllamaApp), findsOneWidget);
  });
}
