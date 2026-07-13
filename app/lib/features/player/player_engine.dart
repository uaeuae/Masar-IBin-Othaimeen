import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Total duration as reported by the player (null until metadata loads).
  Future<Duration?> currentDuration();

  Future<void> load(String videoId, {Duration start = Duration.zero});

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
  Future<Duration?> currentDuration() async {
    final seconds = await _controller.duration;
    return seconds > 0
        ? Duration(milliseconds: (seconds * 1000).round())
        : null;
  }

  @override
  Future<void> load(String videoId, {Duration start = Duration.zero}) =>
      _controller.loadVideoById(
        videoId: videoId,
        startSeconds: start.inSeconds.toDouble(),
      );

  @override
  void dispose() => _controller.close();
}

/// Factory so each player screen gets a fresh engine; tests override this
/// with a fake that never creates a WebView.
final playerEngineFactoryProvider = Provider<LessonPlayerEngine Function()>(
  (ref) => YoutubeLessonPlayerEngine.new,
);
