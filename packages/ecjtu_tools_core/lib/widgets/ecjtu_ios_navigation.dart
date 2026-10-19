// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ecjtu_icon.dart';
import '../platform/ios_platform.dart';

class IosNavigationIcons {
  static const names = [
    'desktop_calendar.svg',
    'desktop_workbench.svg',
    'desktop_academic.svg',
    'desktop_settings.svg',
    'communication_mail.svg',
    'desktop_messages.svg',
  ];
  static final images = <String, Uint8List>{};
  static Future<void> prepare() async {
    for (final name in names) {
      if (images.containsKey(name)) continue;
      final icon = await EcjtuIconPictures.load(name);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(84 / icon.size.width, 84 / icon.size.height);
      canvas.drawPicture(icon.picture);
      final picture = recorder.endRecording();
      final image = await picture.toImage(84, 84);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) images[name] = bytes.buffer.asUint8List();
      } finally {
        image.dispose();
        picture.dispose();
      }
    }
  }
}

class EcjtuIosNavigationBar extends StatefulWidget {
  static double heightFor(BuildContext context) =>
      IosPlatform.nativeTabBarHeight.value ??
      49 + MediaQuery.viewPaddingOf(context).bottom;

  const EcjtuIosNavigationBar({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    required this.accent,
    required this.dark,
  });
  final List<String> labels, icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accent;
  final bool dark;

  @override
  State<EcjtuIosNavigationBar> createState() => _EcjtuIosNavigationBarState();
}

class _EcjtuIosNavigationBarState extends State<EcjtuIosNavigationBar> {
  MethodChannel? _channel;
  Map<String, Object?> get _configuration => {
    'labels': widget.labels,
    'icons': [for (final icon in widget.icons) IosNavigationIcons.images[icon]],
    'selectedIndex': widget.selectedIndex,
    'accent': widget.accent.toARGB32(),
    'dark': widget.dark,
  };

  @override
  void didUpdateWidget(EcjtuIosNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.accent != widget.accent ||
        oldWidget.dark != widget.dark ||
        !listEquals(oldWidget.labels, widget.labels) ||
        !listEquals(oldWidget.icons, widget.icons)) {
      final configuration = _configuration;
      if (listEquals(oldWidget.icons, widget.icons) &&
          listEquals(oldWidget.labels, widget.labels)) {
        configuration.remove('icons');
      }
      unawaited(_channel?.invokeMethod<void>('update', configuration));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('ios-native-bottom-tabs'),
    height: EcjtuIosNavigationBar.heightFor(context),
    child: UiKitView(
      viewType: 'ecjtu/ios_navigation',
      creationParams: _configuration,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        if (!mounted) return;
        final channel = MethodChannel('ecjtu/ios_navigation/$id');
        _channel = channel;
        channel.setMethodCallHandler((call) async {
          if (!mounted) return;
          if (call.method == 'height' && call.arguments is num) {
            final height = (call.arguments as num).toDouble();
            if (height.isFinite &&
                height >= 32 &&
                height <= 240 &&
                IosPlatform.nativeTabBarHeight.value != height) {
              setState(() => IosPlatform.nativeTabBarHeight.value = height);
            }
            return;
          }
          if (call.method != 'select') return;
          final index = call.arguments;
          if (index is int &&
              index >= 0 &&
              index < widget.labels.length &&
              index != widget.selectedIndex) {
            widget.onSelected(index);
          }
        });
        unawaited(channel.invokeMethod<void>('update', _configuration));
      },
    ),
  );
}
