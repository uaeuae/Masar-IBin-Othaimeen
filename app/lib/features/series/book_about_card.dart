import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/scholar_avatar.dart';
import '../../data/view_models.dart';

/// «عن الكتاب» — what this book is, who taught it, and how much of it there is,
/// shown before the reader taps a single lesson.
///
/// Everything here already existed in the catalog and was simply never
/// surfaced. Deliberately not a gate: a sheet that must be dismissed before
/// playing would sit between the reader and the audio every time they meet a
/// new book, which is a worse trade than one they might skip.
class BookAboutCard extends StatelessWidget {
  const BookAboutCard({
    super.key,
    required this.series,
    required this.scienceName,
    this.scholar,
    this.bookAuthorAr,
    required this.hasReadAlongText,
    this.onOpenBookText,
  });

  final SeriesWithProgress series;
  final String scienceName;

  /// Who taught it, and therefore which foundation holds the rights. Both are
  /// per-scholar, so neither can be a constant in the card.
  final ScholarInfo? scholar;

  /// Who wrote the matn. The sheikh explains books he mostly did not write, so
  /// «الشارح» and «المؤلف» are different people — and on the handful he did
  /// write, this is simply his own name.
  final String? bookAuthorAr;

  /// False when not one lesson in the series has a read-along script — the
  /// player would otherwise look broken on every single one.
  final bool hasReadAlongText;

  /// Opens «نص الكتاب». Null when no passage text exists to show.
  final VoidCallback? onOpenBookText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    final facts = [
      lessonCountLabel(series.lessonCount),
      if (series.totalDurationSeconds > 0)
        durationLabel(Duration(seconds: series.totalDurationSeconds)),
      if (scienceName.isNotEmpty) scienceName,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text('عن الكتاب', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (series.level != null)
                LevelBadge(level: series.level!, compact: true),
            ],
          ),
          if (series.descriptionAr != null &&
              series.descriptionAr!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              series.descriptionAr!,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.75),
            ),
          ],
          const SizedBox(height: 12),
          _Fact(icon: Icons.list_rounded, text: facts),
          if (bookAuthorAr != null) ...[
            const SizedBox(height: 6),
            _Fact(icon: Icons.edit_note_rounded, text: 'المؤلف: $bookAuthorAr'),
          ],
          if (scholar != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => context.push('/scholar/${scholar!.slug}'),
              child: Row(
                children: [
                  ScholarAvatar.of(scholar!, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الشارح: ${scholar!.nameAr}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: masar.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Fact(icon: Icons.verified_outlined, text: scholar!.foundationAr),
          ],
          const SizedBox(height: 6),
          _Fact(
            icon: hasReadAlongText
                ? Icons.subject_rounded
                : Icons.subject_outlined,
            text: hasReadAlongText
                ? 'يتوفر نص مقروء مع الصوت'
                : 'لا يتوفر نص مقروء لهذه السلسلة',
            muted: !hasReadAlongText,
          ),
          if (!hasReadAlongText) ...[
            const SizedBox(height: 4),
            Text(
              'لم يُنشر تفريغ نصي لهذه الدروس في مصدرها.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: masar.textFaint,
              ),
            ),
          ],
          if (onOpenBookText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenBookText,
                icon: const Icon(Icons.menu_book_outlined, size: 17),
                label: const Text('عرض نص الكتاب'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final color = muted ? masar.textFaint : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
