import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'models.dart';

/// Communicates with the Ollama REST API.
class OllamaClient {
  OllamaClient({required this.baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(minutes: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final String baseUrl;
  final Dio _dio;

  /// Cancellation token for the current streaming request.
  CancelToken? _streamCancelToken;

  // ---------------------------------------------------------------------------
  // Connection check
  // ---------------------------------------------------------------------------

  /// Returns true if the Ollama server responds with HTTP 200.
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        '/api/version',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Returns the Ollama server version string, or null on failure.
  Future<String?> getVersion() async {
    try {
      final response = await _dio.get('/api/version');
      return response.data['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Model management
  // ---------------------------------------------------------------------------

  /// Lists all locally installed models.
  Future<List<OllamaModel>> listModels() async {
    final response = await _dio.get('/api/tags');
    final models = response.data['models'] as List<dynamic>? ?? [];
    return models
        .map((m) => OllamaModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Returns detailed information about a specific model.
  Future<ModelInfo> showModel(String name) async {
    final response = await _dio.post(
      '/api/show',
      data: {'name': name},
    );
    return ModelInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletes a model by name.
  Future<void> deleteModel(String name) async {
    await _dio.delete(
      '/api/delete',
      data: {'name': name},
    );
  }

  /// Lists models currently loaded in VRAM.
  Future<List<RunningModel>> listRunning() async {
    try {
      final response = await _dio.get('/api/ps');
      final models = response.data['models'] as List<dynamic>? ?? [];
      return models
          .map((m) => RunningModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Pulls a model from the Ollama registry, streaming progress updates.
  Future<void> pullModel(
    String name, {
    void Function(PullProgress)? onProgress,
  }) async {
    final response = await _dio.post<ResponseBody>(
      '/api/pull',
      data: {'name': name, 'stream': true},
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');

      // Keep the last (potentially incomplete) fragment
      buffer.clear();
      buffer.write(lines.last);

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final progress = PullProgress.fromJson(json);
          onProgress?.call(progress);
        } catch (_) {
          // Skip malformed lines
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Chat streaming
  // ---------------------------------------------------------------------------

  /// Streams chat completion tokens from the Ollama API.
  ///
  /// Yields individual content token strings as they arrive.
  Stream<String> chatStream({
    required String model,
    required List<ChatMessage> messages,
    Map<String, dynamic>? options,
    String? keepAlive,
  }) async* {
    _streamCancelToken = CancelToken();

    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        '/api/chat',
        cancelToken: _streamCancelToken,
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
          if (options != null) 'options': options,
          if (keepAlive != null && keepAlive.isNotEmpty) 'keep_alive': keepAlive,
        },
        options: Options(responseType: ResponseType.stream),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      rethrow;
    }

    final buffer = StringBuffer();

    await for (final chunk in response.data!.stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');

      buffer.clear();
      buffer.write(lines.last);

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final done = json['done'] as bool? ?? false;
          if (done) return;

          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // Skip malformed NDJSON lines
        }
      }
    }
  }

  /// Creates a new model from a Modelfile string, streaming progress status.
  Future<void> createModel({
    required String name,
    required String modelfile,
    void Function(String status)? onProgress,
  }) async {
    final response = await _dio.post<ResponseBody>(
      '/api/create',
      data: {'name': name, 'modelfile': modelfile, 'stream': true},
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream;
    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
      final lines = buffer.toString().split('\n');

      buffer.clear();
      buffer.write(lines.last);

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final status = json['status'] as String? ?? '';
          if (status.isNotEmpty) {
            onProgress?.call(status);
          }
        } catch (_) {
          // Skip malformed lines
        }
      }
    }
  }

  /// Unloads a model from VRAM immediately by setting keep_alive to 0.
  Future<void> unloadModel(String name) async {
    try {
      await _dio.post<dynamic>(
        '/api/generate',
        data: {'model': name, 'keep_alive': 0},
      );
    } catch (_) {}
  }

  /// Cancels the current streaming request.
  void cancelStream() {
    _streamCancelToken?.cancel('User cancelled');
    _streamCancelToken = null;
  }
}
