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
  if (Platform.isWindows && !_overridden) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
    _overridden = true;
  }
  return AppDatabase(DatabaseConnection(NativeDatabase.memory()));
}
