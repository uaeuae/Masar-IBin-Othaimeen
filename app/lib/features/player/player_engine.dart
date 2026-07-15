import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Thin abstraction over the video player so the player screen (and its
/// tests) never touch the WebView directly. The only production
/// implementation embeds the official YouTube iframe player — TOS compliant.
abstract class LessonPlayerEngine {
  Widget buildView(BuildContext context);

  /// Playback position ticks while playing.
  Stream<Duration> get positions;

  /// Fires when a video reaches its end.
  Stream<void> get ended;

  /// Play/pause state changes.
  Stream<bool> get playing;

  /// Total duration as reported by the player (null until metadata loads).
  Future<Duration?> currentDuration();

  Future<void> load(String videoId, {Duration start = Duration.zero});

  Future<void> togglePlay();

  void dispose();
}

class YoutubeLessonPlayerEngine implements LessonPlayerEngine {
  final YoutubePlayerController _controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      playsInline: true,
      strictRelatedVideos: true,
      showFullscreenButton: true,
    ),
  );

  @override
  Widget buildView(BuildContext context) =>
      YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);

  @override
  Stream<Duration> get positions =>
      _controller.videoStateStream.map((state) => state.position);

  @override
  Stream<void> get ended => _controller.stream
      .where((value) => value.playerState == PlayerState.ended)
      .map((_) {});

  @override
  Stream<bool> get playing => _controller.stream
      .map((value) => value.playerState == PlayerState.playing)
      .distinct();

  @override
  Future<void> togglePlay() async {
    // If the iframe handshake never completed (no network, embed blocked),
    // controller calls time out — degrade silently instead of crashing.
    try {
      final state = _controller.value.playerState;
      if (state == PlayerState.playing) {
        await _controller.pauseVideo();
      } else {
        await _controller.playVideo();
      }
    } on Exception catch (error) {
      debugPrint('togglePlay failed: $error');
    }
  }

  @override
  Future<Duration?> currentDuration() async {
    final seconds = await _controller.duration;
    return seconds > 0
        ? Duration(milliseconds: (seconds * 1000).round())
        : null;
  }

  @override
  Future<void> load(String videoId, {Duration start = Duration.zero}) async {
    try {
      await _controller.loadVideoById(
        videoId: videoId,
        startSeconds: start.inSeconds.toDouble(),
      );
    } on Exception catch (error) {
      debugPrint('load($videoId) failed: $error');
    }
  }

  @override
  void dispose() => _controller.close();
}

/// Desktop dev-preview fallback: no WebView on Windows/Linux — show a notice
/// and open the lesson in the browser instead. Mobile uses the real embed.
class ExternalLinkPlayerEngine implements LessonPlayerEngine {
  String? _videoId;

  @override
  Widget buildView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تشغيل الفيديو داخل التطبيق متاح على الجوال',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _videoId == null
                  ? null
                  : () => launchUrl(
                      Uri.parse('https://www.youtube.com/watch?v=$_videoId'),
                      mode: LaunchMode.externalApplication,
                    ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('المشاهدة على يوتيوب'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Stream<Duration> get positions => const Stream.empty();

  @override
  Stream<void> get ended => const Stream.empty();

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Future<Duration?> currentDuration() async => null;

  @override
  Future<void> load(String videoId, {Duration start = Duration.zero}) async {
    _videoId = videoId;
  }

  @override
  Future<void> togglePlay() async {}

  @override
  void dispose() {}
}

/// Factory so each player screen gets a fresh engine; tests override this
/// with a fake that never creates a WebView.
final playerEngineFactoryProvider = Provider<LessonPlayerEngine Function()>((
  ref,
) {
  final isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  return isDesktop
      ? ExternalLinkPlayerEngine.new
      : YoutubeLessonPlayerEngine.new;
});
