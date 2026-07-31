import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Theme mode selection (فاتح / داكن / تلقائي), persisted locally.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }

  void cycle() {
    set(switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Autoplay the next lesson when one ends (used by the player).
class AutoplayNotifier extends Notifier<bool> {
  static const _key = 'autoplay_next';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final autoplayProvider = NotifierProvider<AutoplayNotifier, bool>(
  AutoplayNotifier.new,
);

/// Whether downloads may run on mobile data. Off by default: a زاد المستقنع
/// book is several GB, and a mis-tap shouldn't spend someone's bundle.
class AllowMobileDataNotifier extends Notifier<bool> {
  static const _key = 'downloads_allow_mobile_data';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final allowMobileDataProvider =
    NotifierProvider<AllowMobileDataNotifier, bool>(
      AllowMobileDataNotifier.new,
    );

/// Which coach-mark sequences the reader has already seen. Stored as a set of
/// keys rather than one boolean, so a sequence added later can run on its own
/// without replaying the ones already shown.
class SeenCoachMarksNotifier extends Notifier<Set<String>> {
  static const _key = 'seen_coach_marks';

  @override
  Set<String> build() =>
      (ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [])
          .toSet();

  bool has(String sequence) => state.contains(sequence);

  void markSeen(String sequence) {
    if (state.contains(sequence)) return;
    state = {...state, sequence};
    ref.read(sharedPreferencesProvider).setStringList(_key, state.toList());
  }
}

final seenCoachMarksProvider =
    NotifierProvider<SeenCoachMarksNotifier, Set<String>>(
      SeenCoachMarksNotifier.new,
    );

/// Whether the audio player opens on the lesson text rather than the artwork.
/// On by default -- reading along is the point of having the text at all.
class ShowLessonTextNotifier extends Notifier<bool> {
  static const _key = 'show_lesson_text';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final showLessonTextProvider = NotifierProvider<ShowLessonTextNotifier, bool>(
  ShowLessonTextNotifier.new,
);

/// Even out the library's loudness using each lesson's measured level.
class NormalizeVolumeNotifier extends Notifier<bool> {
  static const _key = 'normalize_volume';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final normalizeVolumeProvider =
    NotifierProvider<NormalizeVolumeNotifier, bool>(
      NormalizeVolumeNotifier.new,
    );

/// Daily-continuation reminder preference. Persisted now; the actual local
/// notification ships in Phase 2 (the UI labels it "قريبًا").
class DailyReminderNotifier extends Notifier<bool> {
  static const _key = 'daily_reminder';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final dailyReminderProvider = NotifierProvider<DailyReminderNotifier, bool>(
  DailyReminderNotifier.new,
);
