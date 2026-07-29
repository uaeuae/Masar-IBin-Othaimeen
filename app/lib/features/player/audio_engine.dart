import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:math' as math;

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
    bool isLocalFile = false,
  });

  Future<void> togglePlay();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);

  /// Applies a loudness correction in dB (0 = play the file untouched).
  Future<void> setGainDb(double gainDb);
  void dispose();
}

class JustAudioLessonEngine implements AudioLessonEngine {
  JustAudioLessonEngine()
    : _enhancer = !kIsWeb && Platform.isAndroid
          ? AndroidLoudnessEnhancer()
          : null {
    final enhancer = _enhancer;
    _player = AudioPlayer(
      audioPipeline: enhancer == null
          ? null
          : AudioPipeline(androidAudioEffects: [enhancer]),
    );
  }

  /// Android is the only platform that can lift a quiet lesson *above* its
  /// source level — iOS clamps AVPlayer's volume at 1.0× and just_audio ships
  /// no Darwin effects. There, a positive gain simply isn't applied. One
  /// enhancer per player: an effect can't be attached to two.
  final AndroidLoudnessEnhancer? _enhancer;

  late final AudioPlayer _player;

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
    bool isLocalFile = false,
  }) async {
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          isLocalFile ? Uri.file(url) : Uri.parse(url),
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
  Future<void> setGainDb(double gainDb) async {
    try {
      // Attenuation is just volume, and works everywhere. Boost is not: the
      // player's volume tops out at 1.0×, so a positive gain has to come from
      // the platform effect — which only Android has.
      final linear = math.pow(10, gainDb / 20).toDouble();
      await _player.setVolume(linear.clamp(0.0, 1.0));

      final enhancer = _enhancer;
      if (enhancer == null) return;
      final boost = gainDb > 0 ? gainDb : 0.0;
      await enhancer.setTargetGain(boost);
      await enhancer.setEnabled(boost > 0);
    } on Exception catch (error) {
      debugPrint('audio setGainDb failed: $error');
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
