import 'package:drift/drift.dart';

import 'db/database.dart';

/// Writes to the user-owned tables. Local-first; `synced_at` stays null
/// until Phase 2 introduces optional account sync.
class ProgressRepository {
  ProgressRepository(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _now;

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
        updated_at = excluded.updated_at
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

  Future<void> markCompleted(String videoId, {int? durationSeconds}) async {
    final now = _now();
    await db.into(db.lessonProgress).insertOnConflictUpdate(
          LessonProgressCompanion(
            videoId: Value(videoId),
            watchedSeconds: Value(durationSeconds ?? 0),
            durationSeconds: Value(durationSeconds),
            completed: const Value(true),
            lastWatchedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> enroll(String journeySlug) async {
    final now = _now();
    await db.into(db.journeyEnrollments).insert(
          JourneyEnrollmentsCompanion.insert(
            journeySlug: journeySlug,
            enrolledAt: now,
            lastActivityAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> touchEnrollment(String journeySlug) async {
    await (db.update(db.journeyEnrollments)..where((e) => e.journeySlug.equals(journeySlug))).write(
      JourneyEnrollmentsCompanion(lastActivityAt: Value(_now())),
    );
  }
}
