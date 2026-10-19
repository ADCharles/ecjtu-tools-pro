// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/widgets.dart';

class EcjtuMobileInsets extends InheritedWidget {
  const EcjtuMobileInsets({
    super.key,
    required this.bottom,
    required super.child,
  });
  final double bottom;
  static double bottomOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EcjtuMobileInsets>()?.bottom ??
      0;
  @override
  bool updateShouldNotify(EcjtuMobileInsets oldWidget) =>
      bottom != oldWidget.bottom;
}
