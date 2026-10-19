// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class EcjtuRetainedPages extends StatefulWidget {
  const EcjtuRetainedPages({
    super.key,
    required this.activePage,
    required this.pageBuilder,
    this.fit = StackFit.expand,
    this.backgroundPage,
    this.foregroundWidth,
  });

  final String activePage;
  final Widget Function(String page) pageBuilder;
  final StackFit fit;
  final String? backgroundPage;
  final double? foregroundWidth;

  @override
  State<EcjtuRetainedPages> createState() => _EcjtuRetainedPagesState();
}

class _EcjtuRetainedPagesState extends State<EcjtuRetainedPages> {
  final _visited = <String>{};
  final _pages = <String, Widget>{};
  final _media = <String, MediaQueryData>{};

  @override
  Widget build(BuildContext context) {
    _visited.add(widget.activePage);
    _pages[widget.activePage] = widget.pageBuilder(widget.activePage);
    _media[widget.activePage] = MediaQuery.of(context);
    final background = widget.backgroundPage;
    if (background != null && _visited.contains(background)) {
      _media[background] = MediaQuery.of(context);
      _pages[background] = widget.pageBuilder(background);
    }
    final pages = [
      if (background != null && _visited.contains(background)) background,
      ..._visited.where((page) => page != background),
    ];
    return Stack(
      fit: widget.fit,
      children: [
        for (final page in pages)
          Offstage(
            key: ValueKey(page),
            offstage: page != widget.activePage && page != background,
            child: _RetainedLayout(
              active: page == widget.activePage || page == background,
              child: MediaQuery(
                data: _media[page]!,
                child: ExcludeFocus(
                  excluding: page != widget.activePage && page != background,
                  child: TickerMode(
                    enabled: page == widget.activePage || page == background,
                    child: ClipRect(
                      clipper: page == widget.activePage && background != null
                          ? _LeadingPageClip(widget.foregroundWidth)
                          : null,
                      child: RepaintBoundary(child: _pages[page]!),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LeadingPageClip extends CustomClipper<Rect> {
  const _LeadingPageClip(this.width);
  final double? width;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, width ?? size.width, size.height);
  @override
  bool shouldReclip(_LeadingPageClip oldClipper) => width != oldClipper.width;
}

// Offstage preserves state but still lays out its child on every window resize.
// A hidden page keeps its last viewport until it becomes visible again.
class _RetainedLayout extends SingleChildRenderObjectWidget {
  const _RetainedLayout({required this.active, required super.child});
  final bool active;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RetainedLayoutBox(active);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RetainedLayoutBox renderObject,
  ) {
    renderObject.active = active;
  }
}

class _RetainedLayoutBox extends RenderProxyBox {
  _RetainedLayoutBox(this._active);
  bool _active;
  BoxConstraints? _lastConstraints;
  set active(bool value) {
    if (_active == value) return;
    _active = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    if (_active || _lastConstraints == null) _lastConstraints = constraints;
    child?.layout(_lastConstraints!, parentUsesSize: true);
    size = constraints.constrain(child?.size ?? Size.zero);
  }
}
