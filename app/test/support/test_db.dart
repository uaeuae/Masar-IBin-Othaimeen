import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:masar/data/db/database.dart';
import 'package:sqlite3/open.dart';

bool _overridden = false;

/// In-memory database for tests. On Windows the sqlite3 package can't find
/// sqlite3.dll, so we load the OS-provided winsqlite3.dll instead.
AppDatabase openTestDatabase() {
  if (!_overridden) {
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
  return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
}
