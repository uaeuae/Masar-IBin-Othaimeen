import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/theme_mode_provider.dart';
import 'router.dart';
import 'theme.dart';

class MasarApp extends ConsumerWidget {
  const MasarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'مسار ابن عثيمين',
      debugShowCheckedModeBanner: false,
      // Arabic-only, RTL-first by design.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: router,
      // Phone-first layout: on wide windows (desktop preview, tablets)
      // letterbox the app to a phone-ish width instead of stretching cards.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (MediaQuery.sizeOf(context).width <= 560) return child;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
