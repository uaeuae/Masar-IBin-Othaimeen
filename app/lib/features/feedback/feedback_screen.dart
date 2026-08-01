import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/masar_chip.dart';
import '../../data/providers.dart';
import 'feedback_report.dart';

/// «الإبلاغ عن خطأ أو اقتراح».
///
/// Deliberately not a form that posts anywhere. The app has no backend and
/// tells the reader it collects nothing; a report therefore leaves through
/// their own mail app, with everything it contains shown on screen first. That
/// keeps the promise literally true rather than approximately.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({
    super.key,
    this.initialKind = ReportKind.wrongInfo,
    this.lessonId,
    this.lessonTitle,
    this.seriesTitle,
    this.scholarName,
    this.positionSeconds,
  });

  final ReportKind initialKind;
  final String? lessonId;
  final String? lessonTitle;
  final String? seriesTitle;
  final String? scholarName;
  final int? positionSeconds;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  late ReportKind _kind = widget.initialKind;
  final _controller = TextEditingController();
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ReportContext _context(int catalogVersion) => ReportContext(
    appVersion: kAppVersion,
    catalogVersion: catalogVersion,
    platform: kIsWeb
        ? 'web'
        : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    lessonId: widget.lessonId,
    lessonTitle: widget.lessonTitle,
    seriesTitle: widget.seriesTitle,
    scholarName: widget.scholarName,
    positionSeconds: widget.positionSeconds,
  );

  Future<void> _send(ReportContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    final launched = await launchUrl(
      reportMailto(_kind, context, message),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    // No mail app configured is a real case, and silently doing nothing would
    // read as the report having been sent.
    setState(() => _failed = !launched);
    if (launched) Navigator.of(this.context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final catalogVersion = ref.watch(catalogVersionProvider).value ?? 0;
    final reportContext = _context(catalogVersion);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الإبلاغ عن خطأ أو اقتراح',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'ما نوع البلاغ؟',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final kind in ReportKind.values) ...[
                    MasarChip(
                      label: kind.labelAr,
                      selected: _kind == kind,
                      onTap: () => setState(() => _kind = kind),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _controller,
              maxLines: 6,
              minLines: 4,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: _kind.hintAr,
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Shown, not hidden: the app tells the reader it collects nothing,
            // so anything travelling with the report has to be visible first.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سيُرفق مع رسالتك',
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  for (final (label, value) in reportContext.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '$label: $value',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: masar.textMuted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'يُفتح تطبيق البريد لديك، ولا يُرسل شيء حتى تضغط إرسال فيه. '
                    'التطبيق نفسه لا يرسل ولا يجمع أي بيانات.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: masar.textMuted,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _controller.text.trim().isEmpty
                    ? null
                    : () => _send(reportContext),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: const Text('فتح البريد للإرسال'),
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: 12),
              Text(
                'تعذّر فتح تطبيق البريد. يمكنك المراسلة مباشرة على '
                '$kFeedbackEmail',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
