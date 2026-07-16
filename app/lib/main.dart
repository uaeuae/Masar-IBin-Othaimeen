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
    await initAudioBackground();
    final prefs = await SharedPreferences.getInstance();
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
