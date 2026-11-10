import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/core/system_usage.dart';
import 'package:ollama_gui/shared/widgets/system_usage_bar.dart';

void main() {
  group('SystemUsage Model', () {
    test('initializes with default zeroed values', () {
      const usage = SystemUsage.initial();
      expect(usage.cpuPercent, 0.0);
      expect(usage.ramUsedGb, 0.0);
      expect(usage.ramTotalGb, 0.0);
      expect(usage.ramPercent, 0.0);
      expect(usage.gpuPercent, isNull);
      expect(usage.vramUsedGb, 0.0);
      expect(usage.loadedModels, isEmpty);
    });

    test('retains populated hardware metrics', () {
      const usage = SystemUsage(
        cpuPercent: 24.5,
        ramUsedGb: 8.2,
        ramTotalGb: 16.0,
        ramPercent: 51.25,
        gpuPercent: 18.0,
        vramUsedGb: 3.4,
        vramTotalGb: 8.0,
        vramPercent: 42.5,
        gpuName: 'NVIDIA RTX 4070',
        loadedModels: ['llama3.2:3b'],
      );

      expect(usage.cpuPercent, 24.5);
      expect(usage.ramUsedGb, 8.2);
      expect(usage.gpuPercent, 18.0);
      expect(usage.vramUsedGb, 3.4);
      expect(usage.loadedModels, contains('llama3.2:3b'));
    });
  });

  group('SystemUsageBar Widget', () {
    testWidgets('renders CPU, GPU, RAM, VRAM badges with stream data', (tester) async {
      const testUsage = SystemUsage(
        cpuPercent: 32.0,
        ramUsedGb: 6.4,
        ramTotalGb: 16.0,
        ramPercent: 40.0,
        gpuPercent: 15.0,
        vramUsedGb: 2.1,
        vramTotalGb: 8.0,
        loadedModels: ['llama3.2:3b'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            systemUsageStreamProvider.overrideWith(
              (ref) => Stream.value(testUsage),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SystemUsageBar(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('32%'), findsOneWidget);
      expect(find.text('GPU'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('RAM'), findsOneWidget);
      expect(find.text('6.4G'), findsOneWidget);
      expect(find.text('VRAM'), findsOneWidget);
      expect(find.text('2.1G'), findsOneWidget);
      expect(find.byIcon(Icons.eject_rounded), findsOneWidget);
    });
  });
}
