// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

enum WebRenderMode { automatic, mobile, desktop }

class WebRenderSignals {
  const WebRenderSignals({
    required this.hasDeviceWidthViewport,
    required this.hasMobileShell,
    required this.hasWideOverflow,
  });

  final bool hasDeviceWidthViewport;
  final bool hasMobileShell;
  final bool hasWideOverflow;

  factory WebRenderSignals.fromJavaScript(Object? value) {
    if (value is String) {
      try {
        return WebRenderSignals.fromJavaScript(jsonDecode(value));
      } catch (_) {
        return const WebRenderSignals(
          hasDeviceWidthViewport: false,
          hasMobileShell: false,
          hasWideOverflow: false,
        );
      }
    }
    if (value is! Map) {
      return const WebRenderSignals(
        hasDeviceWidthViewport: false,
        hasMobileShell: false,
        hasWideOverflow: false,
      );
    }
    return WebRenderSignals(
      hasDeviceWidthViewport: value['deviceWidth'] == true,
      hasMobileShell: value['mobileShell'] == true,
      hasWideOverflow: value['wideOverflow'] == true,
    );
  }
}

class WebRenderModeClassifier {
  WebRenderModeClassifier._();

  static WebRenderMode classify({
    required bool mobileApplicationSource,
    required WebRenderSignals signals,
  }) {
    if (signals.hasMobileShell) return WebRenderMode.mobile;
    if (mobileApplicationSource) return WebRenderMode.mobile;
    if (signals.hasDeviceWidthViewport) return WebRenderMode.mobile;
    return WebRenderMode.desktop;
  }
}
