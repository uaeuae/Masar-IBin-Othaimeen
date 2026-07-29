import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

class DownloadedLesson {
  const DownloadedLesson({
    required this.videoId,
    required this.position,
    required this.titleAr,
    required this.bytes,
  });

  final String videoId;
  final int position;
  final String titleAr;
  final int bytes;
}

class DownloadedSeries {
  const DownloadedSeries({
    required this.seriesSlug,
    required this.seriesTitleAr,
    required this.lessons,
  });

  final String seriesSlug;
  final String seriesTitleAr;
  final List<DownloadedLesson> lessons;

  int get bytes => lessons.fold(0, (sum, l) => sum + l.bytes);
}

/// Finished downloads, grouped by series and joined to the catalog for titles
/// and lesson order. Recomputes whenever a download lands or is deleted.
final downloadedLessonsProvider = FutureProvider<List<DownloadedSeries>>((
  ref,
) async {
  // Re-run on any download change.
  ref.watch(downloadsProvider);

  final repository = ref.watch(downloadRepositoryProvider);
  final done = await repository.allDone();
  if (done.isEmpty) return const [];

  final db = ref.watch(databaseProvider);
  final rows = await db.customSelect('''
    SELECT l.video_id, l.position, l.title_ar, l.series_slug, s.title_ar AS series_title
    FROM lessons l
    JOIN series s ON s.slug = l.series_slug
    ORDER BY s.title_ar, l.position
  ''').get();

  final byId = {
    for (final row in rows) row.read<String>('video_id'): row,
  };

  final groups = <String, List<DownloadedLesson>>{};
  final titles = <String, String>{};
  for (final status in done) {
    final row = byId[status.videoId];
    if (row == null) continue;
    final slug = row.read<String>('series_slug');
    titles[slug] = row.read<String>('series_title');

    final file = await repository.fileFor(status.videoId);
    groups
        .putIfAbsent(slug, () => [])
        .add(
          DownloadedLesson(
            videoId: status.videoId,
            position: row.read<int>('position'),
            titleAr: row.read<String>('title_ar'),
            bytes: file.existsSync() ? file.lengthSync() : status.receivedBytes,
          ),
        );
  }

  final result = [
    for (final entry in groups.entries)
      DownloadedSeries(
        seriesSlug: entry.key,
        seriesTitleAr: titles[entry.key] ?? entry.key,
        lessons: entry.value..sort((a, b) => a.position.compareTo(b.position)),
      ),
  ]..sort((a, b) => a.seriesTitleAr.compareTo(b.seriesTitleAr));
  return result;
});

/// Bytes actually occupied on disk — the honest number for the settings page,
/// rather than the sum of what the rows claim.
final downloadedBytesProvider = FutureProvider<int>((ref) async {
  ref.watch(downloadsProvider);
  final repository = ref.watch(downloadRepositoryProvider);
  try {
    return await repository.bytesOnDisk();
  } on FileSystemException {
    return 0;
  }
});
