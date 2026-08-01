import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/progress_repository.dart';
import 'package:masar/features/player/lesson_text.dart';
import 'package:masar/features/player/lesson_text_providers.dart';
import 'package:masar/features/player/lesson_text_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// A full-length script: 60 sentences over 40 minutes, so a resumed position
/// lands far enough down that the row is not built until something scrolls to
/// it. The three-sentence fixture above cannot show this — every row fits on
/// screen, so a highlight that never scrolls still looks correct.
///
/// The opening sentences are deliberately **short** and the rest long, which is
/// what a lesson actually sounds like: it starts with البسملة and a greeting
/// before any real exposition. That shape is what breaks a blind jump — a
/// `ListView` derives `maxScrollExtent` from the children it has laid out, so
/// while only the short opening rows exist the extent is a large underestimate,
/// and a jump computed from it lands nowhere near the target.
final _longTranscript = {
  'lesson': 'fx-riyd-01',
  'kind': 'transcript',
  'duration': 2580,
  'measured': 60,
  'sections': [
    {
      'start': 0,
      'title': 'الدرس',
      'sentences': [
        for (var i = 0; i < 60; i++)
          {
            't': i * 40,
            's': i < 10
                ? 'الجملة رقم $i.'
                : 'الجملة رقم $i، ${List.filled(40, 'وكلمة').join(' ')}.',
          },
      ],
    },
  ],
};

List<Override> _bundleOverride({bool long = false}) {
  final bundle = _TextBundle({
    'assets/texts/fx-riyd-01.json.gz': long ? _longTranscript : _transcript,
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

  /// Opens the lesson with the text panel already showing — it is on by
  /// default now — and makes sure the panel is in view before interacting.
  Future<void> openText(WidgetTester tester, String id) async {
    await openLesson(tester, id);
    await tester.ensureVisible(find.byType(LessonTextView));
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
    'the lesson text is showing from the moment the player opens',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openLesson(tester, 'fx-riyd-01');

      expect(find.text('الجملة الأولى.'), findsOneWidget);
      expect(find.text('مزامنة تقريبية · المس جملة للانتقال'), findsOneWidget);
    },
  );

  testApp(
    'the toggle hides the text, and the choice sticks',
    overrides: _bundleOverride(),
    (tester, app) async {
      await openLesson(tester, 'fx-riyd-01');
      expect(find.text('الجملة الأولى.'), findsOneWidget);

      await tapVisible(tester, find.text('النص'));
      expect(find.text('الجملة الأولى.'), findsNothing);

      // Persisted, so reopening the player keeps it hidden.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('show_lesson_text'), isFalse);

      await tapVisible(tester, find.text('النص'));
      expect(find.text('الجملة الأولى.'), findsOneWidget);
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

  testApp(
    'reopening a lesson lands the text on where playback resumes',
    overrides: _bundleOverride(long: true),
    seed: (db) async {
      // Where the reader stopped before closing the app. Sentence 40 starts at
      // 1600s, forty minutes into a script whose first row is what the panel
      // opens on.
      await ProgressRepository(db).saveWatchPosition(
        videoId: 'fx-riyd-01',
        watchedSeconds: 1600,
        durationSeconds: 2580,
      );
    },
    (tester, app) async {
      await openText(tester, 'fx-riyd-01');

      final resumed = find.textContaining('الجملة رقم 40،');
      // The panel is a lazy list, so a row that was never scrolled to is not
      // built at all — finding it *is* the assertion that the view moved.
      expect(
        resumed,
        findsOneWidget,
        reason: 'the resumed sentence should be on screen, not 40 minutes up',
      );
      final container = tester.widget<AnimatedContainer>(
        find
            .ancestor(of: resumed, matching: find.byType(AnimatedContainer))
            .first,
      );
      expect(
        (container.decoration as BoxDecoration?)?.color,
        isNot(Colors.transparent),
        reason: 'and highlighted, without waiting for the next sentence',
      );
    },
  );

  testApp(
    'the load reporting 0:00 does not drag the text back to the top',
    overrides: _bundleOverride(long: true),
    seed: (db) async {
      await ProgressRepository(db).saveWatchPosition(
        videoId: 'fx-riyd-01',
        watchedSeconds: 1600,
        durationSeconds: 2580,
      );
    },
    (tester, app) async {
      await openText(tester, 'fx-riyd-01');
      final resumed = find.textContaining('الجملة رقم 40،');
      expect(resumed, findsOneWidget);

      // just_audio feeds its position stream from every player event, and the
      // events raised while a source loads still carry the position the player
      // had before it — zero on the fresh engine a cold start creates. This is
      // that echo. Believing it snapped the timer to 0:00 and sent the panel
      // back to the top of the script.
      app.audioEngine.positionsController.add(Duration.zero);
      await tester.pumpAndSettle();
      expect(resumed, findsOneWidget);
      expect(find.textContaining('الجملة رقم 0.'), findsNothing);

      // Once the engine really is where it was asked to start, reports count
      // again — including ones behind the start, which by then are the reader
      // rewinding.
      app.audioEngine.positionsController.add(const Duration(seconds: 1600));
      app.audioEngine.positionsController.add(const Duration(seconds: 40));
      await tester.pumpAndSettle();
      expect(find.textContaining('الجملة رقم 1.'), findsOneWidget);
    },
  );

  testApp('a lesson with no text says so instead of hiding the control', (
    tester,
    app,
  ) async {
    // fx-riyd-03 carries no text_kind in the fixture catalog. The control used
    // to vanish, which read as a broken player rather than as an absent
    // transcript.
    await openLesson(tester, 'fx-riyd-03');

    expect(find.text('النص'), findsOneWidget);
    expect(find.text('لا يوجد نص لهذا الدرس'), findsOneWidget);
    expect(
      find.text('لم يُنشر تفريغ نصي له في مصدره. الصوت يعمل كالمعتاد.'),
      findsOneWidget,
    );
  });
}
