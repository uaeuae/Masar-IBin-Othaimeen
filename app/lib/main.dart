import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/providers.dart';
import 'features/player/audio_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioBackground();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MasarApp(),
    ),
  );
}
