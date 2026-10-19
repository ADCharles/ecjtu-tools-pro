// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'package:flutter/material.dart';
import '../platform/ios_platform.dart';

class EcjtuIosKeyboardInset extends StatefulWidget {
  const EcjtuIosKeyboardInset({super.key, required this.child});
  final Widget child;

  @override
  State<EcjtuIosKeyboardInset> createState() => _EcjtuIosKeyboardInsetState();
}

class _EcjtuIosKeyboardInsetState extends State<EcjtuIosKeyboardInset> {
  Brightness? _brightness;
  Color? _accent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (_brightness == theme.brightness &&
        _accent == theme.colorScheme.primary) {
      return;
    }
    _brightness = theme.brightness;
    _accent = theme.colorScheme.primary;
    unawaited(
      IosPlatform.setKeyboardAppearance(
        dark: _brightness == Brightness.dark,
        accent: _accent!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: IosPlatform.keyboardAccessoryHeight,
    child: widget.child,
    builder: (context, accessory, child) {
      final media = MediaQuery.of(context);
      final bottom = media.viewInsets.bottom;
      return MediaQuery(
        data: media.copyWith(
          viewInsets: media.viewInsets.copyWith(
            bottom: bottom > 0 ? bottom + accessory : bottom,
          ),
        ),
        child: child!,
      );
    },
  );
}
