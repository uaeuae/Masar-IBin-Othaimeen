import 'package:drift/drift.dart';

import 'db/database.dart';

/// Writes to the user-owned tables. Local-first; `synced_at` stays null
/// until Phase 2 introduces optional account sync.
class ProgressRepository {
  ProgressRepository(this.db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

  Future<LessonProgressData?> getProgress(String videoId) => (db.select(
    db.lessonProgress,
  )..where((p) => p.videoId.equals(videoId))).getSingleOrNull();

  /// Upserts watch position. Never un-completes a lesson: rewatching part of
  /// a finished lesson must not reset the checkmark.
  Future<void> saveWatchPosition({
    required String videoId,
    required int watchedSeconds,
    int? durationSeconds,
  }) async {
    final now = _now();
    await db.customStatement(
      '''
      INSERT INTO lesson_progress (video_id, watched_seconds, duration_seconds, completed, last_watched_at, updated_at)
      VALUES (?, ?, ?, 0, ?, ?)
      ON CONFLICT(video_id) DO UPDATE SET
        watched_seconds = excluded.watched_seconds,
        duration_seconds = COALESCE(excluded.duration_seconds, lesson_progress.duration_seconds),
        last_watched_at = excluded.last_watched_at,
        updated_at = excluded.updated_at,
        -- Listening again undoes a dismissal; otherwise a lesson swiped away
        -- once could never return to the list.
        dismissed = 0
      ''',
      [
        videoId,
        watchedSeconds,
        durationSeconds,
        now.millisecondsSinceEpoch ~/ 1000,
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    db.markTablesUpdated({db.lessonProgress});
  }

  /// [watchedSeconds] is where the listener actually stopped. It matters
  /// because completion fires at a *fraction* of the lesson, not at its end:
  /// recording the full duration instead loses the difference between "heard it
  /// all" and "stopped a minute short", and the player needs that to know
  /// whether reopening should resume or start over.
  Future<void> markCompleted(
    String videoId, {
    int? durationSeconds,
    int? watchedSeconds,
  }) async {
    final now = _now();
    await db
        .into(db.lessonProgress)
        .insertOnConflictUpdate(
          LessonProgressCompanion(
            videoId: Value(videoId),
            watchedSeconds: Value(watchedSeconds ?? durationSeconds ?? 0),
            durationSeconds: Value(durationSeconds),
            completed: const Value(true),
            lastWatchedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  /// Takes a lesson off «متابعة الاستماع» without losing the saved position —
  /// reopening it still resumes where the listener stopped.
  Future<void> dismissFromContinue(String videoId) async {
    await (db.update(db.lessonProgress)
          ..where((p) => p.videoId.equals(videoId)))
        .write(
          LessonProgressCompanion(
            dismissed: const Value(true),
            updatedAt: Value(_now()),
          ),
        );
  }

  /// Explicit «التحق بالمسار». Undoes a previous removal — asking for it back
  /// is a clearer signal than the removal was.
  Future<void> enroll(String journeySlug) async {
    final now = _now();
    await db
        .into(db.journeyEnrollments)
        .insertOnConflictUpdate(
          JourneyEnrollmentsCompanion.insert(
            journeySlug: journeySlug,
            enrolledAt: now,
            lastActivityAt: now,
            dismissed: const Value(false),
          ),
        );
  }

  /// Enrols in whatever مسارات teach [seriesSlug], because listening to a
  /// lesson from one *is* starting it.
  ///
  /// Enrolment used to require finding the مسار and tapping «التحق», so a
  /// reader could work through a book for an hour and still see an empty
  /// «مساراتي» — which is what it looked like to anyone who reached a lesson
  /// from the library or from search rather than through the مسار screen.
  ///
  /// Only ever inserts. A مسار the reader removed stays removed: resurrecting
  /// it on the next lesson would make the remove button useless.
  Future<void> enrolInJourneysOf(String seriesSlug) async {
    final now = _now();
    final slugs = await (db.selectOnly(db.journeyItems, distinct: true)
          ..addColumns([db.journeyItems.journeySlug])
          ..where(db.journeyItems.seriesSlug.equals(seriesSlug)))
        .map((row) => row.read(db.journeyItems.journeySlug)!)
        .get();

    for (final slug in slugs) {
      await db
          .into(db.journeyEnrollments)
          .insert(
            JourneyEnrollmentsCompanion.insert(
              journeySlug: slug,
              enrolledAt: now,
              lastActivityAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await touchEnrollment(slug);
    }
  }

  /// Takes a مسار off «مساراتي» without forgetting a single lesson of it —
  /// the progress is in `lesson_progress`, which this does not touch. Tapping
  /// «التحق» again brings it back with everything intact.
  Future<void> leaveJourney(String journeySlug) async {
    await (db.update(db.journeyEnrollments)
          ..where((e) => e.journeySlug.equals(journeySlug)))
        .write(const JourneyEnrollmentsCompanion(dismissed: Value(true)));
  }

  Future<void> touchEnrollment(String journeySlug) async {
    await (db.update(db.journeyEnrollments)
          ..where((e) => e.journeySlug.equals(journeySlug)))
        .write(JourneyEnrollmentsCompanion(lastActivityAt: Value(_now())));
  }
}
