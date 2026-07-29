import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'download_repository.dart';

/// Why a download can't start right now.
class DownloadBlockedException implements Exception {
  const DownloadBlockedException(this.messageAr);
  final String messageAr;
  @override
  String toString() => messageAr;
}

typedef NetworkCheck = Future<bool> Function();

/// Runs the download queue, one lesson at a time.
///
/// Serial on purpose: a زاد المستقنع book is up to 392 lessons, and letting
/// those race would saturate the connection, starve playback of bandwidth, and
/// give the foundation's server a small stampede. One at a time also makes
/// "cancel" mean something predictable.
class DownloadManager {
  DownloadManager({
    required this.repository,
    required this.allowedOnCurrentNetwork,
    HttpClient Function()? httpClient,
  }) : _newClient = httpClient ?? HttpClient.new;

  final DownloadRepository repository;

  /// False when we're on mobile data and the user hasn't allowed it.
  final NetworkCheck allowedOnCurrentNetwork;
  final HttpClient Function() _newClient;

  final _queue = <_Job>[];
  bool _running = false;
  String? _current;
  bool _cancelCurrent = false;

  String? get currentVideoId => _current;

  /// Queues one lesson. Throws [DownloadBlockedException] if the network rules
  /// say no, so the caller can surface it before anything looks like it started.
  Future<void> download({
    required String videoId,
    required String seriesSlug,
    required String url,
  }) async {
    if (!await allowedOnCurrentNetwork()) {
      throw const DownloadBlockedException(
        'التنزيل متوقف على شبكة Wi-Fi. يمكنك السماح ببيانات الجوال من الإعدادات.',
      );
    }
    final existing = await repository.status(videoId);
    if (existing != null && (existing.isDone || existing.isActive)) return;

    await repository.enqueue(videoId: videoId, seriesSlug: seriesSlug);
    _queue.add(_Job(videoId: videoId, seriesSlug: seriesSlug, url: url));
    unawaited(_drain());
  }

  /// Queues a whole series, skipping what's already there. Returns how many
  /// were added.
  Future<int> downloadAll(
    List<({String videoId, String seriesSlug, String url})> lessons,
  ) async {
    if (lessons.isEmpty) return 0;
    if (!await allowedOnCurrentNetwork()) {
      throw const DownloadBlockedException(
        'التنزيل متوقف على شبكة Wi-Fi. يمكنك السماح ببيانات الجوال من الإعدادات.',
      );
    }
    var added = 0;
    for (final lesson in lessons) {
      final existing = await repository.status(lesson.videoId);
      if (existing != null && (existing.isDone || existing.isActive)) continue;
      await repository.enqueue(
        videoId: lesson.videoId,
        seriesSlug: lesson.seriesSlug,
      );
      _queue.add(
        _Job(
          videoId: lesson.videoId,
          seriesSlug: lesson.seriesSlug,
          url: lesson.url,
        ),
      );
      added++;
    }
    if (added > 0) unawaited(_drain());
    return added;
  }

  /// Cancels a queued or in-flight download and clears its row and partial file.
  Future<void> cancel(String videoId) async {
    _queue.removeWhere((job) => job.videoId == videoId);
    if (_current == videoId) _cancelCurrent = true;
    await repository.remove(videoId);
  }

  Future<void> cancelAll() async {
    _queue.clear();
    if (_current != null) _cancelCurrent = true;
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        _current = job.videoId;
        _cancelCurrent = false;
        try {
          await _run(job);
        } on Object catch (error) {
          debugPrint('download ${job.videoId} failed: $error');
          await repository.markFailed(job.videoId, '$error');
        }
        _current = null;
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _run(_Job job) async {
    // Re-check per lesson: a series download can outlive the Wi-Fi that
    // started it, and silently finishing it over mobile data is exactly what
    // the setting exists to prevent.
    if (!await allowedOnCurrentNetwork()) {
      await repository.markFailed(job.videoId, 'في انتظار شبكة Wi-Fi');
      return;
    }

    final file = await repository.fileFor(job.videoId);
    final partial = File('${file.path}.part');
    final client = _newClient();
    try {
      final request = await client.getUrl(Uri.parse(job.url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await repository.markFailed(job.videoId, 'HTTP ${response.statusCode}');
        return;
      }

      final total = response.contentLength > 0 ? response.contentLength : null;
      await repository.markDownloading(job.videoId, totalBytes: total);

      final sink = partial.openWrite();
      var received = 0;
      var lastReported = 0;
      try {
        await for (final chunk in response) {
          if (_cancelCurrent) {
            await sink.close();
            if (partial.existsSync()) await partial.delete();
            return;
          }
          sink.add(chunk);
          received += chunk.length;
          // Writing every chunk would hammer drift (and every listening
          // widget) hundreds of times a second.
          if (received - lastReported >= 256 * 1024) {
            lastReported = received;
            await repository.updateProgress(job.videoId, received);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (received == 0) {
        if (partial.existsSync()) await partial.delete();
        await repository.markFailed(job.videoId, 'الملف فارغ');
        return;
      }

      // Rename only once the bytes are all down, so a half-file can never be
      // mistaken for a finished download.
      if (file.existsSync()) await file.delete();
      await partial.rename(file.path);
      await repository.markDone(job.videoId, received);
    } finally {
      client.close(force: true);
      if (partial.existsSync()) {
        try {
          await partial.delete();
        } on FileSystemException {
          // Already renamed away.
        }
      }
    }
  }
}

class _Job {
  const _Job({
    required this.videoId,
    required this.seriesSlug,
    required this.url,
  });

  final String videoId;
  final String seriesSlug;
  final String url;
}
