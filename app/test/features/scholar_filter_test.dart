import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/widgets/masar_chip.dart';
import 'package:masar/core/widgets/scholar_avatar.dart';
import 'package:masar/features/library/scholar_filter.dart';

import '../support/pump_app.dart';

/// The sheikh filter of design 3a/4e. It was deliberately withheld while one
/// scholar had all the content (DECISIONS 14) — so what these tests pin down
/// is as much *when* it appears as what it does.
///
/// Fixture shape it leans on: ابن عثيمين teaches العقيدة (٢), الفقه and
/// الحديث; ابن باز teaches one العقيدة series; الفوزان is announced with none.
void main() {
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
  }

  Future<void> openSearch(WidgetTester tester) async {
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).push('/search');
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();
  }

  /// A scholar's name is on screen twice over — as a chip and on his card —
  /// so the chip has to be picked out by widget, not by text.
  Finder chip(String label) =>
      find.descendant(of: find.byType(MasarChip), matching: find.text(label));

  Finder pill(String slug) => find.byWidgetPredicate(
    (w) => w is ScholarFilterPill && w.scholar.slug == slug,
  );

  // Chips and pills carry the curated شهرة, not the full name: «الشيخ محمد بن
  // صالح العثيمين» in a chip row ellipsizes to nothing useful. The full name
  // still goes to the screen-reader label, which has room for it.
  const uthaymeen = 'ابن عثيمين';
  const baz = 'ابن باز';
  const fawzan = 'الفوزان';
  const fawzanFull = 'الشيخ صالح الفوزان';
  const bazFull = 'الشيخ عبد العزيز بن عبد الله بن باز';

  testApp('filtering by a scholar narrows the library to his content', (
    tester,
    app,
  ) async {
    await openLibrary(tester);

    // Unfiltered, the grid spans everyone and العقيدة counts both scholars.
    expect(find.text('الفقه'), findsOneWidget);
    expect(find.text('الحديث'), findsOneWidget);
    expect(find.text('٣ سلاسل · شيخان · ١٦ درسًا'), findsOneWidget);

    await tapVisible(tester, chip(baz));

    // العقيدة is the only علم he teaches; the rest leave the grid rather than
    // sit there claiming «قريبًا» for content that already exists.
    expect(find.text('العقيدة'), findsOneWidget);
    expect(find.text('الفقه'), findsNothing);
    expect(find.text('الحديث'), findsNothing);
    // Counts narrow with the filter, and «شيخان» drops off with them.
    expect(find.text('سلسلة واحدة · ٣ دروس'), findsOneWidget);

    // The الشيوخ row narrows too: his card stays, the others go.
    expect(
      tester
          .widgetList<ScholarAvatar>(find.byType(ScholarAvatar))
          .where((a) => a.size == 52)
          .map((a) => a.initialAr),
      ['ب'],
    );

    await tapVisible(tester, chip('كل الشيوخ'));
    expect(find.text('الفقه'), findsOneWidget);
    expect(find.text('٣ سلاسل · شيخان · ١٦ درسًا'), findsOneWidget);
  });

  testApp('an announced scholar gets a card but no filter chip', (
    tester,
    app,
  ) async {
    await openLibrary(tester);

    // A coming_soon scholar has no series, so his chip could only ever empty
    // the screen. He is still announced — on his badged card in الشيوخ.
    expect(chip(fawzan), findsNothing);
    expect(find.text(fawzanFull), findsOneWidget);
    expect(chip(uthaymeen), findsOneWidget);
    expect(chip(baz), findsOneWidget);
  });

  testApp(
    'the filter stays hidden while only one scholar has series',
    (tester, app) async {
      await openLibrary(tester);

      // The trigger is a second scholar WITH content, not a second scholar:
      // ابن باز and الفوزان are both still listed here.
      expect(find.text('كل الشيوخ'), findsNothing);
      expect(find.byType(ScholarFilterPill), findsNothing);
      expect(find.text(bazFull), findsOneWidget);

      // …and nothing is being filtered behind the missing chips.
      expect(find.text('الفقه'), findsOneWidget);
      expect(find.text('الحديث'), findsOneWidget);

      await openSearch(tester);
      await type(tester, 'المسائل');
      expect(find.text('الشيخ:'), findsNothing);
    },
    seed: (db) async {
      await db.customStatement(
        "DELETE FROM lessons WHERE series_slug IN "
        "(SELECT slug FROM series WHERE scholar_slug = 'ibn-baz')",
      );
      await db.customStatement(
        "DELETE FROM series WHERE scholar_slug = 'ibn-baz'",
      );
    },
  );

  testApp('every search result carries its scholar', (tester, app) async {
    await openSearch(tester);
    // A title both scholars use — the case where an unattributed result would
    // be actively misleading.
    await type(tester, 'المسائل الأربع');

    expect(find.text('المسائل الأربع التي تجب معرفتها'), findsNWidgets(2));
    // ScholarLine is the result rows' attribution; the filter row above uses
    // pills, so this counts results only.
    expect(
      tester
          .widgetList<ScholarLine>(find.byType(ScholarLine))
          .map((l) => l.scholar.slug)
          .toSet(),
      {'ibn-uthaymeen', 'ibn-baz'},
    );
    expect(
      tester
          .widgetList<ScholarAvatar>(find.byType(ScholarAvatar))
          .where((a) => a.size == 18)
          .map((a) => a.initialAr),
      containsAll(['ع', 'ب']),
    );
  });

  testApp('the search filter narrows results to one scholar', (
    tester,
    app,
  ) async {
    await openSearch(tester);
    await type(tester, 'المسائل الأربع');
    expect(find.text('المسائل الأربع التي تجب معرفتها'), findsNWidgets(2));

    await tapVisible(tester, pill('ibn-baz'));
    expect(find.text('المسائل الأربع التي تجب معرفتها'), findsOneWidget);
    expect(
      tester
          .widgetList<ScholarLine>(find.byType(ScholarLine))
          .map((l) => l.scholar.slug),
      ['ibn-baz'],
    );

    // The × on the selected pill is the only way back — search has no
    // «كل الشيوخ» chip.
    await tapVisible(tester, pill('ibn-baz'));
    expect(find.text('المسائل الأربع التي تجب معرفتها'), findsNWidgets(2));
  });

  testApp('the filter fits a phone despite full-length scholar names', (
    tester,
    app,
  ) async {
    // The default 800×600 test surface hides overflow a 402pt iPhone would
    // show, and these pills carry «الشيخ محمد بن صالح العثيمين» in full — the
    // design's chips assume a شهرة the catalog does not carry.
    //
    // Search only. Both browse screens already overflow at this width without
    // any filter involved — المكتبة's sciences grid by 19px and a science's
    // sort-chip row by 30px — so they cannot be asserted on until that is
    // fixed, which is not this change's job.
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await openSearch(tester);
    await type(tester, 'المسائل الأربع');
    expect(find.byType(ScholarFilterPill), findsNWidgets(2));
    expect(find.byType(ScholarLine), findsNWidgets(2));

    await tapVisible(tester, pill('ibn-baz'));
    expect(find.text('المسائل الأربع التي تجب معرفتها'), findsOneWidget);
  });

  testApp('a filtered science list shows the filter it is obeying', (
    tester,
    app,
  ) async {
    await openLibrary(tester);
    await tapVisible(tester, chip(baz));
    await tapVisible(tester, find.text('العقيدة'));

    // Only his العقيدة series, and the pill says why the other two are gone.
    expect(find.text('شرح كتاب التوحيد'), findsOneWidget);
    expect(find.text('شرح ثلاثة الأصول'), findsNothing);
    expect(pill('ibn-baz'), findsOneWidget);

    // Clearing it from here restores the full علم.
    await tapVisible(tester, pill('ibn-baz'));
    expect(find.text('شرح ثلاثة الأصول'), findsOneWidget);
  });
}
