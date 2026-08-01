import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/widgets/scholar_avatar.dart';
import 'package:masar/data/models/enums.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/pump_app.dart';

/// The app carries several scholars' teaching and is named for none of them.
/// These tests hold that line: every lesson says whose it is, browsing by
/// scholar is a real axis, and no screen speaks of «الشيخ» or «المؤسسة» as
/// though there were only one.
void main() {
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
  }

  /// Resolved off the root Navigator rather than a home-screen widget, so it
  /// still works once a pushed route covers the home screen.
  Future<void> push(WidgetTester tester, String location) async {
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).push(location);
    await tester.pumpAndSettle();
  }

  testApp('the roundel carries the curated letter, not the name\'s first', (
    tester,
    app,
  ) async {
    await openLibrary(tester);

    // «الشيخ محمد بن صالح العثيمين» starts with ا; his mark is ع, from the
    // شهرة. Deriving it from the name would print ا for both scholars.
    expect(find.text('ع'), findsWidgets);
    expect(find.text('ب'), findsWidgets);

    final avatar = tester
        .widgetList<ScholarAvatar>(find.byType(ScholarAvatar))
        .firstWhere((a) => a.initialAr == 'ب');
    expect(avatar.accent, ScholarAccent.blue);
  });

  testApp('the library browses by scholar, and says which are not here yet', (
    tester,
    app,
  ) async {
    await openLibrary(tester);

    expect(find.text('المشايخ'), findsWidgets);
    expect(find.text('الشيخ محمد بن صالح العثيمين'), findsWidgets);
    expect(find.text('الشيخ عبد العزيز بن عبد الله بن باز'), findsWidgets);
    // Announced, not hidden — one card says «قريبًا», the other a real count.
    expect(find.text('قريبًا'), findsWidgets);
  });

  testApp('an announced scholar opens a page that says so, not an empty list', (
    tester,
    app,
  ) async {
    await push(tester, '/scholar/al-fawzan');

    expect(find.text('الشيخ صالح الفوزان'), findsWidgets);
    expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    expect(find.textContaining('لم تُضف بعد'), findsOneWidget);
    // His own foundation, not the app's — this is why the credit cannot be
    // a single line in app chrome.
    expect(
      find.textContaining('موقع الشيخ صالح الفوزان'),
      findsOneWidget,
    );
  });

  testApp('a scholar with lessons gets his series and his totals', (
    tester,
    app,
  ) async {
    await push(tester, '/scholar/ibn-uthaymeen');

    expect(find.text('الشيخ محمد بن صالح العثيمين'), findsWidgets);
    expect(find.text('رحمه الله'), findsOneWidget);
    expect(find.textContaining('شرح زاد المستقنع'), findsWidgets);
    expect(find.text('قريبًا إن شاء الله'), findsNothing);

    // The permission line sits below his series.
    await tester.scrollUntilVisible(
      find.textContaining('جميع المواد بإذن'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('مؤسسة الشيخ محمد بن صالح العثيمين الخيرية'),
      findsOneWidget,
    );
  });

  testApp('a series card names who taught it', (tester, app) async {
    await push(tester, '/science/aqeedah');

    expect(find.text('الشيخ محمد بن صالح العثيمين رحمه الله'), findsWidgets);
    expect(find.byType(ScholarAvatar), findsWidgets);
  });

  testApp('the resume card names who taught it', (tester, app) async {
    await ProgressRepository(app.db).saveWatchPosition(
      videoId: 'fx-riyd-01',
      watchedSeconds: 400,
      durationSeconds: 2580,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ابن عثيمين'), findsWidgets);
    expect(find.byType(ScholarAvatar), findsWidgets);
  });

  testApp('settings credits every source, not one foundation', (
    tester,
    app,
  ) async {
    await push(tester, '/settings');
    // Settings grew a report row, so the sources list sits below the fold.
    await tester.scrollUntilVisible(
      find.text('مؤسسة الشيخ محمد بن صالح العثيمين الخيرية'),
      300,
    );

    expect(find.text('المصادر والإسناد'), findsOneWidget);
    expect(
      find.text('مؤسسة الشيخ محمد بن صالح العثيمين الخيرية'),
      findsOneWidget,
    );
    expect(find.text('مؤسسة الشيخ عبد العزيز بن باز الخيرية'), findsOneWidget);
    expect(find.textContaining('binothaimeen.net'), findsOneWidget);
  });

  testApp('journey cards say whose شرح they are', (tester, app) async {
    await tester.tap(find.text('المسارات'));
    await tester.pumpAndSettle();

    // The fixture carries «مسار العقيدة» twice, once per scholar — which is
    // exactly why a card has to name whose شرح it is. Without attribution the
    // list shows two identical cards.
    expect(find.text('مسار العقيدة'), findsWidgets);
    expect(find.byType(ScholarAvatar), findsWidgets);
    expect(find.text('الشيخ محمد بن صالح العثيمين رحمه الله'), findsWidgets);
  });

  testApp('a journey mixing scholars names them all', (tester, app) async {
    await push(tester, '/journey/masar-mushtarak');

    // Derived from the stages' own series, so it cannot disagree with them.
    expect(find.textContaining('الشيخ محمد بن صالح العثيمين'), findsWidgets);
    expect(find.textContaining('الشيخ عبد العزيز'), findsWidgets);
  });

  testApp('a flat-transcript series offers no «نص الكتاب» dead end', (
    tester,
    app,
  ) async {
    // «نص الكتاب» is built from timed passage markers. A source that publishes
    // a flat transcript has none, so the button would open an empty screen.
    await push(tester, '/series/baz-sharh-kitab-altawhid');
    expect(find.text('عن الكتاب'), findsOneWidget);
    expect(find.text('عرض نص الكتاب'), findsNothing);
  });


  testApp('home shows the scholars strip and the resume line names the شهرة', (
    tester,
    app,
  ) async {
    await ProgressRepository(app.db).saveWatchPosition(
      videoId: 'fx-riyd-01',
      watchedSeconds: 400,
      durationSeconds: 2580,
    );
    await tester.pumpAndSettle();

    // Design 4a folds attribution into the lesson line — «ابن عثيمين · الدرس
    // ١٢ — …». It only fits with the curated شهرة; the full name ellipsized
    // the lesson away, which is what the short_name_ar seed field is for.
    expect(find.textContaining('ابن عثيمين · الدرس'), findsOneWidget);

    expect(find.text('المشايخ'), findsWidgets);
    expect(find.text('ابن باز'), findsWidgets);
    expect(find.text('المزيد'), findsOneWidget);
  });

  testApp('a scholar with no curated short name still renders', (
    tester,
    app,
  ) async {
    // displayShortName falls back to the full name rather than deriving one —
    // guessing at an attribution is the one thing this project does not do.
    final scholars = await app.db.select(app.db.scholars).get();
    expect(scholars.every((s) => s.nameAr.isNotEmpty), isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testApp('no screen credits a single unnamed «المؤسسة»', (tester, app) async {
    // The old copy said «صوتيات المؤسسة» / «قناة الشيخ الرسمية» — a definite
    // singular that silently meant whichever one the reader assumed.
    List<String> offenders() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s.contains('المؤسسة') || s.contains('الشيخ رحمه الله'))
        .toList();

    await openLibrary(tester);
    expect(offenders(), isEmpty, reason: 'library');

    for (final location in ['/settings', '/series/sharh-zad-almustaqni']) {
      await push(tester, location);
      expect(offenders(), isEmpty, reason: location);
    }
  });
}
