import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/lesson_tile.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stage_timeline.dart';
import '../../data/models/enums.dart';
import '../settings/theme_mode_provider.dart';

/// Internal design-system gallery. Every core widget in every state,
/// in both themes — the visual regression surface for the app's look.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معرض المكونات'),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _GallerySection(title: 'الخط والنصوص'),
          Text(
            'مسار ابن عثيمين',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text(
            'رحلة طالب العلم تبدأ من هنا',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'قال الشيخ رحمه الله: العلم يحتاج إلى تدرج، فيبدأ الطالب بصغار العلم قبل كباره، ٤٥ درسًا في ١٢ أسبوعًا.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),

          const _GallerySection(title: 'شارات المستوى'),
          const Wrap(
            spacing: AppSpacing.sm,
            children: [
              LevelBadge(level: JourneyLevel.beginner),
              LevelBadge(level: JourneyLevel.intermediate),
              LevelBadge(level: JourneyLevel.advanced),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const _GallerySection(title: 'حلقات التقدم'),
          const Row(
            children: [
              ProgressRing(progress: 0.0, showLabel: true),
              SizedBox(width: AppSpacing.lg),
              ProgressRing(progress: 0.35, showLabel: true),
              SizedBox(width: AppSpacing.lg),
              ProgressRing(progress: 0.72, showLabel: true),
              SizedBox(width: AppSpacing.lg),
              ProgressRing(progress: 1.0),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const _GallerySection(title: 'بطاقات المسارات'),
          JourneyCard(
            title: 'مسار العقيدة',
            description: 'رحلة متدرجة في تعلم العقيدة الصحيحة من أصولها',
            level: JourneyLevel.beginner,
            stageCount: 3,
            lessonCount: 45,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          JourneyCard(
            title: 'مسار الفقه — زاد المستقنع',
            description: 'الشرح الممتع على زاد المستقنع كاملًا',
            level: JourneyLevel.intermediate,
            stageCount: 8,
            lessonCount: 340,
            progress: 0.42,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xl),

          const _GallerySection(title: 'الدروس'),
          LessonTile(
            index: 1,
            title: 'مقدمة الشرح وبيان منهج المؤلف رحمه الله',
            duration: const Duration(minutes: 45),
            progress: 1,
            onTap: () {},
          ),
          LessonTile(
            index: 2,
            title: 'باب المياه: أقسام المياه وأحكامها',
            duration: const Duration(minutes: 52),
            progress: 0.6,
            onTap: () {},
          ),
          LessonTile(
            index: 3,
            title: 'باب الآنية وما يتعلق بها من أحكام',
            duration: const Duration(hours: 1, minutes: 5),
            isPlaying: true,
            progress: 0.1,
            onTap: () {},
          ),
          LessonTile(
            index: 4,
            title: 'باب الاستنجاء وآداب قضاء الحاجة',
            duration: const Duration(minutes: 48),
            onTap: () {},
          ),
          const LessonTile(
            index: 5,
            title: 'درس محذوف من المصدر',
            unavailable: true,
          ),
          const SizedBox(height: AppSpacing.xl),

          const _GallerySection(title: 'الخط الزمني للمراحل'),
          StageTimelineNode(
            index: 1,
            title: 'المرحلة الأولى: الأصول الثلاثة',
            description: 'معرفة العبد ربه ودينه ونبيه ﷺ',
            state: StageState.done,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'شرح ثلاثة الأصول — مكتمل',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          StageTimelineNode(
            index: 2,
            title: 'المرحلة الثانية: كتاب التوحيد',
            description: 'حق الله على العبيد',
            state: StageState.current,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'شرح كتاب التوحيد — ٤٠٪',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const StageTimelineNode(
            index: 3,
            title: 'المرحلة الثالثة: العقيدة الواسطية',
            state: StageState.upcoming,
            isLast: true,
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(title: 'متابعة المشاهدة', onSeeAll: () {}),
          const SizedBox(height: AppSpacing.sm),

          const _GallerySection(title: 'هياكل التحميل'),
          const Row(
            children: [
              Skeleton(width: 120, height: 68),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 180),
                    SizedBox(height: AppSpacing.sm),
                    Skeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
