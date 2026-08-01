// `drift` and `matcher` both export `isNull`/`isNotNull`; the matchers are what
// a test wants.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/db/database.dart';

import '../support/test_db.dart';

/// table name → its column names, read from the database itself rather than
/// from the Dart definitions — which is the whole point: the definitions are
/// what a migration is supposed to catch up to.
Future<Map<String, Set<String>>> schemaOf(AppDatabase db) async {
  final schema = <String, Set<String>>{};
  for (final table in db.allTables) {
    final rows = await db
        .customSelect('PRAGMA table_info(${table.actualTableName})')
        .get();
    schema[table.actualTableName] = rows
        .map((row) => row.read<String>('name'))
        .toSet();
  }
  return schema;
}

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
  /// the columns added by v5 onwards.
  ///
  /// **Every** table is listed, including the ones no migration has ever
  /// touched. A fixture that names only the interesting tables is not an old
  /// install — it is a database that could not exist — and the missing ones are
  /// exactly where a forgotten migration hides, because nothing compares them
  /// to anything.
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
    '''
    CREATE TABLE journeys (
      slug TEXT NOT NULL PRIMARY KEY, title_ar TEXT NOT NULL,
      description_ar TEXT NULL, level TEXT NOT NULL, science_slug TEXT NULL,
      cover_url TEXT NULL, sort_order INTEGER NOT NULL DEFAULT 0);
    ''',
    '''
    CREATE TABLE journey_stages (
      journey_slug TEXT NOT NULL, position INTEGER NOT NULL,
      title_ar TEXT NOT NULL, description_ar TEXT NULL,
      PRIMARY KEY (journey_slug, position));
    ''',
    '''
    CREATE TABLE journey_items (
      journey_slug TEXT NOT NULL, stage_position INTEGER NOT NULL,
      position INTEGER NOT NULL, series_slug TEXT NOT NULL,
      PRIMARY KEY (journey_slug, stage_position, position));
    ''',
    // The table v12 forgot. It has never been created or altered by any
    // migration, which is why it went unnoticed: it has been present since v1,
    // so every install has it — in its v1 shape.
    '''
    CREATE TABLE journey_enrollments (
      journey_slug TEXT NOT NULL PRIMARY KEY, enrolled_at INTEGER NOT NULL,
      last_activity_at INTEGER NOT NULL);
    ''',
    '''
    CREATE TABLE catalog_info (
      id INTEGER NOT NULL PRIMARY KEY DEFAULT 1,
      version INTEGER NOT NULL DEFAULT 0, generated_at INTEGER NULL);
    ''',
  ];

  /// v4 plus everything v5–v11 added, i.e. the schema the last shipped build
  /// upgraded *from*.
  final v11Ddl = [
    ...v4Ddl,
    // v5
    '''
    CREATE TABLE scholars (
      slug TEXT NOT NULL PRIMARY KEY, name_ar TEXT NOT NULL,
      foundation_ar TEXT NOT NULL, website TEXT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0);
    ''',
    "ALTER TABLE series ADD COLUMN scholar_slug TEXT NOT NULL DEFAULT 'ibn-uthaymeen'",
    'ALTER TABLE lessons ADD COLUMN text_kind TEXT NULL', // v6
    'ALTER TABLE lessons ADD COLUMN gain_db REAL NULL', // v7
    '''
    CREATE TABLE downloads (
      video_id TEXT NOT NULL PRIMARY KEY, series_slug TEXT NOT NULL,
      state TEXT NOT NULL DEFAULT 'queued', file_name TEXT NOT NULL,
      received_bytes INTEGER NOT NULL DEFAULT 0, total_bytes INTEGER NULL,
      error TEXT NULL, requested_at INTEGER NOT NULL,
      completed_at INTEGER NULL);
    ''',
    'ALTER TABLE lesson_progress ADD COLUMN dismissed INTEGER NOT NULL DEFAULT 0', // v8
    'ALTER TABLE series ADD COLUMN book_author_ar TEXT NULL', // v9
    // v10
    "ALTER TABLE scholars ADD COLUMN initial_ar TEXT NOT NULL DEFAULT '؟'",
    "ALTER TABLE scholars ADD COLUMN accent TEXT NOT NULL DEFAULT 'green'",
    'ALTER TABLE scholars ADD COLUMN honorific_ar TEXT NULL',
    "ALTER TABLE scholars ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
    'ALTER TABLE scholars ADD COLUMN youtube_url TEXT NULL',
    'ALTER TABLE scholars ADD COLUMN short_name_ar TEXT NULL', // v11
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
      containsAll([
        'initial_ar', 'accent', 'honorific_ar', 'status', 'youtube_url', // v10
        'short_name_ar', // v11
      ]),
      reason: 'createTable is not version-aware — later blocks must not re-add these',
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
    expect(stored, 13, reason: 'migration ran to completion and stamped v13');

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
    expect(scholars.single.shortNameAr, isNull); // nullable, until import
    expect(scholars.single.nameAr, 'الشيخ محمد بن صالح العثيمين'); // row survived
  });

  test('an upgraded install ends at the schema a fresh install creates', () async {
    // The guard that was missing. Every other test here checks a column
    // someone already knew to look at; this one compares the *whole* schema,
    // so a column added to a table definition without a matching migration
    // fails here on the commit that adds it.
    //
    // That is precisely how v12 shipped: `journey_enrollments.dismissed` was
    // declared and never migrated. Every test in the suite builds a fresh
    // database, where `createAll` produces the column regardless — so the
    // suite stayed green while upgraded installs lost «مساراتي» entirely.
    final fresh = openTestDatabase();
    addTearDown(fresh.close);
    final upgraded = openTestDatabaseAt(4, v4Ddl);
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get(); // forces the migration

    expect(
      await schemaOf(upgraded),
      await schemaOf(fresh),
      reason: 'a column added to a table needs a migration, not just a field',
    );
  });

  test('an install upgrading from v11 gains journey_enrollments.dismissed', () async {
    // The shipped bug, from the version readers actually had.
    final db = openTestDatabaseAt(11, [
      ...v11Ddl,
      "INSERT INTO journey_enrollments (journey_slug, enrolled_at, last_activity_at) "
          "VALUES ('masar-alaqeedah', 0, 0)",
    ]);
    addTearDown(db.close);

    // Not just that the column exists — that the query which went dark can run
    // and still finds the enrolment. Nobody's progress was deleted; it was
    // unreadable, and this is the line that proves it comes back.
    final enrolled = await db
        .customSelect(
          'SELECT journey_slug FROM journey_enrollments WHERE dismissed = 0',
        )
        .get();
    expect(enrolled.map((r) => r.read<String>('journey_slug')), [
      'masar-alaqeedah',
    ]);
  });

  test('an install *created* by the v12 build upgrades without a duplicate column', () async {
    // The other half of an ambiguous version, and the reason the fix cannot be
    // a plain `addColumn`. A reader who installed fresh on the broken build got
    // `dismissed` from `createAll` and was stamped 12 all the same — so v12 on
    // disk means "column present" for them and "column absent" for everyone who
    // upgraded. Adding it unconditionally would trade one broken group for
    // another, and this one would fail to open the database at all.
    final db = openTestDatabaseAt(12, [
      ...v11Ddl,
      'ALTER TABLE journey_enrollments ADD COLUMN dismissed INTEGER NOT NULL DEFAULT 0',
    ]);
    addTearDown(db.close);

    await expectLater(db.customSelect('SELECT 1').get(), completes);
    final columns = await db
        .customSelect('PRAGMA table_info(journey_enrollments)')
        .get()
        .then((rows) => rows.map((r) => r.read<String>('name')).toList());
    expect(
      columns.where((c) => c == 'dismissed'),
      hasLength(1),
      reason: 'added once, not twice',
    );
  });
}
