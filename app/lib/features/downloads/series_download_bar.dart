import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/download_manager.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';

/// Series-level download control: one tap for the whole book, a live count
/// while it runs, and a way out of it.
class SeriesDownloadBar extends ConsumerWidget {
  const SeriesDownloadBar({
    super.key,
    required this.slug,
    required this.lessons,
  });

  final String slug;
  final List<LessonWithProgress> lessons;

  List<LessonWithProgress> get _downloadable => [
    for (final lesson in lessons)
      if (lesson.status == LessonStatus.active &&
          lesson.media == LessonMedia.audio &&
          lesson.audioUrl != null)
        lesson,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    final downloadable = _downloadable;
    if (downloadable.isEmpty) return const SizedBox.shrink();

    final statuses = ref.watch(downloadsProvider).value ?? const {};
    final mine = [
      for (final lesson in downloadable)
        if (statuses[lesson.videoId] != null) statuses[lesson.videoId]!,
    ];
    final done = mine.where((s) => s.isDone).length;
    final active = mine.where((s) => s.isActive).length;
    final all = downloadable.length;

    final label = active > 0
        ? 'جارٍ التنزيل — ${arabicDigits(done)} من ${arabicDigits(all)}'
        : done == 0
        ? 'تنزيل السلسلة للاستماع دون اتصال'
        : done >= all
        ? 'السلسلة كاملة على جهازك'
        : 'تنزيل الباقي — ${arabicDigits(all - done)} درسًا';

    final complete = done >= all && active == 0;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.banner),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.download_done_rounded
                : Icons.download_for_offline_outlined,
            size: 20,
            color: complete ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: complete ? scheme.primary : scheme.onSurface,
                  ),
                ),
                if (active > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: LinearProgressIndicator(
                      value: all == 0 ? null : done / all,
                      minHeight: 4,
                      backgroundColor: masar.highlightTrack,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (active > 0)
            TextButton(
              onPressed: () => _stop(ref, downloadable),
              child: const Text('إيقاف'),
            )
          else if (!complete)
            TextButton(
              onPressed: () => _start(context, ref, downloadable),
              child: const Text('تنزيل'),
            )
          else
            TextButton(
              onPressed: () => _deleteAll(context, ref, downloadable),
              child: const Text('حذف'),
            ),
        ],
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    List<LessonWithProgress> downloadable,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await ref
          .read(downloadManagerProvider)
          .downloadAll([
            for (final lesson in downloadable)
              (
                videoId: lesson.videoId,
                seriesSlug: slug,
                url: lesson.audioUrl!,
              ),
          ]);
      if (added > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('أُضيف ${arabicDigits(added)} درسًا إلى التنزيلات'),
          ),
        );
      }
    } on DownloadBlockedException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.messageAr)));
    }
  }

  Future<void> _stop(
    WidgetRef ref,
    List<LessonWithProgress> downloadable,
  ) async {
    final manager = ref.read(downloadManagerProvider);
    await manager.cancelAll();
    // Cancelling the queue leaves the rows behind; drop the ones that never
    // finished so the bar doesn't claim work that isn't happening.
    final statuses = ref.read(downloadsProvider).value ?? const {};
    for (final lesson in downloadable) {
      if (statuses[lesson.videoId]?.isActive ?? false) {
        await manager.cancel(lesson.videoId);
      }
    }
  }

  Future<void> _deleteAll(
    BuildContext context,
    WidgetRef ref,
    List<LessonWithProgress> downloadable,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف تنزيلات السلسلة؟'),
        content: const Text(
          'ستُحذف الملفات من الجهاز، وتبقى الدروس متاحة عبر الإنترنت.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repository = ref.read(downloadRepositoryProvider);
    for (final lesson in downloadable) {
      await repository.remove(lesson.videoId);
    }
  }
}
