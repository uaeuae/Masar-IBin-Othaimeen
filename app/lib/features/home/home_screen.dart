import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/resume_hero_card.dart';
import '../../core/widgets/scholar_avatar.dart';
import '../../core/widgets/science_glyph.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../journeys/journeys_providers.dart';
import '../onboarding/coach_marks.dart';
import '../scholars/scholar_providers.dart';
import '../settings/theme_mode_provider.dart';
import '../library/library_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _sequence = 'home';
  final _resumeKey = GlobalKey();
  final _levelKey = GlobalKey();
  bool _coachScheduled = false;

  /// Runs once the first time Home has something to point at. Deferred to a
  /// post-frame callback because the marks measure real widgets, which do not
  /// have a size until they are laid out.
  void _maybeShowCoachMarks({required bool hasResume}) {
    if (_coachScheduled) return;
    if (ref.read(seenCoachMarksProvider).contains(_sequence)) return;
    _coachScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showCoachMarks(context, [
        CoachMark(
          key: _levelKey,
          title: 'اختر مستواك',
          body: 'نقترح عليك المسارات المناسبة لمستواك. يمكنك تغييره متى شئت.',
        ),
        if (hasResume)
          CoachMark(
            key: _resumeKey,
            title: 'تابع من حيث توقفت',
            body:
                'آخر درس استمعت إليه يظهر هنا. اسحب البطاقة يمينًا أو يسارًا لإزالته من القائمة — ويبقى موضع توقفك محفوظًا.',
          ),
      ]);
      if (mounted) {
        ref.read(seenCoachMarksProvider.notifier).markSeen(_sequence);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final continueAsync = ref.watch(continueWatchingProvider);
    final continueWatching = continueAsync.value ?? const [];
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
    // Only once the stream has actually answered: on the first build it has no
    // value yet, and deciding then would drop the resume mark for every reader
    // who has one.
    if (continueAsync.hasValue) {
      _maybeShowCoachMarks(hasResume: resume != null);
    }

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
                        border: Border.all(color: masar.greenTintBorder),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        // The design put a clock roundel here, but the button
                        // opens Settings — a clock promised something else.
                        Icons.settings_rounded,
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
            // Scrolls: three chips fit a phone at the default text size with
            // almost nothing to spare, and overflow as soon as the reader turns
            // text up. A chip row that clips is worse than one that scrolls.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                key: _levelKey,
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
            ),
            const SizedBox(height: 20),

            // ── متابعة المشاهدة ──────────────────────────────────────
            if (resume != null) ...[
              Text('متابعة المشاهدة', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Dismissible(
                key: ValueKey('resume-${resume.videoId}'),
                // Either way: a one-way swipe would feel backwards to half the
                // gestures in an RTL layout.
                direction: DismissDirection.horizontal,
                background: const _RemoveSwipeBackground(),
                secondaryBackground: const _RemoveSwipeBackground(),
                confirmDismiss: (_) => _confirmRemove(context),
                onDismissed: (_) => ref
                    .read(progressRepositoryProvider)
                    .dismissFromContinue(resume.videoId),
                child: ResumeHeroCard(
                  key: _resumeKey,
                  seriesTitle: resume.seriesTitleAr,
                  scholar: ref.watch(scholarProvider(resume.scholarSlug)),
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
                // Same gesture as the resume card above it: swipe, confirm,
                // gone. Nothing is forgotten — the lessons keep their progress
                // and «التحق» brings the مسار back with all of it.
                Dismissible(
                  key: ValueKey('journey-${journey.slug}'),
                  direction: DismissDirection.horizontal,
                  background: const _RemoveSwipeBackground(),
                  secondaryBackground: const _RemoveSwipeBackground(),
                  confirmDismiss: (_) => _confirmLeaveJourney(context),
                  onDismissed: (_) => ref
                      .read(progressRepositoryProvider)
                      .leaveJourney(journey.slug),
                  child: _EnrolledJourneyRow(journey: journey),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],

            // ── شيوخك ───────────────────────────────────────────────
            const _ScholarsStrip(),

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
    final bySlug = ref.watch(scholarsBySlugProvider);
    final journeyScholars = [
      for (final slug in journey.scholarSlugs)
        if (bySlug[slug] != null) bySlug[slug]!,
    ];

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
                    // «مسار العقيدة» exists for more than one scholar, so the
                    // title alone does not say which one you enrolled in
                    // (design 4a).
                    if (journeyScholars.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      StackedScholarAvatars(
                        scholars: journeyScholars,
                        size: 18,
                      ),
                    ],
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
                Icons.arrow_forward_ios_rounded,
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

/// Shown behind the resume card while it is being swiped away.
class _RemoveSwipeBackground extends StatelessWidget {
  const _RemoveSwipeBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
          Text(
            'إزالة من المتابعة',
            style: TextStyle(
              fontFamily: kUiFont,
              fontWeight: FontWeight.w600,
              color: scheme.onErrorContainer,
            ),
          ),
          Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
        ],
      ),
    );
  }
}

/// Confirms before the card goes — a swipe is easy to do by accident while
/// scrolling Home.
Future<bool> _confirmLeaveJourney(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('إزالة المسار من الرئيسية؟'),
      // Says what is kept, not just what goes: the worry with a button like
      // this is losing months of listening.
      content: const Text(
        'لن يظهر المسار في «مساراتي»، ويبقى تقدمك في دروسه كما هو. '
        'يمكنك الالتحاق به مجددًا في أي وقت.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('إزالة'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> _confirmRemove(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('إزالة من المتابعة؟'),
      content: const Text(
        'سيختفي الدرس من قائمة المتابعة، ويبقى موضع التوقف محفوظًا إذا عدت إليه.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('إزالة'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// «المشايخ» — the scholar row from design 4a.
///
/// The design calls it «تابِع شيوخك» and draws a follow affordance. There is no
/// following in the app and no model behind it, so this is the browse row it
/// would sit on: tapping opens the scholar, «المزيد» opens the library. Naming
/// it «شيوخك» rather than «تابِع شيوخك» keeps it from promising a verb that
/// does nothing.
class _ScholarsStrip extends ConsumerWidget {
  const _ScholarsStrip();

  /// Room for three plus «المزيد» before the row starts scrolling.
  static const _shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scholars = ref.watch(scholarsProvider).value ?? const <ScholarInfo>[];
    // One scholar is not a set to browse — the resume card already names him.
    if (scholars.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المشايخ', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final scholar in scholars.take(_shown)) ...[
              Expanded(child: _ScholarTile(scholar: scholar)),
              const SizedBox(width: 10),
            ],
            const Expanded(child: _MoreScholarsTile()),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ScholarTile extends StatelessWidget {
  const _ScholarTile({required this.scholar});

  final ScholarInfo scholar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soon = scholar.status.isComingSoon;

    return Card(
      child: InkWell(
        onTap: () => context.push('/scholar/${scholar.slug}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              // Muted, not hidden: announced is a real state worth showing.
              Opacity(
                opacity: soon ? 0.55 : 1,
                child: ScholarAvatar.of(scholar, size: 46),
              ),
              const SizedBox(height: 6),
              Text(
                scholar.displayShortName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreScholarsTile extends StatelessWidget {
  const _MoreScholarsTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return InkWell(
      onTap: () => context.go('/library'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DottedBorderCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add_rounded, size: 20, color: masar.textMuted),
              ),
              const SizedBox(height: 6),
              Text(
                'المزيد',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: masar.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's dashed «المزيد» tile — dashed rather than solid so it reads as
/// an opening rather than another scholar.
class DottedBorderCard extends StatelessWidget {
  const DottedBorderCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outline, style: BorderStyle.solid),
      ),
      child: child,
    );
  }
}
