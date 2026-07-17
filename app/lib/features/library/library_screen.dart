import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/science_glyph.dart';
import '../../core/widgets/skeleton.dart';
import 'library_providers.dart';

/// المكتبة — the "browse everything" escape hatch, per the design:
/// sciences grid with Amiri glyphs + counts, offline note banner.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final sciencesAsync = ref.watch(sciencesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: sciencesAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const [Skeleton(height: 300, width: double.infinity)],
          ),
          error: (error, stack) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'تعذر تحميل المكتبة',
          ),
          data: (sciences) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المكتبة',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'البحث',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push('/search'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: masar.chipBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: masar.chipBorder),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: masar.chipText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'تصفّح جميع سلاسل الشيخ رحمه الله بحسب العلم — دون التقيد بمسار',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  for (final science in sciences)
                    Card(
                      child: InkWell(
                        onTap: science.seriesCount == 0
                            ? null
                            : () => context.push('/science/${science.slug}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScienceGlyph(
                                nameAr: science.nameAr,
                                sortOrder: science.sortOrder,
                                size: 44,
                              ),
                              const Spacer(),
                              Text(
                                science.nameAr,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                science.seriesCount == 0
                                    ? 'قريبًا'
                                    : '${seriesCountLabel(science.seriesCount)} · ${lessonCountLabel(science.lessonCount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Phase 2–3 sections, shipped as previews ─────────────
              Text('أقسام قادمة', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (index, entry) in const [
                      (Icons.question_answer_outlined, 'الفتاوى', '/fatawa'),
                      (Icons.menu_book_outlined, 'المتون', '/soon/matn'),
                      (
                        Icons.bookmark_border_rounded,
                        'ملاحظاتي',
                        '/soon/notes',
                      ),
                    ].indexed)
                      InkWell(
                        onTap: () => context.push(entry.$3),
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: index == 2
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: scheme.outlineVariant.withAlpha(
                                        0x80,
                                      ),
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Icon(entry.$1, size: 20, color: scheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.$2,
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
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.banner),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.download_done_rounded,
                      size: 17,
                      color: masar.chipText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الفهرس كامل متاح دون اتصال — التشغيل يتطلب اتصالًا بالإنترنت',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: masar.chipText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
