import 'dart:async';

import 'package:masar/features/player/audio_engine.dart';

/// Test double for the audio engine: no platform audio, fully scriptable.
class FakeAudioLessonEngine implements AudioLessonEngine {
  final positionsController = StreamController<Duration>.broadcast(sync: true);
  final endedController = StreamController<void>.broadcast(sync: true);
  final playingController = StreamController<bool>.broadcast(sync: true);

  /// (id, url, start) for every load() call.
  final loads = <(String, String, Duration)>[];
  final seeks = <Duration>[];
  final speeds = <double>[];

  Duration? durationToReport;
  bool disposed = false;
  int togglePlayCalls = 0;

  @override
  Stream<Duration> get positions => positionsController.stream;

  @override
  Stream<void> get ended => endedController.stream;

  @override
  Stream<bool> get playing => playingController.stream;

  @override
  Future<Duration?> currentDuration() async => durationToReport;

  @override
  Future<void> load({
    required String id,
    required String url,
    required String title,
    required String album,
    Duration start = Duration.zero,
  }) async {
    loads.add((id, url, start));
  }

  @override
  Future<void> togglePlay() async {
    togglePlayCalls++;
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    speeds.add(speed);
  }

  @override
  void dispose() {
    disposed = true;
    positionsController.close();
    endedController.close();
    playingController.close();
  }
}
