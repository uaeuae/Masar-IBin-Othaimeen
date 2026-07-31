import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:masar/data/db/database.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

bool _overridden = false;

void _ensureSqliteLoaded() {
  if (_overridden) return;
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  // Widget tests deliberately leak in-memory databases (closing deadlocks
  // under FakeAsync) — suppress the noisy debug warning.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  _overridden = true;
}

/// In-memory database for tests. On Windows the sqlite3 package can't find
/// sqlite3.dll, so we load the OS-provided winsqlite3.dll instead.
AppDatabase openTestDatabase() {
  _ensureSqliteLoaded();
  return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
}

/// An [AppDatabase] over a connection that already holds an *older* schema, so
/// drift runs its real upgrade path over it.
///
/// The DDL has to be applied to the raw sqlite handle before drift ever sees
/// it: opening an [AppDatabase] runs `onCreate` and lays down the current
/// schema, after which there is no old install left to upgrade.
AppDatabase openTestDatabaseAt(int schemaVersion, List<String> ddl) {
  _ensureSqliteLoaded();
  final raw = sqlite3.openInMemory();
  for (final statement in ddl) {
    raw.execute(statement);
  }
  raw.execute('PRAGMA user_version = $schemaVersion');
  return AppDatabase(DatabaseConnection(NativeDatabase.opened(raw)));
}
