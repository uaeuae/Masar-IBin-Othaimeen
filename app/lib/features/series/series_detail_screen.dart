import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lesson_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';
import '../downloads/download_button.dart';
import '../downloads/series_download_bar.dart';
import '../library/library_providers.dart';
import 'book_about_card.dart';
import 'series_providers.dart';

class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(seriesDetailProvider(slug));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: detailAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const [Skeleton(height: 260, width: double.infinity)],
          ),
          error: (error, stack) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'تعذر تحميل السلسلة',
          ),
          data: (detail) {
            if (detail == null) {
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'السلسلة غير موجودة',
              );
            }
            return _SeriesDetailBody(detail: detail);
          },
        ),
      ),
    );
  }
}

class _SeriesDetailBody extends ConsumerWidget {
  const _SeriesDetailBody({required this.detail});

  final SeriesDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final series = detail.series;
    final resume = detail.resumeTarget;
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final scholar = (ref.watch(scholarsProvider).value ?? const [])
        .where((s) => s.slug == series.scholarSlug)
        .firstOrNull;
    final scienceName =
        sciences
            .where((s) => s.slug == series.scienceSlug)
            .map((s) => s.nameAr)
            .firstOrNull ??
        '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Row(children: [BackCircle()]),
        const SizedBox(height: 16),

        // ── Header ────────────────────────────────────────────────────
        Text(
          scienceName,
          style: TextStyle(
            fontFamily: kUiFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(series.titleAr, style: serif(30, scheme.onSurface, height: 1.25)),
        const SizedBox(height: 6),
        Text(
          // Counts and hours live in «عن الكتاب» directly below; repeating them
          // here just said the same thing twice.
          // Named per scholar — «المؤسسة» would mean whichever one the reader
          // happened to assume.
          series.media == LessonMedia.audio
              ? 'صوتيات ${scholar?.foundationAr ?? 'المصدر الرسمي'}'
              : 'القناة الرسمية',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // ── عن الكتاب ─────────────────────────────────────────────────
        BookAboutCard(
          series: series,
          scienceName: scienceName,
          scholar: scholar,
          bookAuthorAr: series.bookAuthorAr,
          hasReadAlongText: detail.lessons.any((l) => l.textKind != null),
          // «نص الكتاب» is assembled from the timed passage markers, so it needs
          // chapters and not merely text. A source that publishes a flat
          // transcript has none — the reader's text is the lesson itself, and
          // offering a button to an empty screen would just be a dead end.
          onOpenBookText: detail.lessons.any((l) => l.chapters.isNotEmpty)
              ? () => context.push('/series/${series.slug}/book')
              : null,
        ),
        const SizedBox(height: 16),

        // ── Resume banner ─────────────────────────────────────────────
        if (resume != null) ...[
          GestureDetector(
            onTap: () =>
                context.push('/player/${resume.videoId}?series=${series.slug}'),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: masar.heroGreen,
                borderRadius: BorderRadius.circular(AppRadius.group),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: masar.onHero,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 24,
                      color: masar.heroGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${resume.watchedSeconds > 0 ? 'استئناف' : 'ابدأ'} — الدرس ${arabicDigits(resume.position)}',
                        style: TextStyle(
                          fontFamily: kUiFont,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: masar.onHero,
                        ),
                      ),
                      if (resume.watchedSeconds > 0 &&
                          resume.durationSeconds != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'توقفت عند ${clockLabel(Duration(seconds: resume.watchedSeconds))} من ${clockLabel(Duration(seconds: resume.durationSeconds!))}',
                          style: TextStyle(
                            fontFamily: kUiFont,
                            fontSize: 11.5,
                            color: masar.onHeroFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Audio edition / video edition cross-link ──────────────────
        if (series.companionSlug != null) ...[
          _CompanionBanner(
            icon: Icons.headphones_rounded,
            title: 'الاستماع للنسخة الصوتية',
            subtitle: 'دروس السلسلة كاملة — تعمل في الخلفية وبالشاشة مقفلة',
            onTap: () => context.push('/series/${series.companionSlug}'),
          ),
          const SizedBox(height: 16),
        ] else if (series.companionOf != null) ...[
          _CompanionBanner(
            icon: Icons.ondemand_video_rounded,
            title: 'مشاهدة النسخة المرئية',
            subtitle: 'مقاطع الدروس على القناة الرسمية',
            onTap: () => context.push('/series/${series.companionOf}'),
          ),
          const SizedBox(height: 16),
        ],

        // ── Download the whole series ─────────────────────────────────
        if (series.media == LessonMedia.audio) ...[
          SeriesDownloadBar(slug: series.slug, lessons: detail.lessons),
          const SizedBox(height: 16),
        ],

        // ── Lesson list (one grouped card) ────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, lesson) in detail.lessons.indexed)
                LessonRow(
                  title:
                      'الدرس ${arabicDigits(lesson.position)} — ${lesson.titleAr}',
                  state: lesson.status != LessonStatus.active
                      ? LessonRowState.unavailable
                      : lesson.completed
                      ? LessonRowState.completed
                      : lesson.videoId == resume?.videoId
                      ? LessonRowState.current
                      : LessonRowState.upcoming,
                  duration: lesson.durationSeconds == null
                      ? null
                      : Duration(seconds: lesson.durationSeconds!),
                  progress: lesson.progress,
                  showDivider: index != detail.lessons.length - 1,
                  trailing:
                      lesson.media == LessonMedia.audio &&
                          lesson.status == LessonStatus.active
                      ? DownloadButton(
                          videoId: lesson.videoId,
                          seriesSlug: series.slug,
                          audioUrl: lesson.audioUrl,
                        )
                      : null,
                  onTap: () => context.push(
                    '/player/${lesson.videoId}?series=${series.slug}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cross-link between a video series and its full audio edition.
class _CompanionBanner extends StatelessWidget {
  const _CompanionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.group),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(0x1F),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: kUiFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: kUiFont,
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
