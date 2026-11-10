import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ollama_client.dart';

/// Controls the app's theme mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// The base URL for the Ollama server.
final ollamaBaseUrlProvider = StateProvider<String>(
  (ref) => 'http://localhost:11434',
);

/// Provides the [OllamaClient] instance, rebuilt when base URL changes.
final ollamaClientProvider = Provider<OllamaClient>((ref) {
  final baseUrl = ref.watch(ollamaBaseUrlProvider);
  return OllamaClient(baseUrl: baseUrl);
});

/// Checks whether the Ollama server is reachable.
final ollamaConnectionStatusProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(ollamaClientProvider);
  return client.checkConnection();
});
