import 'package:drift/drift.dart';

part 'database.g.dart';

// ── Catalog tables (replaced wholesale on catalog import) ──────────────────

class Sciences extends Table {
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();
  TextColumn get descriptionAr => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {slug};
}

@DataClassName('SeriesRow')
class SeriesEntries extends Table {
  @override
  String get tableName => 'series';

  TextColumn get slug => text()();
  TextColumn get scienceSlug => text()();
  TextColumn get titleAr => text()();
  TextColumn get descriptionAr => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();

  /// 'beginner' | 'intermediate' | 'advanced' — optional curation metadata.
  TextColumn get level => text().nullable()();

  @override
  Set<Column> get primaryKey => {slug};
}

class Lessons extends Table {
  TextColumn get videoId => text()();
  TextColumn get seriesSlug => text()();
  IntColumn get position => integer()();
  TextColumn get titleAr => text()();
  IntColumn get durationSeconds => integer().nullable()();

  /// 'active' | 'hidden' | 'unavailable'
  TextColumn get status => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {videoId};
}

class Journeys extends Table {
  TextColumn get slug => text()();
  TextColumn get titleAr => text()();
  TextColumn get descriptionAr => text().nullable()();

  /// 'beginner' | 'intermediate' | 'advanced'
  TextColumn get level => text()();
  TextColumn get scienceSlug => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {slug};
}

class JourneyStages extends Table {
  TextColumn get journeySlug => text()();
  IntColumn get position => integer()();
  TextColumn get titleAr => text()();
  TextColumn get descriptionAr => text().nullable()();

  @override
  Set<Column> get primaryKey => {journeySlug, position};
}

class JourneyItems extends Table {
  TextColumn get journeySlug => text()();
  IntColumn get stagePosition => integer()();
  IntColumn get position => integer()();
  TextColumn get seriesSlug => text()();

  @override
  Set<Column> get primaryKey => {journeySlug, stagePosition, position};
}

class CatalogInfo extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get generatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── User tables (never touched by catalog imports; sync-ready for Phase 2) ─

class LessonProgress extends Table {
  TextColumn get videoId => text()();
  IntColumn get watchedSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastWatchedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {videoId};
}

class JourneyEnrollments extends Table {
  TextColumn get journeySlug => text()();
  DateTimeColumn get enrolledAt => dateTime()();
  DateTimeColumn get lastActivityAt => dateTime()();

  @override
  Set<Column> get primaryKey => {journeySlug};
}

@DriftDatabase(
  tables: [
    Sciences,
    SeriesEntries,
    Lessons,
    Journeys,
    JourneyStages,
    JourneyItems,
    CatalogInfo,
    LessonProgress,
    JourneyEnrollments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(seriesEntries, seriesEntries.level);
      }
    },
  );
}
