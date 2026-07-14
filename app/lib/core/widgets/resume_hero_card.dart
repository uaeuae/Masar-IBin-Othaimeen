import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

/// The home hero: solid green card, Amiri series title, cream play circle,
/// gold progress bar, "توقفت عند / متبقٍ" footer. متابعة المشاهدة.
class ResumeHeroCard extends StatelessWidget {
  const ResumeHeroCard({
    super.key,
    required this.seriesTitle,
    required this.lessonLabel,
    required this.progress,
    this.stoppedAt,
    this.remaining,
    this.onTap,
  });

  final String seriesTitle;

  /// e.g. "الدرس ١٢ — كتاب الطهارة · باب المياه"
  final String lessonLabel;
  final double progress;
  final Duration? stoppedAt;
  final Duration? remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: masar.heroGreen,
          borderRadius: BorderRadius.circular(AppRadius.hero),
          boxShadow: [
            BoxShadow(
              color: masar.heroShadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seriesTitle, style: serif(21, masar.onHero)),
                      const SizedBox(height: 4),
                      Text(
                        lessonLabel,
                        style: TextStyle(
                          fontFamily: kUiFont,
                          fontSize: 13,
                          color: masar.onHeroDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: masar.onHero,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 26,
                    color: masar.heroGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0x40F3EFE0),
                color: masar.gold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (stoppedAt != null)
                  Text(
                    'توقفت عند ${clockLabel(stoppedAt!)}',
                    style: TextStyle(
                      fontFamily: kUiFont,
                      fontSize: 11.5,
                      color: masar.onHeroFaint,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (remaining != null)
                  Text(
                    'متبقٍ ${durationLabel(remaining!)}',
                    style: TextStyle(
                      fontFamily: kUiFont,
                      fontSize: 11.5,
                      color: masar.onHeroFaint,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
