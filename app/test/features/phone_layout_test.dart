import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_app.dart';

/// Every screen, rendered at a real phone's size.
///
/// This file exists because two overflows shipped unnoticed — the sciences grid
/// by 19pt and the sort-chip row by 30pt — and no test caught them. The default
/// test surface is 800x600, which is wider and shorter than any phone, so a row
/// that cannot fit an iPhone still fits the harness. Anything laid out for the
/// app's actual target has to be asserted at the app's actual size.
///
/// `takeException()` is the assertion: a `RenderFlex overflowed` is reported as
/// a caught exception rather than a failure, so a test that never asks for it
/// passes straight through the bug.
void main() {
  /// iPhone 16 Pro logical size — the device this ships to first.
  const phone = Size(402, 874);

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// Also checks a reader who has turned text size up, which is the more
  /// common way a layout that "just fits" stops fitting.
  void useLargeText(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final (label, scale) in [('at phone size', false), ('with large text', true)]) {
    /// Boots home, then clears whatever the first frame reported before
    /// navigating. Without this every case inherits the home screen's own
    /// overflow and they all fail pointing at the wrong screen — which is
    /// exactly what happened the first time this file was written.
    Future<void> settleHome(WidgetTester tester) async {
      usePhone(tester);
      if (scale) useLargeText(tester);
      await tester.pumpAndSettle();
    }

    testApp('the home tab holds together $label', (tester, app) async {
      await settleHome(tester);
      expect(tester.takeException(), isNull);
    });

    testApp('the library holds together $label', (tester, app) async {
      await settleHome(tester);
      tester.takeException();
      await tester.tap(find.text('المكتبة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testApp('a science list holds together $label', (tester, app) async {
      await settleHome(tester);
      tester.takeException();
      final context = tester.element(find.byType(Navigator).first);
      GoRouter.of(context).push('/science/aqeedah');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testApp('the journeys tab holds together $label', (tester, app) async {
      await settleHome(tester);
      tester.takeException();
      await tester.tap(find.text('المسارات'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testApp('a scholar page holds together $label', (tester, app) async {
      await settleHome(tester);
      tester.takeException();
      final context = tester.element(find.byType(Navigator).first);
      GoRouter.of(context).push('/scholar/ibn-uthaymeen');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
