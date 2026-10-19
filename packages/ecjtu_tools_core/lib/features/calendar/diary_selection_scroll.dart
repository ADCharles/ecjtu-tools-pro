// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DiarySelectionScrollController extends ScrollController {
  double pointerOvershoot = 0;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _DiarySelectionPosition(this, physics, context, oldPosition);
}

class _DiarySelectionPosition extends ScrollPositionWithSingleContext {
  _DiarySelectionPosition(
    this.owner,
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) : super(physics: physics, context: context, oldPosition: oldPosition);
  final DiarySelectionScrollController owner;

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    final distance = owner.pointerOvershoot;
    if (distance != 0 &&
        curve == Curves.linear &&
        duration.inMilliseconds <= 100) {
      // Flutter's selection scroller caps each step at 20px. Retain its
      // selection bookkeeping while making the rate follow pointer distance.
      final multiplier = ((distance.abs() + 12) / 20).clamp(1.0, 12.0);
      to = (pixels + (to - pixels) * multiplier).clamp(
        minScrollExtent,
        maxScrollExtent,
      );
      duration = const Duration(milliseconds: 16);
    }
    return super.animateTo(to, duration: duration, curve: curve);
  }
}

class DiarySelectionViewport extends StatefulWidget {
  const DiarySelectionViewport({
    super.key,
    required this.controller,
    required this.child,
  });
  final DiarySelectionScrollController controller;
  final Widget child;

  @override
  State<DiarySelectionViewport> createState() => _DiarySelectionViewportState();
}

class _DiarySelectionViewportState extends State<DiarySelectionViewport> {
  bool _dragging = false;
  void _reset(PointerEvent event) {
    _dragging = false;
    widget.controller.pointerOvershoot = 0;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) {
      _dragging =
          event.kind == PointerDeviceKind.mouse &&
          event.buttons == kPrimaryMouseButton;
    },
    onPointerMove: (event) {
      if (!_dragging) return;
      final box = context.findRenderObject() as RenderBox;
      final y = box.globalToLocal(event.position).dy;
      widget.controller.pointerOvershoot = y < 0
          ? y
          : y > box.size.height
          ? y - box.size.height
          : 0;
    },
    onPointerUp: _reset,
    onPointerCancel: _reset,
    child: widget.child,
  );
}
