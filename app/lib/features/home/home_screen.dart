import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/resume_hero_card.dart';
import '../../core/widgets/science_glyph.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';
import '../journeys/journeys_providers.dart';
import '../library/library_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final continueWatching =
        ref.watch(continueWatchingProvider).value ?? const [];
    final enrolled = ref.watch(enrolledJourneysProvider).value ?? const [];
    final journeys = ref.watch(journeySummariesProvider).value ?? const [];
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final level = ref.watch(levelFilterProvider);

    final enrolledSlugs = {for (final j in enrolled) j.slug};
    final suggestions = journeys
        .where((j) => !enrolledSlugs.contains(j.slug))
        .where((j) => j.level == level)
        .take(2)
        .toList();
    final fallbackSuggestions = journeys
        .where((j) => !enrolledSlugs.contains(j.slug))
        .take(2)
        .toList();
    final shown = suggestions.isEmpty ? fallbackSuggestions : suggestions;
    final resume = continueWatching.isEmpty ? null : continueWatching.first;

    String scienceName(String? slug) =>
        sciences
            .where((s) => s.slug == slug)
            .map((s) => s.nameAr)
            .firstOrNull ??
        '';
    int scienceOrder(String? slug) =>
        sciences
            .where((s) => s.slug == slug)
            .map((s) => s.sortOrder)
            .firstOrNull ??
        1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ── Greeting + settings ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السلام عليكم ورحمة الله',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أهلًا بك يا طالب العلم',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'الإعدادات',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: masar.chipBorder),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Level chips (onboarding replacement) ─────────────────
            Row(
              children: [
                for (final l in JourneyLevel.values) ...[
                  MasarChip(
                    label: l.labelAr,
                    selected: level == l,
                    onTap: () => ref.read(levelFilterProvider.notifier).set(l),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── متابعة المشاهدة ──────────────────────────────────────
            if (resume != null) ...[
              Text('متابعة المشاهدة', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ResumeHeroCard(
                seriesTitle: resume.seriesTitleAr,
                lessonLabel:
                    'الدرس ${arabicDigits(resume.position)} — ${resume.titleAr}',
                progress: resume.progress,
                stoppedAt: Duration(seconds: resume.watchedSeconds),
                remaining: resume.durationSeconds == null
                    ? null
                    : Duration(
                        seconds:
                            (resume.durationSeconds! - resume.watchedSeconds)
                                .clamp(0, 1 << 31),
                      ),
                onTap: () => context.push(
                  '/player/${resume.videoId}?series=${resume.seriesSlug}',
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── مساراتي ─────────────────────────────────────────────
            if (enrolled.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text('مساراتي', style: theme.textTheme.titleLarge),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/journeys'),
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontFamily: kUiFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final journey in enrolled) ...[
                _EnrolledJourneyRow(journey: journey),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],

            // ── مسارات مقترحة ────────────────────────────────────────
            if (shown.isNotEmpty) ...[
              Text(
                enrolled.isEmpty ? 'ابدأ رحلتك' : 'مسارات مقترحة لك',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final journey in shown) ...[
                    Expanded(
                      child: _SuggestionCard(
                        journey: journey,
                        scienceName: scienceName(journey.scienceSlug),
                        scienceSortOrder: scienceOrder(journey.scienceSlug),
                      ),
                    ),
                    if (journey != shown.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// White row card: 52px progress ring, title, "المرحلة X من Y" subtitle.
class _EnrolledJourneyRow extends ConsumerWidget {
  const _EnrolledJourneyRow({required this.journey});

  final JourneySummary journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final detail = ref.watch(journeyDetailProvider(journey.slug)).value;

    String subtitle =
        '${stageCountLabel(journey.stageCount)} · ${lessonCountLabel(journey.lessonCount)}';
    if (detail != null && detail.stages.isNotEmpty) {
      final current = detail.currentStagePosition;
      final stage = detail.stages.firstWhere(
        (s) => s.position == current,
        orElse: () => detail.stages.first,
      );
      final series =
          stage.series
              .where((s) => s.completedCount < s.lessonCount)
              .firstOrNull ??
          stage.series.firstOrNull;
      subtitle =
          'المرحلة ${arabicDigits(current)} من ${arabicDigits(detail.stages.length)}';
      if (series != null) {
        final next = (series.completedCount + 1).clamp(
          1,
          series.lessonCount == 0 ? 1 : series.lessonCount,
        );
        subtitle +=
            ' · ${series.titleAr} — الدرس ${arabicDigits(next)} من ${arabicDigits(series.lessonCount)}';
      }
    }

    return Card(
      child: InkWell(
        onTap: () => context.push('/journey/${journey.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProgressRing(progress: journey.progress, showLabel: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.titleAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: masar.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-up suggestion card: glyph, bold title, series-sequence teaser.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.journey,
    required this.scienceName,
    required this.scienceSortOrder,
  });

  final JourneySummary journey;
  final String scienceName;
  final int scienceSortOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.push('/journey/${journey.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScienceGlyph(
                nameAr: scienceName,
                sortOrder: scienceSortOrder,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                journey.titleAr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                journey.seriesPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
