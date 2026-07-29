import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/features/player/lesson_text.dart';
import 'package:masar/features/player/lesson_text_providers.dart';
import 'package:masar/features/player/lesson_text_view.dart';

import '../support/pump_app.dart';

/// Serves gzipped read-along scripts the way `assets/texts/` does in the app,
/// so the test exercises the real decode + parse path.
class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.scripts);

  final Map<String, Map<String, dynamic>> scripts;

  @override
  Future<ByteData> load(String key) async {
    final script = scripts[key];
    if (script == null) throw FlutterError('missing asset: $key');
    final bytes = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(script))),
    );
    return ByteData.view(bytes.buffer);
  }
}

/// fx-riyd-01: transcript — sentences carry estimated times.
final _transcript = {
  'lesson': 'fx-riyd-01',
  'kind': 'transcript',
  'duration': 2580,
  'sections': [
    {
      'start': 54,
      'title': 'مقدمة الباب',
      'sentences': [
        {'t': 54, 's': 'الجملة الأولى.'},
        {'t': 200, 's': 'الجملة الثانية.'},
      ],
    },
    {
      'start': 489,
      'title': 'الحديث الأول',
      'sentences': [
        {'t': 489, 's': 'الجملة الثالثة.'},
      ],
    },
  ],
};

/// fx-riyd-02: matn — no per-sentence times, only the section markers.
final _matn = {
  'lesson': 'fx-riyd-02',
  'kind': 'matn',
  'duration': 2400,
  'sections': [
    {
      'start': 30,
      'title': 'الباب الأول',
      'sentences': [
        {'s': 'المتن الأول.'},
        {'s': 'تتمة المتن الأول.'},
      ],
    },
    {
      'start': 600,
      'title': 'الباب الثاني',
      'sentences': [
        {'s': 'المتن الثاني.'},
      ],
    },
  ],
};

List<Override> _bundleOverride() {
  final bundle = _TextBundle({
    'assets/texts/fx-riyd-01.json.gz': _transcript,
    'assets/texts/fx-riyd-02.json.gz': _matn,
  });
  return [
    lessonTextRepositoryProvider.overrideWithValue(
      LessonTextRepository(bundle: bundle),
    ),
  ];
}

void main() {
  Future<void> openLesson(WidgetTester tester, String id) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/player/$id?series=sharh-riyad-alsalihin');
    await tester.pumpAndSettle();
  }

  /// Opens the lesson, turns the text on, and scrolls the panel back into
  /// view — ensuring the toggle visible pushes the panel off the top, since
  /// the toggle sits below it in the player's outer list.
  Future<void> openText(WidgetTester tester, String id) async {
    await openLesson(tester, id);
    await tapVisible(tester, find.text('النص'));
    await tester.scrollUntilVisible(
      find.byType(LessonTextView),
      -120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('LessonText', () {
    test('indexAt walks transcript sentences by their estimated times', () {
      final text = LessonText.fromJson(_transcript);
      expect(text.indexAt(const Duration(seconds: 10)), -1);
      expect(text.indexAt(const Duration(seconds: 54)), 0);
      expect(text.indexAt(const Duration(seconds: 199)), 0);
      expect(text.indexAt(const Duration(seconds: 200)), 1);
      expect(text.indexAt(const Duration(seconds: 489)), 2);
      expect(text.indexAt(const Duration(seconds: 3000)), 2);
    });

    test('matn sentences fall back to their section marker', () {
      final text = LessonText.fromJson(_matn);
      // Both sentences of section one share its 30s marker, so the index sits
      // on the last of them until the next marker lands.
      expect(text.indexAt(const Duration(seconds: 29)), -1);
      expect(text.indexAt(const Duration(seconds: 120)), 1);
      expect(text.sectionOf(text.indexAt(const Duration(seconds: 120))), 0);
      expect(text.sectionOf(text.indexAt(const Duration(seconds: 700))), 1);
    });
  });

  testApp(
    'the text toggle reveals the lesson text',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openLesson(tester, 'fx-riyd-01');
      expect(find.text('الجملة الأولى.'), findsNothing);

      await tapVisible(tester, find.text('النص'));

      expect(find.text('الجملة الأولى.'), findsOneWidget);
      expect(find.text('مزامنة تقريبية · المس جملة للانتقال'), findsOneWidget);
    },
  );

  testApp(
    'the highlight advances with the playback position',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openText(tester, 'fx-riyd-01');

      Color? backgroundOf(String sentence) {
        final container = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.text(sentence),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return (container.decoration as BoxDecoration?)?.color;
      }

      app.audioEngine.positionsController.add(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(backgroundOf('الجملة الأولى.'), isNot(Colors.transparent));
      expect(backgroundOf('الجملة الثانية.'), Colors.transparent);

      app.audioEngine.positionsController.add(const Duration(seconds: 250));
      await tester.pumpAndSettle();
      expect(backgroundOf('الجملة الأولى.'), Colors.transparent);
      expect(backgroundOf('الجملة الثانية.'), isNot(Colors.transparent));
    },
  );

  testApp(
    'tapping a sentence seeks to its timestamp',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openText(tester, 'fx-riyd-01');

      await tapVisible(tester, find.text('الجملة الثالثة.'));
      expect(app.audioEngine.seeks, contains(const Duration(seconds: 489)));
    },
  );

  testApp(
    'long-press re-anchors the estimate to where playback actually is',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openText(tester, 'fx-riyd-01');

      // Playing at 0:60, where the estimate says sentence one — but the reader
      // is hearing sentence three, so they long-press it.
      app.audioEngine.positionsController.add(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('الجملة الثالثة.'));
      await tester.pumpAndSettle();

      expect(find.text('تمت المزامنة من هذا الموضع'), findsOneWidget);
      // Re-anchored, not seeked: the audio keeps playing where it was.
      expect(app.audioEngine.seeks, isEmpty);

      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('الجملة الثالثة.'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(
        (container.decoration as BoxDecoration?)?.color,
        isNot(Colors.transparent),
      );
    },
  );

  testApp(
    'matn lessons highlight the whole passage and say so',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openText(tester, 'fx-riyd-02');

      expect(find.text('نص المتن'), findsOneWidget);
      expect(find.text('مزامنة تقريبية · المس جملة للانتقال'), findsNothing);

      app.audioEngine.positionsController.add(const Duration(seconds: 120));
      await tester.pumpAndSettle();

      Color? backgroundOf(String sentence) {
        final container = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.text(sentence),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return (container.decoration as BoxDecoration?)?.color;
      }

      // Both sentences of the current passage light up, the next one doesn't.
      expect(backgroundOf('المتن الأول.'), isNot(Colors.transparent));
      expect(backgroundOf('تتمة المتن الأول.'), isNot(Colors.transparent));
      expect(backgroundOf('المتن الثاني.'), Colors.transparent);
    },
  );

  testApp('lessons with no text never offer the toggle', (tester, app) async {
    // fx-riyd-03 carries no text_kind in the fixture catalog.
    await openLesson(tester, 'fx-riyd-03');
    expect(find.text('النص'), findsNothing);
  });
}
