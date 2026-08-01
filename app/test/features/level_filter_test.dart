import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/widgets/level_badge.dart';
import 'package:masar/core/widgets/masar_chip.dart';
import 'package:masar/data/models/enums.dart';

import '../support/pump_app.dart';

/// The مبتدئ/متوسط/متقدم chips at the top of الرئيسية.
///
/// They were reported as "doing nothing", and they were: the journeys query
/// they feed threw on an upgraded install, so every chip led to an empty list.
/// But they were also *hard to believe* even when working — no مسار is «متقدم»
/// yet, so that chip silently fell back to another level's مسارات and left the
/// same two cards on screen. These tests pin both halves: the chip changes what
/// is suggested, and when it cannot, it says so.
void main() {
  Finder levelChip(String label) =>
      find.descendant(of: find.byType(MasarChip), matching: find.text(label));

  /// The suggestion cards' own level badges — what the reader is being offered,
  /// as opposed to what they asked for.
  List<JourneyLevel> suggestedLevels(WidgetTester tester) => tester
      .widgetList<LevelBadge>(find.byType(LevelBadge))
      .map((b) => b.level)
      .toList();

  /// Home is a lazy ListView and the suggestions sit at the bottom of it, so a
  /// phone-width surface has to be tall enough to build them — scrolling to
  /// them instead means picking the right Scrollable out of the chip rows
  /// nested inside it.
  Future<void> showWholeHome(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
  }

  testApp('choosing a level changes what الرئيسية suggests', (
    tester,
    app,
  ) async {
    await showWholeHome(tester);
    // مبتدئ is the default, and the fixture has three beginner مسارات.
    expect(suggestedLevels(tester), isNotEmpty);
    expect(suggestedLevels(tester), everyElement(JourneyLevel.beginner));

    await tapVisible(tester, levelChip('متوسط'));
    expect(suggestedLevels(tester), isNotEmpty);
    expect(suggestedLevels(tester), everyElement(JourneyLevel.intermediate));
    expect(find.textContaining('لا مسار بمستوى'), findsNothing);
  });

  testApp('a level with no مسار behind it says so instead of substituting', (
    tester,
    app,
  ) async {
    await showWholeHome(tester);
    await tapVisible(tester, levelChip('متقدم'));

    // Cards still appear — an empty section would be worse than an honest one —
    // but nothing pretends they are what was asked for.
    expect(
      find.text('لا مسار بمستوى «متقدم» بعد — هذه مقترحات أخرى'),
      findsOneWidget,
    );
    expect(suggestedLevels(tester), isNotEmpty);
    expect(suggestedLevels(tester), isNot(contains(JourneyLevel.advanced)));
  });
}
