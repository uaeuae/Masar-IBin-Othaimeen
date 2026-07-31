import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/providers.dart';
import 'features/player/audio_engine.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logCrash('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
    };
    // Everything before runApp is guarded individually. The zone handler below
    // only *logs* — it does not call runApp — so anything that throws up here
    // used to leave the reader on a blank screen with no splash, no error, and
    // a log they will never see. A frozen white app is the worst outcome
    // available; degrading is always better.

    // Background audio is a convenience: without it playback still works, it
    // just loses the lock-screen controls. Not worth the whole app.
    try {
      await initAudioBackground();
    } catch (error, stack) {
      debugPrint('background audio unavailable: $error');
      await _logCrash('initAudioBackground: $error\n$stack');
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (error, stack) {
      await _logCrash('SharedPreferences.getInstance: $error\n$stack');
    }

    // Settings live in prefs, so there is no sensible degraded mode — but say
    // so on screen rather than showing nothing at all.
    if (prefs == null) {
      runApp(const _StartupFailureApp());
      return;
    }

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MasarApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
    _logCrash('Uncaught: $error\n$stack');
  });
}

/// Shown when the app cannot start at all. Deliberately depends on nothing —
/// no theme, no providers, no fonts beyond the platform default — because
/// whatever failed may be exactly what those need.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF17492F),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'تعذر بدء التطبيق على هذا الجهاز.\nأعد فتحه، فإن تكرر الأمر '
                'فأعد تثبيته.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF3EFE0),
                  fontSize: 16,
                  height: 1.9,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Appends crashes to `<app-docs>/crash.log` so device-specific failures can
/// be retrieved and reported (no telemetry service in MVP).
Future<void> _logCrash(String message) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    File(
      '${dir.path}/crash.log',
    ).writeAsStringSync(
      '--- ${DateTime.now().toIso8601String()} ---\n$message\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // Logging must never crash the crash handler.
  }
}
