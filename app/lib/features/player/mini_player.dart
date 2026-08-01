import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'playback_controller.dart';

/// The strip above the nav bar that says what is still playing.
///
/// It exists because leaving the player no longer stops the lesson: without a
/// persistent handle, audio would carry on with nothing on screen to pause it
/// or take you back — which is worse than stopping.
///
/// Deliberately small: a title, a progress hairline, play/pause, and a close.
/// Tapping it reopens the full player. Anything more competes with the screen
/// the reader actually navigated to.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider);
    if (!playback.hasLesson) return const SizedBox.shrink();

    final masar = masarColorsOf(context);
    final total = playback.total;
    final fraction = (total == null || total == Duration.zero)
        ? 0.0
        : (playback.position.inMilliseconds / total.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return Material(
      color: masar.heroGreen,
      child: InkWell(
        onTap: () => context.push(
          '/player/${playback.lessonId}?series=${playback.seriesSlug}',
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A hairline rather than a bar: it reports progress without
            // pretending to be a control — dragging happens in the player.
            LinearProgressIndicator(
              value: fraction,
              minHeight: 2,
              backgroundColor: masar.onHero.withAlpha(0x33),
              color: masar.gold,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playback.lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kUiFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: masar.onHero,
                          ),
                        ),
                        if (playback.seriesTitle.isNotEmpty)
                          Text(
                            playback.seriesTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kUiFont,
                              fontSize: 11,
                              color: masar.onHeroFaint,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: playback.playing ? 'إيقاف مؤقت' : 'تشغيل',
                    child: IconButton(
                      onPressed: () =>
                          ref.read(playbackControllerProvider.notifier).toggle(),
                      icon: Icon(
                        playback.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: masar.onHero,
                        size: 30,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'إنهاء التشغيل',
                    child: IconButton(
                      onPressed: () =>
                          ref.read(playbackControllerProvider.notifier).stop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: masar.onHeroDim,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
