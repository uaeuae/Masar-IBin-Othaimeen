import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';
import '../player/lesson_text.dart';
import '../player/lesson_text_providers.dart';
import 'series_providers.dart';

/// «نص الكتاب» — the matn on its own, apart from the explanation.
///
/// The sheikh teaches *from* a book he mostly did not write, and a reader
/// should be able to see that book. Assembled from the timed passages already
/// bundled for the read-along, so every line links to the moment it is
/// explained — which a PDF could never do.
class BookTextScreen extends ConsumerWidget {
  const BookTextScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailAsync = ref.watch(seriesDetailProvider(slug));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'تعذر تحميل نص الكتاب',
          ),
          data: (detail) {
            if (detail == null) {
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'السلسلة غير موجودة',
              );
            }
            final lessons = [
              for (final lesson in detail.lessons)
                if (lesson.textKind != null) lesson,
            ];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [BackCircle()]),
                        const SizedBox(height: 14),
                        Text(
                          detail.series.titleAr,
                          style: serif(26, scheme.onSurface, height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'نص الكتاب — المس أي موضع للاستماع إلى شرحه',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (lessons.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'نص الكتاب غير متوفر',
                      message: 'لم يُنشر نص هذه السلسلة في مصدرها.',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: lessons.length,
                    // Built lazily, one lesson's passages at a time: رياض
                    // الصالحين alone is 96 scripts, and inflating them all up
                    // front would stall the screen for seconds.
                    itemBuilder: (context, index) =>
                        _LessonPassages(slug: slug, lesson: lessons[index]),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LessonPassages extends ConsumerWidget {
  const _LessonPassages({required this.slug, required this.lesson});

  final String slug;
  final LessonWithProgress lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textAsync = ref.watch(lessonTextProvider(lesson.videoId));
    final text = textAsync.value;
    if (text == null) return const SizedBox.shrink();

    final passages = _passagesOf(text);
    if (passages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 6),
          child: Text(
            'الدرس ${arabicDigits(lesson.position)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final passage in passages)
          _PassageRow(
            passage: passage,
            onTap: () => context.push(
              '/player/${lesson.videoId}?series=$slug&t=${passage.startSeconds}',
            ),
          ),
      ],
    );
  }

  /// The book's own words, separated from the explanation.
  ///
  /// On a matn script the sections *are* the book, so the passage is the
  /// section's text. On a transcript the sentences are the sheikh speaking and
  /// only the section title is the matn — taking the sentences there would
  /// reprint the lecture as if it were the book.
  List<_Passage> _passagesOf(LessonText text) {
    final passages = <_Passage>[];
    for (final section in text.sections) {
      final start = section.start;
      if (start == null) continue;
      final title = section.title.trim();
      if (text.kind == LessonTextKind.matn) {
        final body = section.sentences.map((s) => s.text).join(' ').trim();
        if (body.isEmpty && title.isEmpty) continue;
        passages.add(
          _Passage(
            heading: title.isEmpty ? null : title,
            body: body,
            startSeconds: start,
          ),
        );
      } else {
        if (title.isEmpty) continue;
        passages.add(_Passage(heading: null, body: title, startSeconds: start));
      }
    }
    return passages;
  }
}

class _Passage {
  const _Passage({
    required this.heading,
    required this.body,
    required this.startSeconds,
  });

  final String? heading;
  final String body;
  final int startSeconds;
}

class _PassageRow extends StatelessWidget {
  const _PassageRow({required this.passage, required this.onTap});

  final _Passage passage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (passage.heading != null) ...[
              Text(
                passage.heading!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 13.5,
                  color: scheme.primary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (passage.body.isNotEmpty)
              Text(
                passage.body,
                style: serif(16, scheme.onSurface, height: 1.95),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.play_circle_outline, size: 13, color: masar.textFaint),
                const SizedBox(width: 5),
                Text(
                  clockLabelLtr(Duration(seconds: passage.startSeconds)),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: kMonoFont,
                    fontSize: 10.5,
                    color: masar.textFaint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
