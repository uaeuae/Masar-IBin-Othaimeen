import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import 'db/database.dart';

/// Where a lesson's offline copy stands.
enum DownloadState {
  queued,
  downloading,
  done,
  failed;

  static DownloadState fromJson(String value) => switch (value) {
    'queued' => DownloadState.queued,
    'downloading' => DownloadState.downloading,
    'done' => DownloadState.done,
    'failed' => DownloadState.failed,
    _ => DownloadState.failed,
  };
}

class DownloadStatus {
  const DownloadStatus({
    required this.videoId,
    required this.seriesSlug,
    required this.state,
    required this.receivedBytes,
    this.totalBytes,
    this.error,
  });

  final String videoId;
  final String seriesSlug;
  final DownloadState state;
  final int receivedBytes;
  final int? totalBytes;
  final String? error;

  bool get isDone => state == DownloadState.done;
  bool get isActive =>
      state == DownloadState.queued || state == DownloadState.downloading;

  /// 0..1, or null while the server hasn't declared a length.
  double? get progress {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (receivedBytes / total).clamp(0.0, 1.0);
  }
}

/// Owns the download bookkeeping and the files on disk.
///
/// Rows live in a user table, so a catalog import never clears them; the files
/// are stored under a directory this class resolves at runtime, and rows keep
/// only the basename — iOS moves the app container between installs, so an
/// absolute path saved today may not resolve tomorrow.
class DownloadRepository {
  DownloadRepository(this.db, {Future<Directory> Function()? directory})
    : _resolveDirectory = directory ?? defaultDirectory;

  final AppDatabase db;
  final Future<Directory> Function() _resolveDirectory;
  Directory? _cached;

  static Future<Directory> defaultDirectory() async {
    // Application Support, not Documents: this is re-downloadable content and
    // Apple expects it kept out of the user's document store.
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}lesson_audio');
  }

  Future<Directory> directory() async {
    final cached = _cached;
    if (cached != null) return cached;
    final dir = await _resolveDirectory();
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _cached = dir;
  }

  static String fileNameFor(String videoId) {
    // Lesson ids are YouTube ids or site uuids; neither is guaranteed to be a
    // safe filename, so keep only characters that are.
    final safe = videoId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '$safe.mp3';
  }

  Future<File> fileFor(String videoId) async {
    final dir = await directory();
    return File('${dir.path}${Platform.pathSeparator}${fileNameFor(videoId)}');
  }

  /// Local path to play instead of the network, or null if not downloaded.
  Future<String?> localPathFor(String videoId) async {
    final row = await (db.select(
      db.downloads,
    )..where((d) => d.videoId.equals(videoId))).getSingleOrNull();
    if (row == null || DownloadState.fromJson(row.state) != DownloadState.done) {
      return null;
    }
    final file = await fileFor(videoId);
    if (!file.existsSync()) {
      // The OS reclaimed it, or a restore dropped the file but kept the row.
      await remove(videoId);
      return null;
    }
    return file.path;
  }

  Stream<Map<String, DownloadStatus>> watchAll() {
    return db.select(db.downloads).watch().map(
      (rows) => {
        for (final row in rows) row.videoId: _statusOf(row),
      },
    );
  }

  Stream<DownloadStatus?> watch(String videoId) {
    return (db.select(
      db.downloads,
    )..where((d) => d.videoId.equals(videoId))).watchSingleOrNull().map(
      (row) => row == null ? null : _statusOf(row),
    );
  }

  Future<DownloadStatus?> status(String videoId) async {
    final row = await (db.select(
      db.downloads,
    )..where((d) => d.videoId.equals(videoId))).getSingleOrNull();
    return row == null ? null : _statusOf(row);
  }

  Future<List<DownloadStatus>> allDone() async {
    final rows = await (db.select(
      db.downloads,
    )..where((d) => d.state.equals(DownloadState.done.name))).get();
    return [for (final row in rows) _statusOf(row)];
  }

  DownloadStatus _statusOf(Download row) => DownloadStatus(
    videoId: row.videoId,
    seriesSlug: row.seriesSlug,
    state: DownloadState.fromJson(row.state),
    receivedBytes: row.receivedBytes,
    totalBytes: row.totalBytes,
    error: row.error,
  );

  Future<void> enqueue({
    required String videoId,
    required String seriesSlug,
  }) async {
    await db
        .into(db.downloads)
        .insertOnConflictUpdate(
          DownloadsCompanion.insert(
            videoId: videoId,
            seriesSlug: seriesSlug,
            fileName: fileNameFor(videoId),
            state: Value(DownloadState.queued.name),
            receivedBytes: const Value(0),
            error: const Value(null),
            requestedAt: DateTime.now(),
          ),
        );
  }

  Future<void> markDownloading(String videoId, {int? totalBytes}) async {
    await (db.update(db.downloads)..where((d) => d.videoId.equals(videoId)))
        .write(
          DownloadsCompanion(
            state: Value(DownloadState.downloading.name),
            totalBytes: Value(totalBytes),
            error: const Value(null),
          ),
        );
  }

  Future<void> updateProgress(String videoId, int receivedBytes) async {
    await (db.update(db.downloads)..where((d) => d.videoId.equals(videoId)))
        .write(DownloadsCompanion(receivedBytes: Value(receivedBytes)));
  }

  Future<void> markDone(String videoId, int totalBytes) async {
    await (db.update(db.downloads)..where((d) => d.videoId.equals(videoId)))
        .write(
          DownloadsCompanion(
            state: Value(DownloadState.done.name),
            receivedBytes: Value(totalBytes),
            totalBytes: Value(totalBytes),
            completedAt: Value(DateTime.now()),
            error: const Value(null),
          ),
        );
  }

  Future<void> markFailed(String videoId, String error) async {
    await (db.update(db.downloads)..where((d) => d.videoId.equals(videoId)))
        .write(
          DownloadsCompanion(
            state: Value(DownloadState.failed.name),
            error: Value(error),
          ),
        );
  }

  /// Drops the row and the file — used for both "delete" and cleanup after a
  /// cancelled or broken download.
  Future<void> remove(String videoId) async {
    await (db.delete(db.downloads)..where((d) => d.videoId.equals(videoId))).go();
    final file = await fileFor(videoId);
    if (file.existsSync()) await file.delete();
    final partial = File('${file.path}.part');
    if (partial.existsSync()) await partial.delete();
  }

  Future<void> removeAll() async {
    final rows = await db.select(db.downloads).get();
    for (final row in rows) {
      await remove(row.videoId);
    }
  }

  /// Bytes actually on disk — what the settings screen reports, rather than
  /// the sum of what we believe we downloaded.
  Future<int> bytesOnDisk() async {
    final dir = await directory();
    if (!dir.existsSync()) return 0;
    var total = 0;
    for (final entity in dir.listSync()) {
      if (entity is File) total += entity.lengthSync();
    }
    return total;
  }
}
