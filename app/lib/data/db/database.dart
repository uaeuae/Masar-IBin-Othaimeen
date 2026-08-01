import 'package:drift/drift.dart';

part 'database.g.dart';

// ── Catalog tables (replaced wholesale on catalog import) ──────────────────

class Scholars extends Table {
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();

  /// «ابن عثيمين» — for chips, cards and the resume line, where the full name
  /// would ellipsize. Curated, not derived: it is neither the first word of
  /// [nameAr] nor the last.
  TextColumn get shortNameAr => text().nullable()();

  /// The letter in his roundel. Curated in the seed — it comes from the شهرة
  /// (العثيمين → ع), so it cannot be taken from the start of [nameAr].
  TextColumn get initialAr => text().withDefault(const Constant('؟'))();

  /// Palette key the theme resolves: green | blue | gold.
  TextColumn get accent => text().withDefault(const Constant('green'))();

  /// «رحمه الله» / «حفظه الله».
  TextColumn get honorificAr => text().nullable()();

  /// active | coming_soon. A coming-soon scholar is announced with no series.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Rights holder credited in attribution.
  TextColumn get foundationAr => text()();
  TextColumn get website => text().nullable()();
  TextColumn get youtubeUrl => text().nullable()();
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

  /// Author of the matn being explained, when known — usually not the scholar.
  TextColumn get bookAuthorAr => text().nullable()();

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

  /// Swiped off «متابعة الاستماع». A flag rather than a delete, so removing a
  /// lesson from that list never throws away where you stopped in it.
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
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

  /// Taken off «مساراتي» by the reader. A flag rather than a delete, because
  /// listening to any lesson in the مسار enrolls automatically — deleting the
  /// row would just invite it back on the next lesson.
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();

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
  int get schemaVersion => 12;

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
      // `createTable` is NOT version-aware: it emits DDL from the table's
      // definition as it stands today, so a table created here already has
      // every column that later versions added. Any `addColumn` on such a
      // table must therefore be skipped for installs that reached this branch,
      // or SQLite rejects the duplicate and the whole migration aborts —
      // leaving the app unable to open its database at all. See
      // test/data/migration_test.dart.
      final createdScholars = from < 5;
      if (createdScholars) {
        await m.createTable(scholars);
        await m.addColumn(seriesEntries, seriesEntries.scholarSlug);
      }
      if (from < 6) {
        await m.addColumn(lessons, lessons.textKind);
      }
      // Same rule as `createdScholars` above: anything added to `downloads`
      // after v7 must be guarded with `&& !createdDownloads`.
      final createdDownloads = from < 7;
      if (createdDownloads) {
        await m.addColumn(lessons, lessons.gainDb);
        await m.createTable(downloads);
      }
      if (from < 8) {
        await m.addColumn(lessonProgress, lessonProgress.dismissed);
      }
      if (from < 9) {
        await m.addColumn(seriesEntries, seriesEntries.bookAuthorAr);
      }
      if (from < 10 && !createdScholars) {
        await m.addColumn(scholars, scholars.initialAr);
        await m.addColumn(scholars, scholars.accent);
        await m.addColumn(scholars, scholars.honorificAr);
        await m.addColumn(scholars, scholars.status);
        await m.addColumn(scholars, scholars.youtubeUrl);
      }
      if (from < 11 && !createdScholars) {
        await m.addColumn(scholars, scholars.shortNameAr);
      }
    },
  );
}
