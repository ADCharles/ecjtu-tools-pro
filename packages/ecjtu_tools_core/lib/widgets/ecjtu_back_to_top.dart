// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class EcjtuWebScroll extends Notification {
  const EcjtuWebScroll(this.offset, this.onTop, this.source);
  final double offset;
  final Future<void> Function() onTop;
  final BuildContext source;
}

class EcjtuBackToTop extends StatefulWidget {
  const EcjtuBackToTop({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<EcjtuBackToTop> createState() => _EcjtuBackToTopState();
}

class _EcjtuBackToTopState extends State<EcjtuBackToTop> {
  BuildContext? _source;
  Future<void> Function()? _onTop;
  bool _visible = false;
  bool _scheduled = false;
  bool _nextVisible = false;

  void _update(
    double offset,
    BuildContext source,
    Future<void> Function() onTop,
  ) {
    if (source.getInheritedWidgetOfExactType<EcjtuBackToTopBlock>() != null) {
      _nextVisible = false;
      _schedule();
      return;
    }
    _source = source;
    _onTop = onTop;
    _nextVisible =
        offset > math.min(320.0, MediaQuery.sizeOf(context).height * 0.6);
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final source = _source;
      final visible =
          _nextVisible &&
          source != null &&
          source.mounted &&
          (ModalRoute.of(source)?.isCurrent ?? true);
      if (visible != _visible) setState(() => _visible = visible);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    if (!mobile || !widget.enabled) return widget.child;
    return NotificationListener<_HideBackToTop>(
      onNotification: (_) {
        _nextVisible = false;
        _source = null;
        _schedule();
        return true;
      },
      child: NotificationListener<EcjtuWebScroll>(
        onNotification: (event) {
          _update(event.offset, event.source, event.onTop);
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if (event.metrics.axis != Axis.vertical || event.context == null)
              return false;
            final source = event.context!;
            final scrollable = Scrollable.maybeOf(source);
            if (scrollable != null) {
              _update(event.metrics.pixels, source, () async {
                if (scrollable.mounted) {
                  await scrollable.position.animateTo(
                    scrollable.position.minScrollExtent,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  );
                }
              });
            }
            return false;
          },
          child: Listener(
            onPointerDown: (_) => _schedule(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                Positioned(
                  right: 16,
                  bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    reverseDuration: const Duration(milliseconds: 120),
                    child: _visible
                        ? Semantics(
                            label: '回到顶部',
                            button: true,
                            child: Material(
                              key: const ValueKey('mobile-back-to-top-surface'),
                              color: const Color(
                                0xFF80C7F5,
                              ).withValues(alpha: 0.72),
                              elevation: 5,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: const ValueKey('mobile-back-to-top'),
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (_source?.mounted ?? false)
                                    unawaited(_onTop?.call());
                                  _nextVisible = false;
                                  _schedule();
                                },
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: CustomPaint(
                                      size: Size(22, 22),
                                      painter: _BackToTopArrowPainter(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: 44, height: 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HideBackToTop extends Notification {
  const _HideBackToTop();
}

class EcjtuBackToTopBlock extends InheritedWidget {
  const EcjtuBackToTopBlock({super.key, required super.child});
  @override
  bool updateShouldNotify(EcjtuBackToTopBlock oldWidget) => false;

  static Widget wrap(Widget child) => _BackToTopBlockEntry(child: child);
}

class _BackToTopBlockEntry extends StatefulWidget {
  const _BackToTopBlockEntry({required this.child});
  final Widget child;
  @override
  State<_BackToTopBlockEntry> createState() => _BackToTopBlockEntryState();
}

class _BackToTopBlockEntryState extends State<_BackToTopBlockEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) const _HideBackToTop().dispatch(context);
    });
  }

  @override
  Widget build(BuildContext context) =>
      EcjtuBackToTopBlock(child: widget.child);
}

class _BackToTopArrowPainter extends CustomPainter {
  const _BackToTopArrowPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final tip = Offset(size.width * 0.5, size.height * 0.28);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.78), tip, paint);
    canvas.drawLine(tip, Offset(size.width * 0.27, size.height * 0.51), paint);
    canvas.drawLine(tip, Offset(size.width * 0.73, size.height * 0.51), paint);
  }

  @override
  bool shouldRepaint(covariant _BackToTopArrowPainter oldDelegate) => false;
}
