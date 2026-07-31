import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/scholar_avatar.dart';
import '../../core/widgets/series_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/view_models.dart';
import '../library/library_providers.dart';
import 'scholar_providers.dart';

/// A scholar's own page (design 4b) — the screen that makes the app plural.
///
/// Without it a scholar is only ever a caption on someone else's card, and the
/// app reads as though it belonged to him. Here he is the subject: his series,
/// his totals, and his foundation's permission line, which differs per scholar
/// and so cannot live in app-wide chrome.
///
/// Left out of the design's version deliberately: «متابَع» (following needs a
/// model we do not have) and the المسارات/الفتاوى/نبذة tabs (no data behind
/// them yet).
class ScholarScreen extends ConsumerWidget {
  const ScholarScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholar = ref.watch(scholarProvider(slug));
    final scholarsAsync = ref.watch(scholarsProvider);

    if (scholar == null) {
      return Scaffold(
        body: SafeArea(
          child: scholarsAsync.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Skeleton(height: 220, width: double.infinity),
                )
              : const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(children: [BackCircle()]),
                    ),
                    Expanded(
                      child: EmptyState(
                        icon: Icons.person_off_outlined,
                        title: 'الشيخ غير موجود',
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(scholar: scholar)),
          if (scholar.status.isComingSoon)
            SliverToBoxAdapter(child: _ComingSoon(scholar: scholar))
          else
            _SeriesList(slug: slug),
          SliverToBoxAdapter(child: _Permission(scholar: scholar)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.scholar});

  final ScholarInfo scholar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final stats = ref.watch(scholarStatsProvider(scholar.slug)).value;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: masar.headerGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: BackCircle(style: BackCircleStyle.onHero),
              ),
              const SizedBox(height: 14),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: masar.gold.withAlpha(0x99), width: 2),
                ),
                alignment: Alignment.center,
                child: ScholarAvatar.of(scholar, size: 70, onHero: true),
              ),
              const SizedBox(height: 12),
              Text(
                scholar.nameAr,
                textAlign: TextAlign.center,
                style: serif(24, masar.onHero, height: 1.3),
              ),
              if (scholar.honorificAr != null) ...[
                const SizedBox(height: 4),
                Text(
                  scholar.honorificAr!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: masar.onHeroFaint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              if (stats != null && stats.seriesCount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    seriesCountLabel(stats.seriesCount),
                    lessonCountLabel(stats.lessonCount),
                    if (stats.totalDurationSeconds > 0)
                      durationLabel(
                        Duration(seconds: stats.totalDurationSeconds),
                      ),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: masar.onHeroDim,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesList extends ConsumerWidget {
  const _SeriesList({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByScholarProvider(slug));
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final series = seriesAsync.value;

    if (series == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Skeleton(height: 200, width: double.infinity),
        ),
      );
    }
    if (series.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.auto_stories_rounded,
          title: 'لا سلاسل بعد',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      sliver: SliverList.separated(
        itemCount: series.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = series[index];
          // His own name on every card would say nothing here, so the design
          // puts the science in its place: «الفقه · ٣٤٨ حلقة · ٢٩٠ ساعة».
          final science = sciences
              .where((s) => s.slug == entry.scienceSlug)
              .firstOrNull;
          return SeriesCard(series: entry, scienceNameAr: science?.nameAr);
        },
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.scholar});

  final ScholarInfo scholar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: masar.goldTintBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'قريبًا إن شاء الله',
              style: TextStyle(
                fontFamily: kUiFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: masar.goldTintFg,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'دروس ${scholar.nameAr} لم تُضف بعد. نعمل على إضافتها من مصادرها '
            'الرسمية بإذن الله.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// «جميع المواد بإذن …» — the design's per-scholar permission footer. It sits
/// here rather than in app chrome precisely because it is not the same line for
/// every scholar.
class _Permission extends StatelessWidget {
  const _Permission({required this.scholar});

  final ScholarInfo scholar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final links = <(String, String)>[
      if (scholar.website != null) ('الموقع الرسمي', scholar.website!),
      if (scholar.youtubeUrl != null) ('القناة الرسمية', scholar.youtubeUrl!),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: masar.attributionBg,
          borderRadius: BorderRadius.circular(AppRadius.group),
          border: Border.all(color: masar.attributionBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, size: 16, color: masar.goldTintFg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'جميع المواد بإذن ${scholar.foundationAr}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: masar.attributionText,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
            if (links.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final (label, url) in links)
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
