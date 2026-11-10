import 'package:flutter_test/flutter_test.dart';
import 'package:ollama_gui/features/chat/chat_media_helper.dart';
import 'package:ollama_gui/features/models/models_library.dart';

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
}
