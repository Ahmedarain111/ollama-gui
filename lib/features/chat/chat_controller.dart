import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart' as api;
import '../../core/providers.dart';
import '../../database/database.dart';
import '../../database/database_provider.dart';
import 'chat_providers.dart';

/// Provides the [ChatController] scoped to a conversation.
final chatControllerProvider =
    Provider.family<ChatController, int>((ref, convId) {
  return ChatController(ref: ref, conversationId: convId);
});

/// Handles chat business logic: send messages, stream responses, cancel.
class ChatController {
  ChatController({required this.ref, required this.conversationId});

  final Ref ref;
  final int conversationId;

  StreamSubscription<String>? _streamSub;
  int? _assistantMessageId;
  final StringBuffer _contentBuffer = StringBuffer();
  int _tokenCount = 0;
  DateTime? _streamStart;

  AppDatabase get _db => ref.read(appDatabaseProvider);

  /// Sends a user message and starts streaming the assistant reply.
  Future<void> sendMessage(String content, String model) async {
    if (content.trim().isEmpty) return;

    final now = DateTime.now();

    // 1. Insert user message
    await _db.insertMessage(
      MessagesCompanion(
        conversationId: Value(conversationId),
        role: const Value('user'),
        content: Value(content.trim()),
        createdAt: Value(now),
      ),
    );

    // Update conversation timestamp
    await _db.updateConversationUpdatedAt(conversationId);

    // 2. Set streaming state
    ref.read(isStreamingProvider.notifier).state = true;
    ref.read(streamingStatsProvider.notifier).state = null;
    _contentBuffer.clear();
    _tokenCount = 0;
    _streamStart = DateTime.now();

    // 3. Create placeholder assistant message
    _assistantMessageId = await _db.insertMessage(
      MessagesCompanion(
        conversationId: Value(conversationId),
        role: const Value('assistant'),
        content: const Value(''),
        createdAt: Value(DateTime.now()),
      ),
    );

    // 4. Fetch conversation history for context
    final dbMessages = await _db.getMessages(conversationId);
    // Remove the empty placeholder we just inserted from history
    final historyMessages = dbMessages
        .where((m) => m.id != _assistantMessageId)
        .map(
          (m) => api.ChatMessage(
            role: m.role,
            content: m.content,
            createdAt: m.createdAt,
          ),
        )
        .toList();

    // 5. Start streaming
    final client = ref.read(ollamaClientProvider);
    final stream = client.chatStream(
      model: model,
      messages: historyMessages,
    );

    _streamSub = stream.listen(
      _onToken,
      onDone: _onDone,
      onError: _onError,
      cancelOnError: true,
    );
  }

  void _onToken(String token) {
    _contentBuffer.write(token);
    _tokenCount++;

    // Update stats
    if (_streamStart != null) {
      final elapsed =
          DateTime.now().difference(_streamStart!).inMilliseconds / 1000.0;
      final tps = elapsed > 0 ? _tokenCount / elapsed : 0.0;
      ref.read(streamingStatsProvider.notifier).state = (
        tokensPerSec: tps,
        totalTokens: _tokenCount,
      );
    }

    // Live-update the assistant message in DB
    if (_assistantMessageId != null) {
      _db.updateMessage(_assistantMessageId!, content: _contentBuffer.toString());
    }
  }

  Future<void> _onDone() async {
    if (_assistantMessageId != null && _streamStart != null) {
      final durationMs =
          DateTime.now().difference(_streamStart!).inMilliseconds;
      final tps =
          durationMs > 0 ? _tokenCount / (durationMs / 1000.0) : 0.0;

      await _db.updateMessage(
        _assistantMessageId!,
        content: _contentBuffer.toString(),
        tokensPerSec: tps,
        totalTokens: _tokenCount,
        durationMs: durationMs,
      );
    }

    _cleanup();
  }

  void _onError(Object error) {
    // Insert error notice into message
    if (_assistantMessageId != null) {
      final errMsg = _contentBuffer.isEmpty
          ? '⚠️ Error: $error'
          : '${_contentBuffer.toString()}\n\n⚠️ Stream interrupted: $error';
      _db.updateMessage(_assistantMessageId!, content: errMsg);
    }
    _cleanup();
  }

  /// Cancels the current streaming request.
  void cancelStream() {
    _streamSub?.cancel();
    ref.read(ollamaClientProvider).cancelStream();
    if (_assistantMessageId != null && _contentBuffer.isNotEmpty) {
      _db.updateMessage(
        _assistantMessageId!,
        content: '${_contentBuffer.toString()}\n\n*(Generation stopped)*',
      );
    }
    _cleanup();
  }

  void _cleanup() {
    _streamSub = null;
    _assistantMessageId = null;
    _streamStart = null;
    ref.read(isStreamingProvider.notifier).state = false;
  }
}
