/// Domain enums shared by the design system and (from M2) the catalog models.
enum JourneyLevel {
  beginner,
  intermediate,
  advanced;

  String get labelAr => switch (this) {
    JourneyLevel.beginner => 'مبتدئ',
    JourneyLevel.intermediate => 'متوسط',
    JourneyLevel.advanced => 'متقدم',
  };

  static JourneyLevel fromJson(String value) => switch (value) {
    'beginner' => JourneyLevel.beginner,
    'intermediate' => JourneyLevel.intermediate,
    'advanced' => JourneyLevel.advanced,
    _ => throw ArgumentError('Unknown journey level: $value'),
  };
}

/// How a lesson is delivered: embedded YouTube video, or the foundation's
/// own MP3 stream (which may legally play in the background).
enum LessonMedia {
  video,
  audio;

  static LessonMedia fromJson(String value) => switch (value) {
    'video' => LessonMedia.video,
    'audio' => LessonMedia.audio,
    _ => throw ArgumentError('Unknown lesson media: $value'),
  };
}

/// Which read-along script a lesson has. `transcript` is the sheikh's speech,
/// so its sentences carry estimated times; `matn` is the book text being
/// explained, which is only ever synced at the marker level.
enum LessonTextKind {
  transcript,
  matn;

  static LessonTextKind? fromJson(String? value) => switch (value) {
    'transcript' => LessonTextKind.transcript,
    'matn' => LessonTextKind.matn,
    null => null,
    _ => throw ArgumentError('Unknown lesson text kind: $value'),
  };
}

enum LessonStatus {
  active,
  hidden,
  unavailable;

  static LessonStatus fromJson(String value) => switch (value) {
    'active' => LessonStatus.active,
    'hidden' => LessonStatus.hidden,
    'unavailable' => LessonStatus.unavailable,
    _ => throw ArgumentError('Unknown lesson status: $value'),
  };
}
