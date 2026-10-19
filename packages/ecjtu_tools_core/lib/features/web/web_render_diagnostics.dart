// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';

class WebRenderDiagnostics {
  static const enabled = bool.fromEnvironment('ECJTU_RENDER_DIAGNOSTICS');
  static Future<void> _queue = Future.value();

  static void record(Map<String, Object?> metrics) {
    if (!enabled) return;
    _queue = _queue
        .then((_) async {
          final file = File(
            '${Directory.systemTemp.path}/ecjtu-web-rendering.jsonl',
          );
          if (await file.exists() && await file.length() > 65536) {
            await file.writeAsString('');
          }
          await file.writeAsString(
            '${jsonEncode({'time': DateTime.now().toIso8601String(), ...metrics})}\n',
            mode: FileMode.append,
          );
        })
        .catchError((_) {});
  }

  // Collect geometry only: URLs, page text and session data must stay out.
  static const viewportScript = '''
    (() => JSON.stringify({
      innerWidth: innerWidth, innerHeight: innerHeight,
      devicePixelRatio: devicePixelRatio,
      clientWidth: document.documentElement.clientWidth,
      clientHeight: document.documentElement.clientHeight,
      scrollWidth: document.documentElement.scrollWidth,
      scrollHeight: Math.max(
        document.documentElement.scrollHeight,
        document.body?.scrollHeight || 0
      ),
      viewportScale: window.visualViewport?.scale,
      rootFontPixels: parseFloat(getComputedStyle(document.documentElement).fontSize),
      loadMilliseconds: performance.now()
    }))()
  ''';
}
