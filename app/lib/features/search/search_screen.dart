import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';

/// Unified search per design 1m: one query over the catalog, grouped results
/// with highlighted matches. Lessons and series search for real; the فتاوى
/// and كتب scopes are Phase 3 and show a coming-soon state.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum _Scope { all, lessons, fatawa, books }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _Scope _scope = _Scope.all;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Query field + cancel ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.primary, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _onChanged,
                              textInputAction: TextInputAction.search,
                              style: theme.textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'ابحث في الدروس والسلاسل…',
                                contentPadding: EdgeInsetsDirectional.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: kUiFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Scope chips ──────────────────────────────────────────
              Row(
                children: [
                  for (final (scope, label) in const [
                    (_Scope.all, 'الكل'),
                    (_Scope.lessons, 'دروس'),
                    (_Scope.fatawa, 'فتاوى'),
                    (_Scope.books, 'كتب'),
                  ]) ...[
                    GestureDetector(
                      onTap: () => setState(() => _scope = scope),
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _scope == scope
                              ? scheme.primary
                              : masar.chipBg,
                          borderRadius: BorderRadius.circular(99),
                          border: _scope == scope
                              ? null
                              : Border.all(color: masar.chipBorder),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: kUiFont,
                            fontSize: 12,
                            fontWeight: _scope == scope
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _scope == scope
                                ? scheme.onPrimary
                                : masar.chipText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              Expanded(child: _buildResults(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_scope == _Scope.fatawa || _scope == _Scope.books) {
      return EmptyState(
        icon: _scope == _Scope.fatawa
            ? Icons.question_answer_outlined
            : Icons.menu_book_outlined,
        title: 'قريبًا إن شاء الله',
        message: _scope == _Scope.fatawa
            ? 'البحث في فتاوى الشيخ يصل ضمن تحديث قادم.'
            : 'البحث في المتون والكتب يصل ضمن تحديث قادم.',
      );
    }
    if (_query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'ابحث في مكتبة الشيخ',
        message: 'اكتب اسم كتاب أو بابًا أو كلمة من عنوان درس.',
      );
    }
    return FutureBuilder<CatalogSearchResults>(
      // Keyed so a new query triggers a fresh future.
      key: ValueKey(_query),
      future: ref.read(catalogRepositoryProvider).search(_query),
      builder: (context, snapshot) {
        final results = snapshot.data;
        if (results == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'لا نتائج',
            message: 'جرّب كلمة أخرى أو أقصر.',
          );
        }
        final showSeries = _scope == _Scope.all && results.series.isNotEmpty;
        return ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          children: [
            if (showSeries) ...[
              _GroupLabel('سلاسل · ${arabicDigits(results.series.length)}'),
              for (final hit in results.series)
                _ResultCard(
                  onTap: () => context.push('/series/${hit.slug}'),
                  title: _highlight(context, hit.titleAr, serif: true),
                  subtitle:
                      '${lessonCountLabel(hit.lessonCount)}'
                      '${hit.media == LessonMedia.audio ? ' · صوتيات المؤسسة' : ''}',
                ),
              const SizedBox(height: 10),
            ],
            if (results.lessons.isNotEmpty) ...[
              _GroupLabel('دروس · ${arabicDigits(results.lessons.length)}'),
              for (final hit in results.lessons)
                _ResultCard(
                  onTap: () => context.push(
                    '/player/${hit.videoId}?series=${hit.seriesSlug}',
                  ),
                  title: _highlight(context, hit.titleAr),
                  subtitle: [
                    hit.seriesTitleAr,
                    'الدرس ${arabicDigits(hit.position)}',
                    if (hit.durationSeconds != null)
                      clockLabel(Duration(seconds: hit.durationSeconds!)),
                  ].join(' · '),
                ),
            ] else if (!showSeries)
              const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'لا دروس مطابقة',
                message: 'جرّب كلمة أخرى.',
              ),
          ],
        );
      },
    );
  }

  /// Title with the matched substring softly highlighted, per the design.
  Widget _highlight(BuildContext context, String text, {bool serif = false}) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final base = serif
        ? TextStyle(
            fontFamily: kSerifFont,
            fontSize: 15.5,
            color: theme.colorScheme.onSurface,
            height: 1.6,
          )
        : theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.5,
          );
    final query = _query.trim();
    final index = query.isEmpty ? -1 : text.indexOf(query);
    if (index < 0) return Text(text, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: masar.goldTintBg,
              color: masar.goldTintFg,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final Widget title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 4),
              Text(
                subtitle,
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
    );
  }
}
