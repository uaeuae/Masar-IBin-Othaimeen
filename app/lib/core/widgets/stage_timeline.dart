import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

enum StageState { done, current, upcoming }

/// One stage node on the journey timeline, per the design: 34px marker
/// (green check / bordered number / recessed number), 2px connector that is
/// green above completed stages, content supplied by the screen.
class StageTimelineNode extends StatelessWidget {
  const StageTimelineNode({
    super.key,
    required this.index,
    required this.state,
    this.isLast = false,
    required this.child,
  });

  /// 1-based stage number.
  final int index;
  final StageState state;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;

    final Widget marker = switch (state) {
      StageState.done => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: masar.heroGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.check_rounded, size: 16, color: masar.onHero),
      ),
      StageState.current => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: masar.chipBg,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Text(
          arabicDigits(index),
          style: TextStyle(
            fontFamily: kUiFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
      StageState.upcoming => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: masar.upcomingCircle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          arabicDigits(index),
          style: TextStyle(
            fontFamily: kUiFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: masar.textMuted,
          ),
        ),
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              marker,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == StageState.done
                        ? masar.heroGreen
                        : masar.timelineInactive,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
