import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';
import '../settings/theme_mode_provider.dart';
import 'downloads_providers.dart';

/// «التنزيلات» — what's stored on the device, how much room it takes, and the
/// controls to change either.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    final allowMobile = ref.watch(allowMobileDataProvider);
    final itemsAsync = ref.watch(downloadedLessonsProvider);
    final bytesAsync = ref.watch(downloadedBytesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Text('التنزيلات', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bytesAsync.when(
                loading: () => '…',
                error: (_, _) => '',
                data: (bytes) => bytes == 0
                    ? 'لا توجد دروس منزّلة بعد.'
                    : 'يشغل ${byteLabel(bytes)} من مساحة الجهاز.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              // List tiles paint their ink on the nearest Material ancestor;
              // without one the decorated Container swallows the splash.
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: allowMobile,
                  onChanged: (v) =>
                      ref.read(allowMobileDataProvider.notifier).set(v),
                  title: Text(
                    'السماح بالتنزيل عبر بيانات الجوال',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'التنزيل مقتصر على Wi-Fi افتراضيًا — الدرس الواحد قد يتجاوز ٤٠ ميغابايت.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            itemsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذّر قراءة التنزيلات',
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return const EmptyState(
                    icon: Icons.download_outlined,
                    title: 'لا توجد تنزيلات',
                    message:
                        'نزّل أي درس صوتي من صفحة السلسلة للاستماع إليه دون اتصال.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final group in groups) ...[
                      _SeriesGroup(group: group),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _confirmClearAll(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: masar.textMuted,
                      ),
                      child: const Text('حذف جميع التنزيلات'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف جميع التنزيلات؟'),
        content: const Text(
          'ستُحذف كل الملفات الصوتية من الجهاز. لن يتأثر تقدّمك في الدروس.',
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
    if (confirmed != true || !context.mounted) return;
    await ref.read(downloadRepositoryProvider).removeAll();
  }
}

class _SeriesGroup extends ConsumerWidget {
  const _SeriesGroup({required this.group});

  final DownloadedSeries group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.seriesTitleAr,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${arabicDigits(group.lessons.length)} · ${byteLabel(group.bytes)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: masar.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            for (final (index, lesson) in group.lessons.indexed)
              Container(
                decoration: index == group.lessons.length - 1
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.dividerTheme.color!),
                        ),
                      ),
                child: ListTile(
                  dense: true,
                  onTap: () => context.push(
                    '/player/${lesson.videoId}?series=${group.seriesSlug}',
                  ),
                  title: Text(
                    'الدرس ${arabicDigits(lesson.position)} — ${lesson.titleAr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    tooltip: 'حذف',
                    iconSize: 17,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: masar.textMuted,
                    ),
                    onPressed: () => ref
                        .read(downloadRepositoryProvider)
                        .remove(lesson.videoId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
