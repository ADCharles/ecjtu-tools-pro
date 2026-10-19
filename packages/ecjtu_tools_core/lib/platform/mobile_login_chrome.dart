// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class MobileLoginChrome {
  static const channel = MethodChannel('ecjtu/login_chrome');

  static Future<void> setActive(bool active) async {
    if (kIsWeb) return;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await channel.invokeMethod<void>('setLoginActive', {
            'active': active,
          });
        case TargetPlatform.iOS:
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );
        default:
          break;
      }
    } on MissingPluginException {
      // Older embedded hosts may not provide the native window channel.
    }
  }
}
