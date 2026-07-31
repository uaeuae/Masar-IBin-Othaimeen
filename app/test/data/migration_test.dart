import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_db.dart';

/// Upgrades from old installs.
///
/// This file exists because there were none, and a crash-on-launch upgrade bug
/// shipped as a result. The trap is specific to drift and easy to re-introduce:
/// `Migrator.createTable` emits DDL from the table's **current** definition, not
/// from what that table looked like at the version that introduced it. So a
/// `createTable` in an early `if (from < N)` block already produces every column
/// a later block then tries to `addColumn` — and SQLite rejects the duplicate,
/// which aborts the migration and leaves the app unable to open its database.
void main() {
  /// The schema as it stood at v4: no `scholars`, no `downloads`, and none of
  /// the columns added by v5–v10. Only the tables the migration actually
  /// touches are needed.
  const v4Ddl = [
    '''
    CREATE TABLE sciences (
      slug TEXT NOT NULL PRIMARY KEY, name_ar TEXT NOT NULL,
      description_ar TEXT NULL, icon TEXT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0);
    ''',
    '''
    CREATE TABLE series (
      slug TEXT NOT NULL PRIMARY KEY, science_slug TEXT NOT NULL,
      title_ar TEXT NOT NULL, description_ar TEXT NULL, thumbnail_url TEXT NULL,
      level TEXT NULL, media_type TEXT NOT NULL DEFAULT 'video',
      companion_of TEXT NULL, companion_slug TEXT NULL);
    ''',
    '''
    CREATE TABLE lessons (
      video_id TEXT NOT NULL PRIMARY KEY, series_slug TEXT NOT NULL,
      position INTEGER NOT NULL, title_ar TEXT NOT NULL,
      duration_seconds INTEGER NULL, status TEXT NOT NULL DEFAULT 'active',
      media_type TEXT NOT NULL DEFAULT 'video', audio_url TEXT NULL,
      chapters_json TEXT NULL);
    ''',
    '''
    CREATE TABLE lesson_progress (
      video_id TEXT NOT NULL PRIMARY KEY, watched_seconds INTEGER NOT NULL,
      duration_seconds INTEGER NULL, completed INTEGER NOT NULL DEFAULT 0,
      last_watched_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
      synced_at INTEGER NULL);
    ''',
  ];

  test('createTable emits todays columns, not the version that added it', () async {
    // The mechanism behind the bug, pinned on its own so the reason this
    // matters survives even if the migration is later restructured.
    final db = openTestDatabase();
    addTearDown(db.close);
    await Migrator(db).createTable(db.scholars);

    final columns = await db
        .customSelect('PRAGMA table_info(scholars)')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('name')).toSet());

    // `scholars` shipped with five columns at schemaVersion 5; these arrived at
    // 10. createTable produces them anyway.
    expect(columns, containsAll(['slug', 'name_ar', 'foundation_ar']));
    expect(
      columns,
      containsAll(['initial_ar', 'accent', 'honorific_ar', 'status', 'youtube_url']),
      reason: 'createTable is not version-aware — the v10 block must not re-add these',
    );
  });

  test('an install from before the scholars table upgrades cleanly', () async {
    // The shipping bug: v4 runs `createTable(scholars)` (which already includes
    // the v10 columns) and then the v10 block tried to add them again, so the
    // migration threw "duplicate column name" and the app could not open its
    // database at all. A tester on a pre-2026-07-17 build hit this on update.
    final db = openTestDatabaseAt(4, v4Ddl);
    addTearDown(db.close);

    // The query is what forces the migration to run; without it the connection
    // is lazy and the test would pass having proved nothing.
    await expectLater(db.customSelect('SELECT 1').get(), completes);
    final stored = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((row) => row.read<int>('user_version'));
    expect(stored, 10, reason: 'migration ran to completion and stamped v10');

    // And the table really is the current shape, so catalog import works.
    final columns = await db
        .customSelect('PRAGMA table_info(scholars)')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
    expect(columns, contains('initial_ar'));
  });

  test('an install that already had the v5 scholars table still gains v10 columns', () async {
    // The other side of the same fix: for these installs the columns really are
    // missing, so skipping the addColumn block would be just as broken.
    final db = openTestDatabaseAt(9, [
      ...v4Ddl,
      '''
      CREATE TABLE scholars (
        slug TEXT NOT NULL PRIMARY KEY, name_ar TEXT NOT NULL,
        foundation_ar TEXT NOT NULL, website TEXT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0);
      ''',
      'ALTER TABLE series ADD COLUMN scholar_slug TEXT NOT NULL DEFAULT \'ibn-uthaymeen\'',
      'ALTER TABLE series ADD COLUMN book_author_ar TEXT NULL',
      'ALTER TABLE lessons ADD COLUMN text_kind TEXT NULL',
      'ALTER TABLE lessons ADD COLUMN gain_db REAL NULL',
      'ALTER TABLE lesson_progress ADD COLUMN dismissed INTEGER NOT NULL DEFAULT 0',
      '''
      CREATE TABLE downloads (
        video_id TEXT NOT NULL PRIMARY KEY, series_slug TEXT NOT NULL,
        state TEXT NOT NULL DEFAULT 'queued', file_name TEXT NOT NULL,
        received_bytes INTEGER NOT NULL DEFAULT 0, total_bytes INTEGER NULL,
        error TEXT NULL, requested_at INTEGER NOT NULL,
        completed_at INTEGER NULL);
      ''',
      "INSERT INTO scholars (slug, name_ar, foundation_ar, sort_order) "
          "VALUES ('ibn-uthaymeen', 'الشيخ محمد بن صالح العثيمين', 'مؤسسة', 1)",
    ]);
    addTearDown(db.close);

    final scholars = await db.select(db.scholars).get();
    expect(scholars.single.initialAr, '؟'); // the column default, until import
    expect(scholars.single.nameAr, 'الشيخ محمد بن صالح العثيمين'); // row survived
  });
}
