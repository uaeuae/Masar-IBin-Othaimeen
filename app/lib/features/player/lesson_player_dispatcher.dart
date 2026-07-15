import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';
import '../series/series_providers.dart';
import 'audio_player_screen.dart';
import 'player_screen.dart';

/// Routes /player/:id to the right player: the YouTube embed for video
/// lessons, the background-capable audio player for foundation MP3s.
class LessonPlayerDispatcher extends ConsumerWidget {
  const LessonPlayerDispatcher({
    super.key,
    required this.lessonId,
    this.seriesSlug,
  });

  final String lessonId;
  final String? seriesSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = seriesSlug;
    if (slug == null) {
      return PlayerScreen(videoId: lessonId, seriesSlug: null);
    }

    final detailAsync = ref.watch(seriesDetailProvider(slug));
    return detailAsync.when(
      // Match the players' always-dark chrome while resolving.
      loading: () => Theme(
        data: buildTheme(Brightness.dark),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (error, stack) => PlayerScreen(
        videoId: lessonId,
        seriesSlug: slug,
      ),
      data: (detail) {
        final lesson = detail?.lessons
            .where((l) => l.videoId == lessonId)
            .firstOrNull;
        if (lesson?.media == LessonMedia.audio) {
          return AudioPlayerScreen(lessonId: lessonId, seriesSlug: slug);
        }
        return PlayerScreen(videoId: lessonId, seriesSlug: slug);
      },
    );
  }
}
