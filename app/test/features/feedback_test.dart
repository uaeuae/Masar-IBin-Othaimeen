import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/features/feedback/feedback_report.dart';

import '../support/pump_app.dart';

/// Reporting a mistake — especially a mistake in the *content*.
///
/// In a da'wah app a wrong attribution or a wrong title is the most serious
/// kind of defect, and the person most likely to catch it is a listener, mid
/// lesson. So the report has to be reachable from there and has to carry which
/// lesson it is about: «هناك خطأ» with no lesson names nothing and cannot be
/// acted on.
void main() {
  const context = ReportContext(
    appVersion: '0.1.0',
    catalogVersion: 15,
    platform: 'ios 18.0',
    lessonId: 'binbaz-2016',
    lessonTitle: 'الدرس ١ — باب كتاب التوحيد',
    seriesTitle: 'شرح كتاب التوحيد',
    scholarName: 'الشيخ عبد العزيز بن عبد الله بن باز',
    positionSeconds: 754,
  );

  group('the report itself', () {
    test('the subject names the kind and the lesson, so an inbox sorts', () {
      expect(
        reportSubject(ReportKind.wrongInfo, context),
        '[مسار] خطأ في المعلومات — الدرس ١ — باب كتاب التوحيد',
      );
      expect(
        reportSubject(ReportKind.idea, const ReportContext(
          appVersion: '0.1.0',
          catalogVersion: 15,
          platform: 'android 14',
        )),
        '[مسار] اقتراح',
      );
    });

    test('the body carries what is needed to find the mistake again', () {
      final body = reportBody(
        ReportKind.wrongInfo,
        context,
        'الشيخ المنسوب إليه الدرس غير صحيح.',
      );
      expect(body, startsWith('الشيخ المنسوب إليه الدرس غير صحيح.'));
      expect(body, contains('binbaz-2016'));
      expect(body, contains('شرح كتاب التوحيد'));
      // The moment, so a wrong-info report about a passage can be checked.
      expect(body, contains('12:34'));
      // The catalog version: content is corrected by republishing it, so a
      // report against an old snapshot may already be fixed.
      expect(body, contains('إصدار الفهرس: 15'));
    });

    test('a general report still carries the build it came from', () {
      final body = reportBody(
        ReportKind.bug,
        const ReportContext(
          appVersion: '0.1.0',
          catalogVersion: 15,
          platform: 'ios 18.0',
        ),
        'التطبيق يتوقف عند فتح المكتبة.',
      );
      expect(body, contains('إصدار التطبيق: 0.1.0'));
      expect(body, contains('ios 18.0'));
      expect(body, isNot(contains('الدرس:')));
    });

    test('the mailto is properly encoded, Arabic and newlines included', () {
      final uri = reportMailto(ReportKind.idea, context, 'أتمنى وضع علامات.');
      expect(uri.scheme, 'mailto');
      expect(uri.path, kFeedbackEmail);
      // Encoded, not raw: an unescaped newline or space truncates the body in
      // most mail clients.
      expect(uri.toString(), isNot(contains(' ')));
      expect(uri.toString(), isNot(contains('\n')));
      expect(Uri.decodeComponent(uri.query), contains('أتمنى وضع علامات.'));
    });
  });

  group('reaching it', () {
    testApp('settings offers it', (tester, app) async {
      final ctx = tester.element(find.byType(Navigator).first);
      GoRouter.of(ctx).push('/settings');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('الإبلاغ عن خطأ أو اقتراح'),
        300,
      );
      await tester.tap(find.text('الإبلاغ عن خطأ أو اقتراح'));
      await tester.pumpAndSettle();

      expect(find.text('ما نوع البلاغ؟'), findsOneWidget);
      // Content errors first — the category that matters most here.
      expect(find.text('خطأ في المعلومات'), findsWidgets);
      expect(find.text('اقتراح'), findsWidgets);
    });

    testApp('the player attaches the lesson being listened to', (
      tester,
      app,
    ) async {
      final ctx = tester.element(find.byType(Navigator).first);
      GoRouter.of(
        ctx,
      ).push('/player/fx-riyd-01?series=sharh-riyad-alsalihin');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      // Prefilled, so the reader only has to say what is wrong.
      expect(find.textContaining('شرح رياض الصالحين'), findsWidgets);
      expect(find.textContaining('fx-riyd-01'), findsOneWidget);
    });

    testApp('nothing is sent until the reader has written something', (
      tester,
      app,
    ) async {
      final ctx = tester.element(find.byType(Navigator).first);
      GoRouter.of(ctx).push('/feedback');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'المعلومة خاطئة');
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testApp('it says plainly that the app sends nothing itself', (
      tester,
      app,
    ) async {
      final ctx = tester.element(find.byType(Navigator).first);
      GoRouter.of(ctx).push('/feedback');
      await tester.pumpAndSettle();

      // The app promises «بلا جمع بيانات». A report leaves through the
      // reader's own mail app, and everything attached is listed first, so the
      // promise stays literally true.
      expect(find.text('سيُرفق مع رسالتك'), findsOneWidget);
      expect(find.textContaining('لا يُرسل شيء حتى تضغط إرسال'), findsOneWidget);
    });
  });
}
