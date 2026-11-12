import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ollama_client.dart';
import 'ollama_process_manager.dart';

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

/// Checks whether the Ollama server is reachable, with auto-retry when offline.
final ollamaConnectionStatusProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(ollamaClientProvider);
  ref.watch(ollamaServiceStatusProvider);
  final isConnected = await client.checkConnection();

  if (!isConnected) {
    // Retry every 2.5 seconds while disconnected or while Ollama is starting up
    final timer = Timer(const Duration(milliseconds: 2500), () {
      ref.invalidateSelf();
    });
    ref.onDispose(timer.cancel);
  }

  return isConnected;
});
