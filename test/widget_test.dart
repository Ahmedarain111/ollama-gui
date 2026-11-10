import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/app.dart';
import 'package:ollama_gui/core/providers.dart';

void main() {
  testWidgets('OllamaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override async connection check to return immediately without pending network timers
          ollamaConnectionStatusProvider.overrideWith((ref) async => false),
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
