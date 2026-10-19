// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show FocusManager, Color;

import '../app/app_edition.dart';

class IosPlatformInfo {
  const IosPlatformInfo({
    this.systemVersion = '',
    this.sdkVersion = '',
    this.version = '',
    this.build = '',
    this.nativeTabs = false,
  });
  factory IosPlatformInfo.fromMap(Map<Object?, Object?> value) =>
      IosPlatformInfo(
        systemVersion: value['systemVersion'] as String? ?? '',
        sdkVersion: value['sdkVersion'] as String? ?? '',
        version: value['version'] as String? ?? '',
        build: value['build'] as String? ?? '',
        nativeTabs: value['nativeTabs'] == true,
      );
  final String systemVersion, sdkVersion, version, build;
  final bool nativeTabs;
}

class IosPlatform {
  static const channel = MethodChannel('ecjtu/ios_platform');
  static IosPlatformInfo info = const IosPlatformInfo();
  static final keyboardAccessoryHeight = ValueNotifier<double>(0);
  static final nativeTabBarHeight = ValueNotifier<double?>(null);

  static Future<void> setKeyboardAppearance({
    required bool dark,
    required Color accent,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await channel.invokeMethod<void>('setKeyboardAppearance', {
        'dark': dark,
        'accent': accent.toARGB32(),
      });
    } on MissingPluginException {
      // The Flutter-only harness does not install the native input accessory.
    } on PlatformException {
      // A native appearance failure must not interrupt text entry.
    }
  }

  static bool get usesNativeTabs =>
      defaultTargetPlatform == TargetPlatform.iOS && info.nativeTabs;

  static Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'keyboardAccessoryHeight' && call.arguments is num) {
        final height = (call.arguments as num).toDouble();
        if (height.isFinite && height >= 0 && height <= 120) {
          keyboardAccessoryHeight.value = height;
        }
      } else if (call.method == 'keyboardDismissed') {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      }
    });
    try {
      final values = await channel.invokeMapMethod<Object?, Object?>('getInfo');
      if (values == null) return;
      info = IosPlatformInfo.fromMap(values);
      if (info.version.isNotEmpty && info.build.isNotEmpty) {
        AppEdition.versionLabel = '${info.version}+${info.build}';
      }
    } on MissingPluginException {
      info = const IosPlatformInfo();
    } on PlatformException {
      info = const IosPlatformInfo();
    }
  }
}
