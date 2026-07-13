import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

enum StageState { done, current, upcoming }

/// One stage (مرحلة) in a journey's vertical timeline. Stages are visually
/// sequenced but never locked — adult learners choose their own pace.
class StageTimelineNode extends StatelessWidget {
  const StageTimelineNode({
    super.key,
    required this.index,
    required this.title,
    required this.state,
    this.description,
    this.isLast = false,
    this.child,
  });

  /// 1-based stage number.
  final int index;
  final String title;
  final String? description;
  final StageState state;
  final bool isLast;

  /// Stage content (series cards / tiles) rendered under the title.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Widget marker = switch (state) {
      StageState.done => _markerCircle(
        background: scheme.primary,
        child: Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
      ),
      StageState.current => _markerCircle(
        background: scheme.primaryContainer,
        border: Border.all(color: scheme.primary, width: 2),
        child: Text(
          arabicDigits(index),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      StageState.upcoming => _markerCircle(
        background: Colors.transparent,
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
        child: Text(
          arabicDigits(index),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    };

    final dimmed = state == StageState.upcoming;

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
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    color: state == StageState.done
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Opacity(
              opacity: dimmed ? 0.65 : 1,
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 3),
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (child != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      child!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markerCircle({
    required Color background,
    Border? border,
    required Widget child,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
