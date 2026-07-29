import 'package:drift/drift.dart';

part 'database.g.dart';

// ── Catalog tables (replaced wholesale on catalog import) ──────────────────

class Scholars extends Table {
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();

  /// Rights holder credited in attribution.
  TextColumn get foundationAr => text()();
  TextColumn get website => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {slug};
}

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
  TextColumn get scholarSlug =>
      text().withDefault(const Constant('ibn-uthaymeen'))();
  TextColumn get titleAr => text()();
  TextColumn get descriptionAr => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();

  /// 'beginner' | 'intermediate' | 'advanced' — optional curation metadata.
  TextColumn get level => text().nullable()();

  /// 'video' | 'audio'
  TextColumn get mediaType => text().withDefault(const Constant('video'))();

  /// Audio editions: slug of the video series this one mirrors. Companion
  /// series are hidden from library browse.
  TextColumn get companionOf => text().nullable()();

  /// Video series: slug of their full audio edition, if one exists.
  TextColumn get companionSlug => text().nullable()();

  @override
  Set<Column> get primaryKey => {slug};
}

class Lessons extends Table {
  /// External id: YouTube video id, or the site lesson uuid for audio.
  TextColumn get videoId => text()();
  TextColumn get seriesSlug => text()();
  IntColumn get position => integer()();
  TextColumn get titleAr => text()();
  IntColumn get durationSeconds => integer().nullable()();

  /// 'active' | 'hidden' | 'unavailable'
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// 'video' | 'audio'
  TextColumn get mediaType => text().withDefault(const Constant('video'))();
  TextColumn get audioUrl => text().nullable()();

  /// JSON list of {start_seconds, title, body} chapter markers (audio only).
  TextColumn get chaptersJson => text().nullable()();

  /// 'transcript' | 'matn' — which read-along script exists under
  /// assets/texts/, or null when the lesson has none.
  TextColumn get textKind => text().nullable()();

  /// Playback correction in dB from the measured loudness (see
  /// `analyze:loudness`). Negative pulls a loud lesson down; positive marks a
  /// quiet one, which only Android can actually boost.
  RealColumn get gainDb => real().nullable()();

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

/// Offline copies of audio lessons. A user table: catalog imports must never
/// drop rows here, or an app update would silently orphan files on disk.
class Downloads extends Table {
  TextColumn get videoId => text()();
  TextColumn get seriesSlug => text()();

  /// 'queued' | 'downloading' | 'done' | 'failed'
  TextColumn get state => text().withDefault(const Constant('queued'))();

  /// Basename under the downloads directory — never an absolute path, which
  /// iOS invalidates whenever the app container is relocated.
  TextColumn get fileName => text()();
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get requestedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {videoId};
}

@DriftDatabase(
  tables: [
    Scholars,
    Sciences,
    SeriesEntries,
    Lessons,
    Journeys,
    JourneyStages,
    JourneyItems,
    CatalogInfo,
    LessonProgress,
    JourneyEnrollments,
    Downloads,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(seriesEntries, seriesEntries.level);
      }
      if (from < 3) {
        await m.addColumn(seriesEntries, seriesEntries.mediaType);
        await m.addColumn(lessons, lessons.mediaType);
        await m.addColumn(lessons, lessons.audioUrl);
        await m.addColumn(lessons, lessons.chaptersJson);
      }
      if (from < 4) {
        await m.addColumn(seriesEntries, seriesEntries.companionOf);
        await m.addColumn(seriesEntries, seriesEntries.companionSlug);
      }
      if (from < 5) {
        await m.createTable(scholars);
        await m.addColumn(seriesEntries, seriesEntries.scholarSlug);
      }
      if (from < 6) {
        await m.addColumn(lessons, lessons.textKind);
      }
      if (from < 7) {
        await m.addColumn(lessons, lessons.gainDb);
        await m.createTable(downloads);
      }
    },
  );
}
