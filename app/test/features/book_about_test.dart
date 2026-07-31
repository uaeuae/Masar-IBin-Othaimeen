import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/features/player/lesson_text.dart';
import 'package:masar/features/player/lesson_text_providers.dart';
import 'package:masar/features/series/book_about_card.dart';

import '../support/pump_app.dart';

/// Serves matn scripts the way `assets/texts/` does — the book text screen
/// builds the matn out of exactly these.
class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.scripts);

  final Map<String, Map<String, dynamic>> scripts;

  @override
  Future<ByteData> load(String key) async {
    final script = scripts[key];
    if (script == null) throw FlutterError('missing asset: $key');
    final bytes = gzip.encode(utf8.encode(jsonEncode(script)));
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

Map<String, dynamic> _matnScript(String lesson) => {
  'lesson': lesson,
  'kind': 'matn',
  'duration': 2580,
  'sections': [
    {
      'start': 54,
      'title': 'مقدمة الباب',
      'sentences': [
        {'s': 'قال الله تعالى: وما أمروا إلا ليعبدوا الله مخلصين له الدين.'},
      ],
    },
    {
      'start': 489,
      'title': 'الحديث الأول',
      'sentences': [
        {'s': 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى.'},
      ],
    },
  ],
};

List<Override> _bundleOverride() => [
  lessonTextRepositoryProvider.overrideWithValue(
    LessonTextRepository(
      bundle: _TextBundle({
        'assets/texts/fx-riyd-01.json.gz': _matnScript('fx-riyd-01'),
        'assets/texts/fx-riyd-02.json.gz': _matnScript('fx-riyd-02'),
      }),
    ),
  ),
];

/// «عن الكتاب» — the series screen should say what the book is before the
/// reader commits to a 90-minute lesson.
void main() {
  Future<void> openSeries(WidgetTester tester, String slug) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/series/$slug');
    await tester.pumpAndSettle();
  }

  testApp('the book card names the sheikh, the size, and the source', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-riyad-alsalihin');

    expect(find.byType(BookAboutCard), findsOneWidget);
    expect(find.text('عن الكتاب'), findsOneWidget);
    expect(find.text('الشارح: الشيخ محمد بن صالح العثيمين'), findsOneWidget);
    expect(find.textContaining('مؤسسة'), findsWidgets);
    expect(find.textContaining('دروس'), findsWidgets);
  });

  testApp('a series with no transcript says so up front', (tester, app) async {
    // sharh-thalathat-alusul carries no text_kind on any lesson in the fixture.
    await openSeries(tester, 'sharh-thalathat-alusul');

    expect(find.text('لا يتوفر نص مقروء لهذه السلسلة'), findsOneWidget);
    expect(
      find.text('المؤسسة لم تنشر تفريغًا نصيًا لهذه الدروس.'),
      findsOneWidget,
    );
  });

  testApp('a series that has a transcript says that instead', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-riyad-alsalihin');
    expect(find.text('يتوفر نص مقروء مع الصوت'), findsOneWidget);
    expect(find.text('لا يتوفر نص مقروء لهذه السلسلة'), findsNothing);
  });

  testApp('the matn author is named separately from the one explaining it', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-zad-almustaqni');

    // Distinct people: the sheikh teaches from a book he did not write.
    expect(find.text('المؤلف: الحجاوي'), findsOneWidget);
    expect(find.text('الشارح: الشيخ محمد بن صالح العثيمين'), findsOneWidget);
  });

  testApp('a series with no author named shows only the one explaining it', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-riyad-alsalihin');

    // Better silent than a guessed attribution.
    expect(find.textContaining('المؤلف:'), findsNothing);
    expect(find.text('الشارح: الشيخ محمد بن صالح العثيمين'), findsOneWidget);
  });

  testApp(
    'the book text opens from the card, and links back to the lesson',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openSeries(tester, 'sharh-riyad-alsalihin');
      await tapVisible(tester, find.text('عرض نص الكتاب'));

      expect(
        find.text('نص الكتاب — المس أي موضع للاستماع إلى شرحه'),
        findsOneWidget,
      );
      // The book's own words, not the explanation.
      expect(find.textContaining('مقدمة الباب'), findsWidgets);
      expect(find.textContaining('إنما الأعمال بالنيات'), findsWidgets);

      // Tapping a passage opens the lesson at the moment it is explained.
      // Every lesson in the fixture carries the same script, so the passage
      // appears once per lesson; the first is lesson one's.
      await tapVisible(tester, find.textContaining('إنما الأعمال بالنيات').first);
      expect(app.audioEngine.loads, isNotEmpty);
      expect(app.audioEngine.loads.last.$3, const Duration(seconds: 489));
    },
  );
}
