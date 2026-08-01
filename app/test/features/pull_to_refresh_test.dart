import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/core/widgets/masar_refresh.dart';
import 'package:masar/core/widgets/masar_nav_bar.dart';

import '../support/pump_app.dart';

/// Pull-to-refresh, and what it can honestly claim to do.
///
/// The catalog ships inside the build — nothing is fetched — so this gesture is
/// not "get new lessons". It is recovery: a drift stream that throws reaches the
/// UI as *absent data*, so one broken query looks exactly like an empty library
/// and stays that way for the life of the process. That is not hypothetical;
/// «مساراتي» went blank for every install that upgraded into a schema missing a
/// column, and nothing short of a reinstall brought it back.
void main() {
  Finder navItem(String label) =>
      find.descendant(of: find.byType(MasarNavBar), matching: find.text(label));

  Future<void> pull(WidgetTester tester) async {
    await tester.fling(
      find.byType(RefreshIndicator).first,
      const Offset(0, 320),
      1000,
    );
    await tester.pumpAndSettle();
  }

  testApp('every browse tab can be pulled, and says what it found', (
    tester,
    app,
  ) async {
    for (final tab in ['الرئيسية', 'المسارات', 'المكتبة']) {
      await tester.tap(navItem(tab));
      await tester.pumpAndSettle();
      expect(
        find.byType(MasarRefresh),
        findsWidgets,
        reason: '$tab should be pullable',
      );

      await pull(tester);
      // Said out loud, because «nothing new» is the normal answer here and a
      // spinner that merely stops cannot be told from one that failed.
      expect(
        find.text('المحتوى لديك هو الأحدث'),
        findsOneWidget,
        reason: '$tab should report the outcome',
      );
    }
  });

  testApp('the detail screens are pullable too', (tester, app) async {
    final context = tester.element(find.byType(Navigator).first);
    for (final route in [
      '/journey/masar-alaqeedah',
      '/series/sharh-riyad-alsalihin',
      '/science/aqeedah',
      '/scholar/ibn-baz',
      '/downloads',
      '/settings',
    ]) {
      GoRouter.of(context).push(route);
      await tester.pumpAndSettle();
      expect(
        find.byType(MasarRefresh),
        findsWidgets,
        reason: '$route should be pullable',
      );
      GoRouter.of(context).pop();
      await tester.pumpAndSettle();
    }
  });

  testApp(
    'a screen with nothing on it can still be pulled',
    seed: (db) async {
      // No journeys at all: the list is empty, so there is nothing to overscroll
      // — which is exactly the state a refresh is for. Without a scrollable
      // wrapper the gesture would work everywhere except here.
      await db.customStatement('DELETE FROM journey_items');
      await db.customStatement('DELETE FROM journeys');
    },
    (tester, app) async {
      await tester.tap(navItem('المسارات'));
      await tester.pumpAndSettle();
      expect(find.text('لا مسارات تطابق التصفية'), findsOneWidget);

      await pull(tester);
      expect(find.text('المحتوى لديك هو الأحدث'), findsOneWidget);
    },
  );
}
