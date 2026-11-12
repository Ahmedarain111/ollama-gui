import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Current lifecycle status of the local Ollama background daemon.
enum OllamaServiceStatus {
  stopped,
  starting,
  running,
  failed,
}

/// Provider exposing the local Ollama service manager state.
final ollamaServiceStatusProvider =
    StateProvider<OllamaServiceStatus>((ref) => OllamaServiceStatus.stopped);

/// Manages automatically locating, launching, and supervising the `ollama serve`
/// background process when the application starts.
class OllamaProcessManager {
  static final OllamaProcessManager _instance =
      OllamaProcessManager._internal();
  factory OllamaProcessManager() => _instance;
  OllamaProcessManager._internal();

  Process? _process;
  OllamaServiceStatus _status = OllamaServiceStatus.stopped;
  String? _lastError;
  bool _spawnedByUs = false;

  OllamaServiceStatus get status => _status;
  String? get lastError => _lastError;
  bool get wasSpawnedByUs => _spawnedByUs;

  /// Locates the `ollama` executable on the host system.
  Future<String?> findOllamaBinary() async {
    // 1. Try finding in standard PATH via 'which' / 'where'
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final res = await Process.run(cmd, ['ollama']);
      if (res.exitCode == 0) {
        final path = (res.stdout as String).split('\n').first.trim();
        if (path.isNotEmpty && await File(path).exists()) {
          return path;
        }
      }
    } catch (_) {}

    // 2. Common fallback paths on Unix / macOS / Windows
    final home = Platform.environment['HOME'] ?? '';
    final commonPaths = [
      '/usr/local/bin/ollama',
      '/usr/bin/ollama',
      '/bin/ollama',
      if (home.isNotEmpty) '$home/.local/bin/ollama',
      if (Platform.isMacOS)
        '/Applications/Ollama.app/Contents/Resources/ollama',
      if (Platform.isWindows) ...[
        r'C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe',
        r'C:\Program Files\Ollama\ollama.exe',
      ],
    ];

    for (final p in commonPaths) {
      if (await File(p).exists()) {
        return p;
      }
    }

    return null;
  }

  /// Pings the Ollama server with a fast timeout to check if it's already responsive.
  Future<bool> isOllamaResponding({
    String baseUrl = 'http://localhost:11434',
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 700);
      final uri = Uri.parse('$baseUrl/api/version');
      final request = await client.getUrl(uri);
      final response =
          await request.close().timeout(const Duration(milliseconds: 700));
      final ok = response.statusCode == 200;
      client.close(force: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Automatically launches `ollama serve` in the background if it is not already running.
  Future<bool> startIfNeeded({
    String baseUrl = 'http://localhost:11434',
    WidgetRef? ref,
  }) async {
    // In automated test environments, bypass launching external processes
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }

    // Check if already running and responsive
    if (await isOllamaResponding(baseUrl: baseUrl)) {
      _status = OllamaServiceStatus.running;
      _spawnedByUs = false;
      if (ref != null) {
        ref.read(ollamaServiceStatusProvider.notifier).state =
            OllamaServiceStatus.running;
        ref.invalidate(ollamaConnectionStatusProvider);
      }
      return true;
    }

    _status = OllamaServiceStatus.starting;
    if (ref != null) {
      ref.read(ollamaServiceStatusProvider.notifier).state =
          OllamaServiceStatus.starting;
    }
    _lastError = null;

    final binary = await findOllamaBinary();
    if (binary == null) {
      _status = OllamaServiceStatus.failed;
      _lastError = 'Ollama executable not found on host system';
      if (ref != null) {
        ref.read(ollamaServiceStatusProvider.notifier).state =
            OllamaServiceStatus.failed;
      }
      debugPrint('[OllamaProcessManager] $_lastError');
      return false;
    }

    try {
      debugPrint('[OllamaProcessManager] Launching "$binary serve"...');
      _process = await Process.start(
        binary,
        ['serve'],
        mode: ProcessStartMode.normal,
      );
      _spawnedByUs = true;

      // Drain stdout and stderr to prevent OS pipe buffers from filling and freezing
      _process!.stdout.transform(utf8.decoder).listen((data) {
        // Suppress or debug-log if needed
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        // Suppress or debug-log if needed
      });

      _process!.exitCode.then((code) {
        debugPrint('[OllamaProcessManager] Process exited with code $code');
        if (_status == OllamaServiceStatus.starting ||
            _status == OllamaServiceStatus.running) {
          _status = OllamaServiceStatus.stopped;
          if (ref != null) {
            ref.read(ollamaServiceStatusProvider.notifier).state =
                OllamaServiceStatus.stopped;
            ref.invalidate(ollamaConnectionStatusProvider);
          }
        }
      });

      // Poll until Ollama is responsive (up to 12 seconds)
      final deadline = DateTime.now().add(const Duration(seconds: 12));
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (await isOllamaResponding(baseUrl: baseUrl)) {
          _status = OllamaServiceStatus.running;
          debugPrint(
              '[OllamaProcessManager] Ollama service connected successfully.');
          if (ref != null) {
            ref.read(ollamaServiceStatusProvider.notifier).state =
                OllamaServiceStatus.running;
            ref.invalidate(ollamaConnectionStatusProvider);
          }
          return true;
        }
      }

      _status = OllamaServiceStatus.failed;
      _lastError = 'Ollama service started but failed to bind in time';
      if (ref != null) {
        ref.read(ollamaServiceStatusProvider.notifier).state =
            OllamaServiceStatus.failed;
      }
      return false;
    } catch (e) {
      _status = OllamaServiceStatus.failed;
      _lastError = e.toString();
      if (ref != null) {
        ref.read(ollamaServiceStatusProvider.notifier).state =
            OllamaServiceStatus.failed;
      }
      debugPrint('[OllamaProcessManager] Failed to start Ollama: $e');
      return false;
    }
  }

  /// Stops the background process if it was started by the application.
  void stopIfSpawned() {
    if (_spawnedByUs && _process != null) {
      try {
        _process!.kill(ProcessSignal.sigterm);
      } catch (_) {
        _process!.kill();
      }
      _process = null;
      _status = OllamaServiceStatus.stopped;
    }
  }
}
