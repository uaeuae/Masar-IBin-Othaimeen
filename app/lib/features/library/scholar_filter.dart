import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/scholar_avatar.dart';
import '../../data/view_models.dart';
import 'library_providers.dart';

/// The library's scholar filter — «كل الشيوخ» plus one chip per scholar,
/// design 3a.
///
/// Renders nothing until a second scholar actually has series; see
/// [scholarFilterVisibleProvider]. Horizontally scrolled rather than wrapped
/// because `name_ar` is the full name («الشيخ محمد بن صالح العثيمين»): the
/// design draws the شهرة on these chips, but that is curated data the catalog
/// does not carry, and shortening a scholar's name in view code is the kind of
/// guess this app keeps out of attribution.
class ScholarFilterChips extends ConsumerWidget {
  const ScholarFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(scholarFilterVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final scholars = ref.watch(filterableScholarsProvider);
    final selected = ref.watch(activeScholarFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            MasarChip(
              label: 'كل الشيوخ',
              selected: selected == null,
              onTap: () => ref.read(scholarFilterProvider.notifier).set(null),
            ),
            for (final scholar in scholars) ...[
              const SizedBox(width: 8),
              MasarChip(
                label: scholar.displayShortName,
                selected: selected == scholar.slug,
                onTap: () =>
                    ref.read(scholarFilterProvider.notifier).set(scholar.slug),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The search screen's «الشيخ:» row, design 4e — a pill per scholar, the
/// selected one removable.
///
/// The × is the design's own affordance and worth keeping: on search, unlike
/// the library, there is no «كل الشيوخ» chip to return to.
class ScholarFilterBar extends ConsumerWidget {
  const ScholarFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(scholarFilterVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final scholars = ref.watch(filterableScholarsProvider);
    final selected = ref.watch(activeScholarFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            'الشيخ:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: masar.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final scholar in scholars) ...[
                    ScholarFilterPill(
                      scholar: scholar,
                      selected: selected == scholar.slug,
                    ),
                    if (scholar != scholars.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The active filter shown where there is no chip row to show it — a science's
/// series list, which honours the filter but is not where it gets set.
///
/// Without it the list would quietly be missing series, with nothing on screen
/// to say why.
class ActiveScholarFilterChip extends ConsumerWidget {
  const ActiveScholarFilterChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = ref.watch(activeScholarFilterProvider);
    final scholar = slug == null
        ? null
        : ref
              .watch(filterableScholarsProvider)
              .where((s) => s.slug == slug)
              .firstOrNull;
    if (scholar == null) return const SizedBox.shrink();
    return ScholarFilterPill(scholar: scholar, selected: true);
  }
}

/// Roundel + name pill; selected it tints and grows an × that clears the
/// filter (design 4e).
class ScholarFilterPill extends ConsumerWidget {
  const ScholarFilterPill({
    super.key,
    required this.scholar,
    required this.selected,
  });

  final ScholarInfo scholar;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final masar = masarColorsOf(context);
    final fg = selected ? scheme.onPrimaryContainer : masar.chipText;

    return Semantics(
      button: true,
      label: selected
          ? 'إزالة تصفية ${scholar.nameAr}'
          : 'التصفية بدروس ${scholar.nameAr}',
      child: GestureDetector(
        onTap: () => ref
            .read(scholarFilterProvider.notifier)
            .set(selected ? null : scholar.slug),
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(12, 5, selected ? 10 : 12, 5),
          // Bounded so a pill can never run off the row — `name_ar` is the
          // full name, and the × has to stay reachable at the end of it.
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : masar.chipBg,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? masar.greenTintBorder : masar.chipBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScholarAvatar.of(scholar, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  scholar.displayShortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kUiFont,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.close_rounded, size: 13, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
