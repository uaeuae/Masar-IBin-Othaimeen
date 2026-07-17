import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/segmented_control.dart';
import '../../data/providers.dart';
import 'theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final themeMode = ref.watch(themeModeProvider);
    final autoplay = ref.watch(autoplayProvider);
    final reminder = ref.watch(dailyReminderProvider);

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
                Text('الإعدادات', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 18),

            // ── المظهر ────────────────────────────────────────────────
            Text(
              'المظهر',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedControl<ThemeMode>(
              segments: const {
                ThemeMode.light: 'فاتح',
                ThemeMode.dark: 'داكن',
                ThemeMode.system: 'تلقائي',
              },
              selected: themeMode,
              onChanged: (mode) =>
                  ref.read(themeModeProvider.notifier).set(mode),
            ),
            const SizedBox(height: 18),

            // ── Toggles ──────────────────────────────────────────────
            _GroupCard(
              children: [
                _ToggleRow(
                  title: 'التشغيل التلقائي للدرس التالي',
                  subtitle: 'ينتقل تلقائيًا بعد انتهاء الدرس',
                  value: autoplay,
                  onChanged: (v) => ref.read(autoplayProvider.notifier).set(v),
                ),
                _ToggleRow(
                  title: 'تذكير المتابعة اليومي',
                  subtitle: 'إشعار لطيف لمواصلة مسارك (قريبًا)',
                  value: reminder,
                  onChanged: (v) =>
                      ref.read(dailyReminderProvider.notifier).set(v),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Links ────────────────────────────────────────────────
            _GroupCard(
              children: [
                _LinkRow(
                  title: 'القناة الرسمية للشيخ',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.youtube.com/@ibnothaimeentv'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _LinkRow(
                  title: 'موقع المؤسسة',
                  onTap: () => launchUrl(
                    Uri.parse('https://binothaimeen.net/'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _LinkRow(
                  title: 'مسح بيانات التقدم',
                  showDivider: false,
                  onTap: () => _confirmWipe(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Attribution ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: masar.attributionBg,
                borderRadius: BorderRadius.circular(AppRadius.group),
                border: Border.all(color: masar.attributionBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جميع الدروس منسوبة بالكامل إلى',
                    style: serif(17, masar.attributionText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مؤسسة الشيخ محمد بن صالح العثيمين الخيرية',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق تطوعي غير ربحي — بلا حسابات، بلا إعلانات، بلا جمع بيانات. تقدمك محفوظ على جهازك فقط.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: masar.attributionText,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Masar v1.0.0',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: kMonoFont,
                  fontSize: 11,
                  color: masar.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح بيانات التقدم؟'),
        content: const Text(
          'سيُحذف سجل المشاهدة والالتحاق بالمسارات من هذا الجهاز نهائيًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.delete(db.lessonProgress).go();
    await db.delete(db.journeyEnrollments).go();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم مسح بيانات التقدم')));
    }
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.group),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerTheme.color!),
              ),
            )
          : null,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerTheme.color!),
                ),
              )
            : null,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: masar.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
