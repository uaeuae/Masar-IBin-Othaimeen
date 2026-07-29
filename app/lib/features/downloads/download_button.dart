import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/download_manager.dart';
import '../../data/download_repository.dart';
import '../../data/providers.dart';

/// The per-lesson download control: an arrow to fetch, a ring while fetching,
/// a check when it's on the device. Tapping a finished or in-flight download
/// asks first — a long re-download over a slow link is not something to
/// trigger with a stray thumb.
class DownloadButton extends ConsumerWidget {
  const DownloadButton({
    super.key,
    required this.videoId,
    required this.seriesSlug,
    required this.audioUrl,
    this.size = 30,
  });

  final String videoId;
  final String seriesSlug;
  final String? audioUrl;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = audioUrl;
    if (url == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final masar = masarColorsOf(context);
    final status = ref
        .watch(downloadsProvider)
        .value?[videoId];

    final icon = switch (status?.state) {
      DownloadState.done => Icon(
        Icons.download_done_rounded,
        size: 17,
        color: scheme.primary,
      ),
      DownloadState.failed => Icon(
        Icons.error_outline_rounded,
        size: 17,
        color: scheme.error,
      ),
      DownloadState.queued || DownloadState.downloading => SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: status?.progress,
          color: scheme.primary,
        ),
      ),
      null => Icon(
        Icons.download_outlined,
        size: 17,
        color: masar.textFaint,
      ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 17,
        tooltip: switch (status?.state) {
          DownloadState.done => 'حذف التنزيل',
          DownloadState.failed => 'إعادة المحاولة',
          DownloadState.queued ||
          DownloadState.downloading => 'إيقاف التنزيل',
          null => 'تنزيل للاستماع دون اتصال',
        },
        onPressed: () => _onPressed(context, ref, status, url),
        icon: icon,
      ),
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    WidgetRef ref,
    DownloadStatus? status,
    String url,
  ) async {
    final manager = ref.read(downloadManagerProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (status != null && status.isDone) {
      final confirmed = await _confirm(
        context,
        title: 'حذف التنزيل؟',
        message: 'سيُحذف الملف من الجهاز، ويبقى الدرس متاحًا عبر الإنترنت.',
        action: 'حذف',
      );
      if (confirmed) await ref.read(downloadRepositoryProvider).remove(videoId);
      return;
    }

    if (status != null && status.isActive) {
      await manager.cancel(videoId);
      return;
    }

    try {
      await manager.download(
        videoId: videoId,
        seriesSlug: seriesSlug,
        url: url,
      );
    } on DownloadBlockedException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.messageAr)));
    }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
