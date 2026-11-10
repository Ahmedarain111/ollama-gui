import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../database/database.dart';
import '../../database/database_provider.dart';

/// Riverpod providers specific to the chat feature.

// ---------------------------------------------------------------------------
// Active conversation
// ---------------------------------------------------------------------------

/// The currently selected conversation ID. Null = no conversation selected.
final activeConversationProvider = StateProvider<int?>((ref) => null);

/// A trigger counter to open the new chat dialog from anywhere.
final newChatTriggerProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Installed models
// ---------------------------------------------------------------------------

/// Lists all models installed on the Ollama server.
final installedModelsProvider = FutureProvider<List<OllamaModel>>((ref) async {
  final client = ref.watch(ollamaClientProvider);
  return client.listModels();
});

// ---------------------------------------------------------------------------
// Selected model
// ---------------------------------------------------------------------------

/// The model currently chosen for new messages. Defaults to first available.
final selectedModelProvider = StateProvider<String>((ref) {
  final modelsAsync = ref.watch(installedModelsProvider);
  return modelsAsync.when(
    data: (models) =>
        models.isNotEmpty ? models.first.name : 'llama3.2',
    loading: () => 'llama3.2',
    error: (_, __) => 'llama3.2',
  );
});

// ---------------------------------------------------------------------------
// Streaming state
// ---------------------------------------------------------------------------

/// True while an assistant response is being streamed.
final isStreamingProvider = StateProvider<bool>((ref) => false);

/// Live streaming statistics: tokens per second and total token count.
final streamingStatsProvider =
    StateProvider<({double tokensPerSec, int totalTokens})?>(
  (ref) => null,
);

// ---------------------------------------------------------------------------
// Messages stream
// ---------------------------------------------------------------------------

/// Watches messages for a specific conversation from the drift database.
final messagesStreamProvider =
    StreamProvider.family<List<Message>, int>((ref, convId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchMessages(convId);
});

// ---------------------------------------------------------------------------
// Conversations stream
// ---------------------------------------------------------------------------

/// Watches all conversations from the drift database.
final conversationsStreamProvider =
    StreamProvider<List<Conversation>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchConversations();
});

/// Watches a single conversation from the drift database.
final conversationDetailProvider =
    StreamProvider.family<Conversation?, int>((ref, convId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchConversation(convId);
});

/// Controls whether the inference parameters and system prompt side panel is open.
final showParamsPanelProvider = StateProvider<bool>((ref) => false);
