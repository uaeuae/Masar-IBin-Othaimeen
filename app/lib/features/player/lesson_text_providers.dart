import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lesson_text.dart';

/// One repository for the app: it holds the parse cache, so toggling «النص»
/// off and on, or stepping to the next lesson and back, doesn't re-inflate.
final lessonTextRepositoryProvider = Provider<LessonTextRepository>(
  (ref) => LessonTextRepository(),
);

/// Null when the lesson has no bundled script.
final lessonTextProvider = FutureProvider.family<LessonText?, String>(
  (ref, lessonId) => ref.watch(lessonTextRepositoryProvider).load(lessonId),
);
