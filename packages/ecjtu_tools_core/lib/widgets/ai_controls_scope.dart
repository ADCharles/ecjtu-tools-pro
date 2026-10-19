// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/widgets.dart';

/// Carries the workspace's surface admission callback across dialog routes.
class AiControlsScope extends InheritedWidget {
  const AiControlsScope({
    super.key,
    required this.wrapDialog,
    required super.child,
  });

  final Widget Function(BuildContext origin, Widget child) wrapDialog;

  static Widget captureDialog(BuildContext origin, Widget child) {
    final scope = origin.getInheritedWidgetOfExactType<AiControlsScope>();
    if (scope == null) return child;
    return scope.wrapDialog(
      origin,
      AiControlsScope(wrapDialog: scope.wrapDialog, child: child),
    );
  }

  @override
  bool updateShouldNotify(AiControlsScope oldWidget) =>
      oldWidget.wrapDialog != wrapDialog;
}
