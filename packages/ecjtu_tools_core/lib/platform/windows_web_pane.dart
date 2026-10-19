// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';

class WindowsWebPane {
  const WindowsWebPane._();

  static const _channel = MethodChannel('ecjtu/windows_web_pane');
  static void Function(double width)? onWorkspaceWidthChanged;
  static final clientViewport = ValueNotifier<Size?>(null);
  static final fixedLeftResizePaneWidth = ValueNotifier<double?>(null);

  static void initialize() {
    if (!Platform.isWindows) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'paneAnimationStarted') {
        final value = call.arguments;
        if (value is num) onWorkspaceWidthChanged?.call(value.toDouble());
        return;
      }
      if (call.method == 'clientViewportChanged') {
        final values = call.arguments as Map;
        final fixedPaneWidth = values['fixedPaneWidth'];
        fixedLeftResizePaneWidth.value = fixedPaneWidth is num
            ? fixedPaneWidth.toDouble()
            : null;
        final workspaceWidth = values['workspaceWidth'];
        clientViewport.value = Size(
          (values['width'] as num).toDouble(),
          (values['height'] as num).toDouble(),
        );
        if (workspaceWidth is num) {
          onWorkspaceWidthChanged?.call(workspaceWidth.toDouble());
        }
        return;
      }
      if (call.method != 'workspaceWidthChanged') return;
      final value = call.arguments;
      if (value is num) onWorkspaceWidthChanged?.call(value.toDouble());
    });
  }

  static Future<Size?> refreshClientViewport() async {
    if (!Platform.isWindows) return null;
    try {
      final values = await _channel.invokeMapMethod<String, dynamic>(
        'getClientViewport',
      );
      if (values == null) return null;
      final size = Size(
        (values['width'] as num).toDouble(),
        (values['height'] as num).toDouble(),
      );
      clientViewport.value = size;
      return size;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<bool> isMaximized() async {
    if (!Platform.isWindows) return false;
    try {
      return await _channel.invokeMethod<bool>('isMaximized') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> startTabDragPreview(String title) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('startTabDragPreview', {
        'title': title,
      });
    } on PlatformException {
      // The tab remains draggable if the runner has no native preview.
    }
  }

  static Future<void> stopTabDragPreview() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('stopTabDragPreview');
    } on PlatformException {
      // Older runners have no native preview.
    }
  }

  static Future<double?> setExtended(
    bool extended, {
    double paneWidth = 500,
  }) async {
    if (!Platform.isWindows) return null;
    if (!extended) fixedLeftResizePaneWidth.value = null;
    try {
      return await _channel.invokeMethod<double>('setExtended', {
        'extended': extended,
        'paneWidth': paneWidth,
      });
    } on PlatformException {
      return null;
    }
  }

  static Future<
    ({double workspaceWidth, double paneWidth, bool animateWindow})?
  >
  planExtended(double paneWidth) async {
    if (!Platform.isWindows) return null;
    try {
      final plan = await _channel.invokeMapMethod<String, dynamic>(
        'planExtended',
        {'paneWidth': paneWidth},
      );
      if (plan == null) return null;
      return (
        workspaceWidth: (plan['workspaceWidth'] as num).toDouble(),
        paneWidth: (plan['paneWidth'] as num).toDouble(),
        animateWindow: plan['animateWindow'] == true,
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<double> resizeExtended(
    double paneWidth, {
    bool opening = false,
  }) async {
    if (!Platform.isWindows) return paneWidth;
    try {
      return await _channel.invokeMethod<double>('resizeExtended', {
            'paneWidth': paneWidth,
            'opening': opening,
          }) ??
          paneWidth;
    } on PlatformException {
      return paneWidth;
    }
  }

  static Future<void> animateExtended(
    double paneWidth, {
    double? workspaceWidth,
  }) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('animateExtended', {
        'paneWidth': paneWidth,
        if (workspaceWidth != null) 'workspaceWidth': workspaceWidth,
      });
    } on PlatformException {
      await resizeExtended(paneWidth);
    }
  }

  static Future<void> setWorkspaceWidth(double width) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('setWorkspaceWidth', {
        'workspaceWidth': width,
      });
    } on PlatformException {
      // Window sizing remains usable even if the native synchronization is
      // unavailable on an older runner.
    }
  }

  static Future<WindowsWebPaneFrame?> detachedFrame({
    required double workspaceWidth,
  }) async {
    if (!Platform.isWindows) return null;
    try {
      final value = await _channel.invokeMapMethod<String, double>(
        'getDetachedFrame',
        {'workspaceWidth': workspaceWidth},
      );
      if (value == null) return null;
      final x = value['x'];
      final y = value['y'];
      final width = value['width'];
      final height = value['height'];
      if (x == null || y == null || width == null || height == null) {
        return null;
      }
      return WindowsWebPaneFrame(x: x, y: y, width: width, height: height);
    } on PlatformException {
      return null;
    }
  }

  static Future<WindowsCursorPosition?> cursorPosition() async {
    if (!Platform.isWindows) return null;
    try {
      final value = await _channel.invokeMapMethod<String, double>(
        'getCursorPosition',
      );
      final x = value?['x'];
      final y = value?['y'];
      if (value == null || x == null || y == null) return null;
      return WindowsCursorPosition(
        position: Offset(x, y),
        clientPosition: value['clientX'] == null || value['clientY'] == null
            ? null
            : Offset(value['clientX']!, value['clientY']!),
        leftButtonDown: value['leftButtonDown'] == 1.0,
        workArea: value['workLeft'] == null
            ? null
            : Rect.fromLTRB(
                value['workLeft']!,
                value['workTop']!,
                value['workRight']!,
                value['workBottom']!,
              ),
      );
    } on PlatformException {
      return null;
    }
  }

  /// Screen-space rectangles (logical pixels) of every detached browser
  /// window, used to detect "drop a sidebar tab onto a floating window".
  static Future<List<Rect>> detachedBrowserRects() async {
    if (!Platform.isWindows) return const [];
    try {
      final value = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'getDetachedBrowserRects',
      );
      if (value == null) return const [];
      return [
        for (final item in value)
          Rect.fromLTWH(
            (item['x'] as num?)?.toDouble() ?? 0,
            (item['y'] as num?)?.toDouble() ?? 0,
            (item['width'] as num?)?.toDouble() ?? 0,
            (item['height'] as num?)?.toDouble() ?? 0,
          ),
      ];
    } on PlatformException {
      return const [];
    }
  }
}

class WindowsCursorPosition {
  const WindowsCursorPosition({
    required this.position,
    this.clientPosition,
    this.leftButtonDown = false,
    this.workArea,
  });

  final Offset position;
  final Offset? clientPosition;
  final bool leftButtonDown;

  /// Screen work area (logical px) of the monitor under the cursor; null on
  /// older runners that do not report it.
  final Rect? workArea;
}

class WindowsWebPaneFrame {
  const WindowsWebPaneFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}
