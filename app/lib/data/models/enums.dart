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
