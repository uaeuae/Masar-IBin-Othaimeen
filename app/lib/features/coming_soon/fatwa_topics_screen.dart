import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/back_circle.dart';

/// الفتاوى hub per design 1k — the topic taxonomy is real, the content is
/// Phase 3, so every row is marked قريبًا and nothing pretends to be live.
class FatwaTopicsScreen extends StatelessWidget {
  const FatwaTopicsScreen({super.key});

  static const _collections = ['نور على الدرب', 'اللقاء الشهري', 'لقاء الباب المفتوح'];

  static const _topics = [
    ('ط', 'الطهارة'),
    ('ص', 'الصلاة'),
    ('ز', 'الزكاة'),
    ('م', 'الصيام'),
    ('ج', 'الحج والعمرة'),
    ('ب', 'البيوع والمعاملات'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

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
                Text('الفتاوى', style: theme.textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 16),

            // ── Collection chips (preview, disabled) ─────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, name) in _collections.indexed)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 15,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: index == 0 ? scheme.primary : masar.chipBg,
                      borderRadius: BorderRadius.circular(99),
                      border: index == 0
                          ? null
                          : Border.all(color: masar.chipBorder),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: kUiFont,
                        fontSize: 13,
                        fontWeight: index == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: index == 0 ? scheme.onPrimary : masar.chipText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Coming-soon banner ───────────────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: masar.goldTintBg,
                borderRadius: BorderRadius.circular(AppRadius.banner),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 17, color: masar.goldTintFg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'قريبًا إن شاء الله — فتاوى الشيخ مصنّفة حسب الأبواب، '
                      'مع الاستماع وقراءة النص',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: masar.goldTintFg,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Topic rows (preview) ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: scheme.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, topic) in _topics.indexed)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        border: index == _topics.length - 1
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: scheme.outlineVariant.withAlpha(0x80),
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(0x14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              topic.$1,
                              style: TextStyle(
                                fontFamily: kSerifFont,
                                fontSize: 18,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic.$2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'قريبًا',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
