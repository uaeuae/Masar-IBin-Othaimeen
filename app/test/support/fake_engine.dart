import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:masar/features/player/player_engine.dart';

/// Test double for the player: no WebView, fully scriptable.
class FakeLessonPlayerEngine implements LessonPlayerEngine {
  final positionsController = StreamController<Duration>.broadcast(sync: true);
  final endedController = StreamController<void>.broadcast(sync: true);

  /// (videoId, startPosition) for every load() call.
  final loads = <(String, Duration)>[];

  Duration? durationToReport;
  bool disposed = false;

  @override
  Widget buildView(BuildContext context) => const SizedBox.expand();

  @override
  Stream<Duration> get positions => positionsController.stream;

  @override
  Stream<void> get ended => endedController.stream;

  @override
  Future<Duration?> currentDuration() async => durationToReport;

  @override
  Future<void> load(String videoId, {Duration start = Duration.zero}) async {
    loads.add((videoId, start));
  }

  @override
  void dispose() {
    disposed = true;
    positionsController.close();
    endedController.close();
  }
}
