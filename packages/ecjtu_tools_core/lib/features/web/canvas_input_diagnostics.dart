// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CanvasInputDiagnostics {
  CanvasInputDiagnostics._();

  static bool get enabled =>
      Platform.isWindows &&
      Platform.environment['ECJTU_CANVAS_DIAGNOSTICS'] == '1';

  static Future<void> capture(
    InAppWebViewController controller,
    String host,
  ) async {
    if (!enabled) return;
    try {
      final result = await controller.callDevToolsProtocolMethod(
        methodName: 'Runtime.evaluate',
        parameters: {
          'expression': "document.querySelector('uni-canvas')",
          'returnByValue': false,
        },
      );
      final objectId = (result as Map?)?['result']?['objectId'];
      if (objectId is! String) return;
      final listeners = await controller.callDevToolsProtocolMethod(
        methodName: 'DOMDebugger.getEventListeners',
        parameters: {'objectId': objectId, 'depth': 3},
      );
      final eventTypes = <String, int>{};
      for (final entry
          in (listeners as Map?)?['listeners'] as List? ?? const []) {
        final type = (entry as Map?)?['type'];
        if (type is String) eventTypes[type] = (eventTypes[type] ?? 0) + 1;
      }
      final geometry = await controller.evaluateJavascript(
        source: r'''
(() => {
  const node = document.querySelector('uni-canvas');
  if (!node) return null;
  const rect = node.getBoundingClientRect();
  const inner = node.querySelector('canvas');
  return JSON.stringify({
    viewportWidth: innerWidth,
    dpr: devicePixelRatio,
    rect: {x: rect.x, y: rect.y, width: rect.width, height: rect.height},
    backing: inner ? {width: inner.width, height: inner.height} : null,
    maxTouchPoints: navigator.maxTouchPoints,
    pointerFine: matchMedia('(pointer: fine)').matches
  });
})()
''',
      );
      final record = {
        'time': DateTime.now().toIso8601String(),
        'host': host,
        'eventTypes': eventTypes,
        'geometry': geometry is String ? jsonDecode(geometry) : geometry,
      };
      await File(
        '${Directory.systemTemp.path}\\ecjtu_canvas_input.jsonl',
      ).writeAsString('${jsonEncode(record)}\n', mode: FileMode.append);
    } catch (error) {
      await File(
        '${Directory.systemTemp.path}\\ecjtu_canvas_input.jsonl',
      ).writeAsString(
        '${jsonEncode({'host': host, 'errorType': error.runtimeType.toString()})}\n',
        mode: FileMode.append,
      );
    }
  }
}
