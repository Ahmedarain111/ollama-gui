// GENERATED CODE — DO NOT EDIT BY HAND
//
// Run the following command to regenerate:
//   dart run build_runner build --delete-conflicting-outputs
//
// ignore_for_file: type=lint

import 'package:drift/drift.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Table of chat conversations.
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 256)();
  TextColumn get model => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get systemPrompt => text().nullable()();

  /// JSON blob for parameter presets (temperature, top_p, etc.)
  TextColumn get paramPreset => text().nullable()();
}

/// Table of individual chat messages.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get tokensPerSec => real().nullable()();
  IntColumn get totalTokens => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Conversations, Messages])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          // Enable foreign key constraints
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // -------------------------------------------------------------------------
  // Conversations
  // -------------------------------------------------------------------------

  /// Watches all conversations ordered by most recently updated.
  Stream<List<Conversation>> watchConversations() {
    return (select(conversations)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Inserts a new conversation and returns its generated id.
  Future<int> insertConversation(ConversationsCompanion data) {
    return into(conversations).insert(data);
  }

  /// Updates the title of a conversation.
  Future<void> updateConversationTitle(int id, String title) {
    return (update(conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(title: Value(title)),
    );
  }

  /// Bumps the updatedAt timestamp for a conversation.
  Future<void> updateConversationUpdatedAt(int id) {
    return (update(conversations)..where((t) => t.id.equals(id))).write(
      ConversationsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  /// Deletes a conversation and cascades to its messages.
  Future<void> deleteConversation(int id) {
    return (delete(conversations)..where((t) => t.id.equals(id))).go();
  }

  // -------------------------------------------------------------------------
  // Messages
  // -------------------------------------------------------------------------

  /// Watches all messages for a given conversation ordered by creation time.
  Stream<List<Message>> watchMessages(int convId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(convId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Returns all messages for a conversation (single fetch).
  Future<List<Message>> getMessages(int convId) {
    return (select(messages)
          ..where((t) => t.conversationId.equals(convId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Inserts a message and returns its generated id.
  Future<int> insertMessage(MessagesCompanion data) {
    return into(messages).insert(data);
  }

  /// Updates a message's content and optional stats (for streaming completion).
  Future<void> updateMessage(
    int id, {
    String? content,
    double? tokensPerSec,
    int? totalTokens,
    int? durationMs,
  }) {
    return (update(messages)..where((t) => t.id.equals(id))).write(
      MessagesCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        tokensPerSec:
            tokensPerSec != null ? Value(tokensPerSec) : const Value.absent(),
        totalTokens:
            totalTokens != null ? Value(totalTokens) : const Value.absent(),
        durationMs:
            durationMs != null ? Value(durationMs) : const Value.absent(),
      ),
    );
  }

  /// Deletes a message by id.
  Future<void> deleteMessage(int id) {
    return (delete(messages)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes all messages for a specific conversation.
  Future<void> deleteMessagesForConversation(int convId) {
    return (delete(messages)..where((t) => t.conversationId.equals(convId))).go();
  }
}
