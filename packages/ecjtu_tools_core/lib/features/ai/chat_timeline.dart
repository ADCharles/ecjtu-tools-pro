// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../../widgets/ecjtu_chat.dart';

class AiChatTimeline extends StatefulWidget {
  const AiChatTimeline({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.listKey,
    this.padding = const EdgeInsets.all(12),
    this.findChildIndexCallback,
  });
  final ScrollController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Key? listKey;
  final EdgeInsetsGeometry padding;
  final ChildIndexGetter? findChildIndexCallback;

  @override
  State<AiChatTimeline> createState() => _AiChatTimelineState();
}

class _AiChatTimelineState extends State<AiChatTimeline> {
  bool _following = true;
  bool _scheduled = false;

  void _follow() {
    if (!_following || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_following || !widget.controller.hasClients) return;
      final position = widget.controller.position;
      if (position.pixels != position.maxScrollExtent) {
        widget.controller.jumpTo(position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(AiChatTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listKey != widget.listKey) _following = true;
    _follow();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: (event) {
      // A small upward wheel step can still be within the follow threshold.
      // Suspend before Scrollable applies it, including pending frame callbacks.
      if (event is PointerScrollEvent && event.scrollDelta.dy < 0) {
        _following = false;
      }
    },
    onPointerPanZoomUpdate: (event) {
      if (event.panDelta.dy > 0) _following = false;
    },
    child: NotificationListener<ScrollNotification>(
      onNotification: (notice) {
        if (notice.depth == 0 && notice is UserScrollNotification) {
          if (notice.direction == ScrollDirection.forward) {
            _following = false;
          } else if (notice.direction == ScrollDirection.reverse ||
              notice.direction == ScrollDirection.idle) {
            _following = notice.metrics.extentAfter <= 1;
          }
        }
        if (notice.depth == 0 &&
            notice is ScrollUpdateNotification &&
            notice.dragDetails != null &&
            (notice.scrollDelta ?? 0) < 0) {
          _following = false;
        }
        return false;
      },
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (notice) {
          if (notice.depth == 0) _follow();
          return false;
        },
        child: EcjtuChatTimeline(
          controller: widget.controller,
          plain: true,
          reverse: false,
          listKey: widget.listKey,
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
          padding: widget.padding,
          findChildIndexCallback: widget.findChildIndexCallback,
        ),
      ),
    ),
  );
}
