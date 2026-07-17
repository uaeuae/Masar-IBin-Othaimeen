import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to Android picture-in-picture (MainActivity). While a video player
/// screen is mounted, leaving the app shrinks it into a floating window that
/// keeps playing — TOS-compliant, the official player stays fully visible.
class PipController {
  PipController._();

  static const _channel = MethodChannel('app.masar.talib/pip');

  /// True while the activity is in a PiP window; the player screen renders
  /// only the video surface then.
  static final ValueNotifier<bool> inPip = ValueNotifier(false);

  static bool _handlerInstalled = false;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') {
        inPip.value = call.arguments == true;
      }
    });
  }

  /// Marks the foreground screen as PiP-eligible (video player mounted).
  static Future<void> setActive(bool active) async {
    if (!_supported) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod('setActive', active);
    } on PlatformException {
      // Best-effort: devices without PiP just background normally.
    } on MissingPluginException {
      // Widget tests / platforms without the channel.
    }
  }
}
