// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MessageScrollBoundary extends StatelessWidget {
  const MessageScrollBoundary({
    super.key,
    required this.controller,
    required this.child,
  });
  final ScrollController controller;
  final Widget child;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (event) {
      if (event is! PointerScrollEvent || !controller.hasClients) return;
      final position = controller.position;
      final reversed =
          position.axisDirection == AxisDirection.up ||
          position.axisDirection == AxisDirection.left;
      final delta = reversed ? -event.scrollDelta.dy : event.scrollDelta.dy;
      final atBoundary = delta < 0
          ? position.pixels <= position.minScrollExtent
          : position.pixels >= position.maxScrollExtent;
      if (atBoundary) {
        GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
      }
    },
    child: child,
  );
}
