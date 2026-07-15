import 'models/catalog.dart' show CatalogChapter;
import 'models/enums.dart';

/// Plain read-models produced by repository queries for the screens.
/// Progress percentages are always derived from lesson_progress — never stored.

class JourneySummary {
  const JourneySummary({
    required this.slug,
    required this.titleAr,
    this.descriptionAr,
    required this.level,
    this.scienceSlug,
    this.coverUrl,
    required this.stageCount,
    required this.lessonCount,
    required this.completedCount,
    required this.totalDurationSeconds,
    required this.enrolled,
    this.seriesPreview = '',
  });

  final String slug;
  final String titleAr;
  final String? descriptionAr;
  final JourneyLevel level;
  final String? scienceSlug;
  final String? coverUrl;
  final int stageCount;
  final int lessonCount;
  final int completedCount;
  final int totalDurationSeconds;
  final bool enrolled;

  /// Stage sequence teaser: "ثلاثة الأصول ← القواعد الأربع ← الواسطية".
  final String seriesPreview;

  double get progress => lessonCount == 0 ? 0 : completedCount / lessonCount;
}

class SeriesWithProgress {
  const SeriesWithProgress({
    required this.slug,
    required this.titleAr,
    this.descriptionAr,
    this.thumbnailUrl,
    required this.scienceSlug,
    required this.lessonCount,
    required this.completedCount,
    this.totalDurationSeconds = 0,
    this.level,
    this.media = LessonMedia.video,
  });

  final String slug;
  final String titleAr;
  final String? descriptionAr;
  final String? thumbnailUrl;
  final String scienceSlug;
  final int lessonCount;
  final int completedCount;
  final int totalDurationSeconds;
  final JourneyLevel? level;
  final LessonMedia media;

  double get progress => lessonCount == 0 ? 0 : completedCount / lessonCount;

  bool get started => completedCount > 0;
}

class StageDetail {
  const StageDetail({
    required this.position,
    required this.titleAr,
    this.descriptionAr,
    required this.series,
  });

  final int position;
  final String titleAr;
  final String? descriptionAr;
  final List<SeriesWithProgress> series;

  int get lessonCount => series.fold(0, (sum, s) => sum + s.lessonCount);
  int get completedCount => series.fold(0, (sum, s) => sum + s.completedCount);
  bool get isDone => lessonCount > 0 && completedCount >= lessonCount;
  bool get isStarted => completedCount > 0;
}

class JourneyDetail {
  const JourneyDetail({required this.summary, required this.stages});

  final JourneySummary summary;
  final List<StageDetail> stages;

  /// First stage that isn't finished — the "current" node on the timeline.
  int get currentStagePosition {
    for (final stage in stages) {
      if (!stage.isDone) return stage.position;
    }
    return stages.isEmpty ? 1 : stages.last.position;
  }
}

class LessonWithProgress {
  const LessonWithProgress({
    required this.videoId,
    required this.position,
    required this.titleAr,
    this.durationSeconds,
    required this.status,
    required this.watchedSeconds,
    required this.completed,
    this.media = LessonMedia.video,
    this.audioUrl,
    this.chapters = const [],
  });

  final String videoId;
  final int position;
  final String titleAr;
  final int? durationSeconds;
  final LessonStatus status;
  final int watchedSeconds;
  final bool completed;
  final LessonMedia media;
  final String? audioUrl;
  final List<CatalogChapter> chapters;

  double get progress {
    if (completed) return 1;
    final total = durationSeconds;
    if (total == null || total == 0 || watchedSeconds <= 0) return 0;
    return (watchedSeconds / total).clamp(0.0, 0.99);
  }
}

class SeriesDetail {
  const SeriesDetail({required this.series, required this.lessons});

  final SeriesWithProgress series;
  final List<LessonWithProgress> lessons;

  /// The lesson "استئناف" should open: first partial, else first not completed.
  LessonWithProgress? get resumeTarget {
    for (final lesson in lessons) {
      if (lesson.status != LessonStatus.active) continue;
      if (!lesson.completed && lesson.watchedSeconds > 0) return lesson;
    }
    for (final lesson in lessons) {
      if (lesson.status != LessonStatus.active) continue;
      if (!lesson.completed) return lesson;
    }
    return null;
  }
}

class ContinueWatchingItem {
  const ContinueWatchingItem({
    required this.videoId,
    required this.titleAr,
    required this.position,
    required this.seriesSlug,
    required this.seriesTitleAr,
    required this.watchedSeconds,
    this.durationSeconds,
    required this.lastWatchedAt,
  });

  final String videoId;
  final String titleAr;
  final int position;
  final String seriesSlug;
  final String seriesTitleAr;
  final int watchedSeconds;
  final int? durationSeconds;
  final DateTime lastWatchedAt;

  double get progress {
    final total = durationSeconds;
    if (total == null || total == 0) return 0;
    return (watchedSeconds / total).clamp(0.0, 1.0);
  }
}

class ScienceSummary {
  const ScienceSummary({
    required this.slug,
    required this.nameAr,
    this.descriptionAr,
    this.icon,
    required this.sortOrder,
    required this.seriesCount,
    required this.lessonCount,
  });

  final String slug;
  final String nameAr;
  final String? descriptionAr;
  final String? icon;
  final int sortOrder;
  final int seriesCount;
  final int lessonCount;
}
