import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Engine for foundation-hosted audio lessons. Unlike the YouTube embed,
/// this one may legally keep playing in the background — just_audio_background
/// provides the media notification and lock-screen controls.
abstract class AudioLessonEngine {
  Stream<Duration> get positions;
  Stream<bool> get playing;
  Stream<void> get ended;

  Future<Duration?> currentDuration();

  Future<void> load({
    required String id,
    required String url,
    required String title,
    required String album,
    Duration start = Duration.zero,
  });

  Future<void> togglePlay();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);
  void dispose();
}

class JustAudioLessonEngine implements AudioLessonEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Stream<bool> get playing => _player.playingStream.distinct();

  @override
  Stream<void> get ended => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<Duration?> currentDuration() async => _player.duration;

  @override
  Future<void> load({
    required String id,
    required String url,
    required String title,
    required String album,
    Duration start = Duration.zero,
  }) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(id: id, title: title, album: album),
        ),
        initialPosition: start,
      );
      // Mirror the video player: opening a lesson starts it.
      unawaited(_player.play());
    } on Exception catch (error) {
      debugPrint('audio load($id) failed: $error');
    }
  }

  @override
  Future<void> togglePlay() async {
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } on Exception catch (error) {
      debugPrint('audio togglePlay failed: $error');
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } on Exception catch (error) {
      debugPrint('audio seekTo failed: $error');
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
    } on Exception catch (error) {
      debugPrint('audio setSpeed failed: $error');
    }
  }

  @override
  void dispose() {
    _player.dispose();
  }
}

/// Background audio (notification + lock screen) is an Android/iOS feature;
/// desktop dev-preview plays in-app only.
Future<void> initAudioBackground() async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.masar.talib.audio',
    androidNotificationChannelName: 'الدروس الصوتية',
    androidNotificationOngoing: true,
  );
}

/// Factory so each audio screen gets a fresh engine; tests override this
/// with a fake that never touches platform audio.
final audioEngineFactoryProvider = Provider<AudioLessonEngine Function()>(
  (ref) => JustAudioLessonEngine.new,
);
