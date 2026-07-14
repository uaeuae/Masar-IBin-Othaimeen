import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/lesson_row.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/resume_hero_card.dart';
import '../../core/widgets/science_glyph.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stage_timeline.dart';
import '../../data/models/enums.dart';
import '../settings/theme_mode_provider.dart';

/// Internal design-system gallery — every core component in every state,
/// in both themes. Kept in sync with docs/design/masar-screens.dc.html.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('معرض المكونات', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: 'تبديل المظهر',
            onPressed: () => ref.read(themeModeProvider.notifier).cycle(),
            icon: Icon(switch (mode) {
              ThemeMode.system => Icons.brightness_auto_rounded,
              ThemeMode.light => Icons.light_mode_rounded,
              ThemeMode.dark => Icons.dark_mode_rounded,
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section('الخط — Amiri للعناوين، Plex للواجهة'),
          Text(
            'شرح ثلاثة الأصول',
            style: serif(30, theme.colorScheme.onSurface),
          ),
          Text('أهلًا بك يا طالب العلم', style: theme.textTheme.headlineSmall),
          Text(
            'قال الشيخ رحمه الله: العلم يحتاج إلى تدرج — ٤٥ درسًا في ١٢ أسبوعًا.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          const _Section('شارات المستوى'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LevelBadge(level: JourneyLevel.beginner),
              LevelBadge(level: JourneyLevel.intermediate),
              LevelBadge(level: JourneyLevel.advanced),
              LevelBadge(level: JourneyLevel.beginner, onHero: true),
            ],
          ),
          const SizedBox(height: 24),

          const _Section('رموز العلوم'),
          const Row(
            children: [
              ScienceGlyph(nameAr: 'العقيدة', sortOrder: 1, size: 44),
              SizedBox(width: 10),
              ScienceGlyph(nameAr: 'الفقه', sortOrder: 2, size: 44),
              SizedBox(width: 10),
              ScienceGlyph(nameAr: 'التفسير', sortOrder: 4, size: 44),
              SizedBox(width: 10),
              ScienceGlyph(nameAr: 'أصول الفقه', sortOrder: 5, size: 44),
            ],
          ),
          const SizedBox(height: 24),

          const _Section('الرقائق والمقاطع'),
          Row(
            children: [
              MasarChip(label: 'الكل', selected: true, onTap: () {}),
              const SizedBox(width: 8),
              MasarChip(label: 'العقيدة', selected: false, onTap: () {}),
              const SizedBox(width: 8),
              MasarChip(label: 'الفقه', selected: false, onTap: () {}),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedControl<JourneyLevel>(
            segments: {for (final l in JourneyLevel.values) l: l.labelAr},
            selected: JourneyLevel.beginner,
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),

          const _Section('حلقات التقدم'),
          const Row(
            children: [
              ProgressRing(progress: 0.33, showLabel: true),
              SizedBox(width: 16),
              ProgressRing(progress: 0.72, showLabel: true),
              SizedBox(width: 16),
              ProgressRing(progress: 1.0),
            ],
          ),
          const SizedBox(height: 24),

          const _Section('متابعة المشاهدة'),
          ResumeHeroCard(
            seriesTitle: 'الشرح الممتع على زاد المستقنع',
            lessonLabel: 'الدرس ١٢ — كتاب الطهارة · باب المياه',
            progress: 0.42,
            stoppedAt: const Duration(minutes: 12, seconds: 34),
            remaining: const Duration(minutes: 25),
            onTap: () {},
          ),
          const SizedBox(height: 24),

          const _Section('بطاقة مسار'),
          JourneyCard(
            title: 'مسار العقيدة — المستوى الأول',
            level: JourneyLevel.beginner,
            stageCount: 5,
            scienceName: 'العقيدة',
            scienceSortOrder: 1,
            seriesPreview:
                'ثلاثة الأصول ← القواعد الأربع ← كشف الشبهات ← كتاب التوحيد',
            enrolled: true,
            progress: 0.33,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          const _Section('صفوف الدروس'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                LessonRow(
                  title: 'الدرس ١ — مقدمة الرسالة',
                  state: LessonRowState.completed,
                  duration: const Duration(minutes: 42, seconds: 10),
                  onTap: () {},
                ),
                LessonRow(
                  title: 'الدرس ٢ — القاعدة الأولى',
                  state: LessonRowState.current,
                  progress: 0.4,
                  duration: const Duration(minutes: 45, seconds: 30),
                  onTap: () {},
                ),
                LessonRow(
                  title: 'الدرس ٣ — القاعدة الثانية: الشفاعة',
                  state: LessonRowState.upcoming,
                  duration: const Duration(minutes: 51, seconds: 20),
                  onTap: () {},
                ),
                const LessonRow(
                  title: 'الدرس ٤ — درس محذوف',
                  state: LessonRowState.unavailable,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const _Section('الخط الزمني للمراحل'),
          StageTimelineNode(
            index: 1,
            state: StageState.done,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(
                'شرح ثلاثة الأصول — مكتملة ✓',
                style: serif(18, theme.colorScheme.onSurface),
              ),
            ),
          ),
          StageTimelineNode(
            index: 2,
            state: StageState.current,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(
                'شرح القواعد الأربع — ٣ من ٨',
                style: serif(18, theme.colorScheme.onSurface),
              ),
            ),
          ),
          StageTimelineNode(
            index: 3,
            state: StageState.upcoming,
            isLast: true,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Text(
                'شرح كشف الشبهات',
                style: serif(18, masarColorsOf(context).chipText),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const _Section('هياكل التحميل'),
          const Row(
            children: [
              Skeleton(width: 120, height: 68),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 180),
                    SizedBox(height: 8),
                    Skeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
