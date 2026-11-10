import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Provides the singleton [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openConnection());
  ref.onDispose(db.close);
  return db;
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(dbFolder.path, 'ollama_gui'));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }
    final file = File(p.join(dbDir.path, 'chat.db'));
    return NativeDatabase.createInBackground(file, logStatements: false);
  });
}
