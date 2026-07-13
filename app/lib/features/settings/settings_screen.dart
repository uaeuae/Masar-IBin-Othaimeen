import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import 'theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final autoplay = ref.watch(autoplayProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _SectionLabel('المظهر'),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) ref.read(themeModeProvider.notifier).set(mode);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('تلقائي (حسب النظام)'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('فاتح'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('داكن'),
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionLabel('التشغيل'),
          SwitchListTile(
            value: autoplay,
            onChanged: (value) =>
                ref.read(autoplayProvider.notifier).set(value),
            title: const Text('الانتقال التلقائي للدرس التالي'),
            subtitle: const Text('عند انتهاء الدرس يُقترح التالي مباشرة'),
          ),
          const Divider(),
          _SectionLabel('عن التطبيق'),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Text(
              'تطبيق تعليمي مجاني غير ربحي، يجمع دروس فضيلة الشيخ محمد بن صالح العثيمين رحمه الله في مسارات منظمة لطالب العلم.\n\nجميع المواد العلمية من إنتاج ونشر مؤسسة الشيخ محمد بن صالح العثيمين الخيرية، وتُعرض المقاطع عبر مشغل يوتيوب الرسمي من قناة الشيخ.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('الموقع الرسمي للشيخ'),
            subtitle: const Text('binothaimeen.net'),
            onTap: () => launchUrl(
              Uri.parse('https://binothaimeen.net/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: const Text('قناة الشيخ الرسمية على يوتيوب'),
            subtitle: const Text('@ibnothaimeentv'),
            onTap: () => launchUrl(
              Uri.parse('https://www.youtube.com/@ibnothaimeentv'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
