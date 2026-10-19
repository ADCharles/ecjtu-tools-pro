// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';
import '../theme/ecjtu_control_palette.dart';

Object? _openSelectOwner;
VoidCallback? _closeOpenSelect;

void dismissEcjtuPopup() => _closeOpenSelect?.call();

Offset _originInOverlay(BuildContext context, RenderBox box) {
  final overlay = Overlay.of(context).context.findRenderObject();
  return box.localToGlobal(
    Offset.zero,
    ancestor: overlay is RenderBox ? overlay : null,
  );
}

Offset _pixelAlignedFollowerOffset(
  BuildContext context, {
  required Alignment targetAnchor,
  double gap = 4,
}) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return Offset(0, gap);
  final origin = box.localToGlobal(Offset.zero);
  final x = origin.dx + (targetAnchor.x + 1) * box.size.width / 2;
  final y = origin.dy + (targetAnchor.y + 1) * box.size.height / 2 + gap;
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;
  double correction(double coordinate) =>
      (coordinate * pixelRatio).roundToDouble() / pixelRatio - coordinate;
  return Offset(correction(x), gap + correction(y));
}

class _PixelAlignedSlide extends StatelessWidget {
  const _PixelAlignedSlide({
    required this.position,
    required this.height,
    required this.child,
  });

  final Animation<Offset> position;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return AnimatedBuilder(
      animation: position,
      child: child,
      builder: (context, child) {
        // Keep the rasterized popup on the same pixel grid when opacity reaches 1.
        final physicalDy = position.value.dy * height * pixelRatio;
        return Transform.translate(
          offset: Offset(0, physicalDy.roundToDouble() / pixelRatio),
          child: child,
        );
      },
    );
  }
}

class EcjtuSelectBox<T> extends StatefulWidget {
  const EcjtuSelectBox({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.fontSize,
    this.enabled = true,
    this.textAlign = TextAlign.center,
    this.height,
    this.animateOpen = true,
    this.optimistic = true,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final double? fontSize;
  final bool enabled;
  final TextAlign textAlign;
  final double? height;
  final bool animateOpen;
  final bool optimistic;

  @override
  State<EcjtuSelectBox<T>> createState() => _EcjtuSelectBoxState<T>();
}

class EcjtuActionMenu<T> extends StatefulWidget {
  const EcjtuActionMenu({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
    this.tooltip = '更多',
    this.width = 210,
    this.iconColor,
    this.onOverlayBoundsChanged,
  });

  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final double width;
  final Color? iconColor;
  final FutureOr<void> Function(Rect?)? onOverlayBoundsChanged;

  @override
  State<EcjtuActionMenu<T>> createState() => _EcjtuActionMenuState<T>();
}

class _EcjtuActionMenuState<T> extends State<EcjtuActionMenu<T>>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _panelKey = GlobalKey();
  Rect? _reportedBounds;
  int _boundsGeneration = 0;
  OverlayEntry? _entry;
  T? _hoveredItem;
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final CurvedAnimation _menuAnimation;
  bool _closing = false;
  Future<void>? _closeFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticking = TickerMode.valuesOf(context).enabled;
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (_entry != null && (!ticking || !current)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _entry != null) _removeMenu();
      });
    }
  }

  @override
  void didUpdateWidget(covariant EcjtuActionMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_entry != null &&
        (oldWidget.items.length != widget.items.length ||
            !oldWidget.items.every(widget.items.contains))) {
      if (!widget.items.contains(_hoveredItem)) _hoveredItem = null;
      _entry!.markNeedsBuild();
    }
  }

  void _observePanelBounds(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _entry == null || generation != _boundsGeneration) return;
      final box = _panelKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final bounds = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        if (bounds != _reportedBounds) {
          _reportedBounds = bounds;
          widget.onOverlayBoundsChanged?.call(bounds);
        }
      }
      // Observe existing frames; do not drive an idle popup render loop.
      _observePanelBounds(generation);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _menuAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.035),
      end: Offset.zero,
    ).animate(_menuAnimation);
  }

  @override
  void dispose() {
    _menuAnimation.dispose();
    _controller.dispose();
    if (identical(_openSelectOwner, this)) {
      _openSelectOwner = null;
      _closeOpenSelect = null;
    }
    _entry?.remove();
    if (_entry != null) {
      final report = widget.onOverlayBoundsChanged;
      scheduleMicrotask(() => report?.call(null));
    }
    super.dispose();
  }

  void _toggle() {
    if (_closing) return;
    if (_entry != null) {
      _close();
      return;
    }
    if (!identical(_openSelectOwner, this)) _closeOpenSelect?.call();
    _openSelectOwner = this;
    _closeOpenSelect = () => unawaited(_close());
    final box = context.findRenderObject() as RenderBox;
    final button = _originInOverlay(context, box) & box.size;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context).copyWith(size: overlayBox.size);
    final menuHeight = widget.items.length * EcjtuMetrics.pickerItemHeight + 2;
    final menuWidth = math.min(widget.width, media.size.width - 16);
    final upward =
        button.bottom + menuHeight + 4 >
        media.size.height - media.padding.bottom - media.viewInsets.bottom;
    final anchor = upward ? Alignment.topRight : Alignment.bottomRight;
    final followerOffset = _pixelAlignedFollowerOffset(
      context,
      targetAnchor: anchor,
    );
    final horizontalCorrection =
        (button.right - menuWidth).clamp(
          8.0,
          math.max(8.0, media.size.width - menuWidth - 8),
        ) -
        (button.right - menuWidth);
    final themes = InheritedTheme.capture(
      from: context,
      to: Overlay.of(context).context,
    );
    _entry = OverlayEntry(
      builder: (overlayContext) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final palette = EcjtuControlPalette.maybeOf(context);
        final surface = palette?.surface ?? (EcjtuColors.surfaceFor(context));
        final border = palette?.border ?? (EcjtuColors.borderFor(context));
        final text = palette?.foreground ?? (EcjtuColors.textFor(context));
        final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
        return themes.wrap(
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CompositedTransformFollower(
                  link: _link,
                  showWhenUnlinked: false,
                  targetAnchor: anchor,
                  followerAnchor: Alignment.topLeft,
                  offset:
                      followerOffset -
                      Offset(
                        menuWidth - horizontalCorrection,
                        upward ? menuHeight + 8 : 0,
                      ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TapRegion(
                      groupId: this,
                      child: FadeTransition(
                        // A native child window is clipped below this popup;
                        // alpha blending would expose Flutter's backing surface.
                        opacity: widget.onOverlayBoundsChanged == null
                            ? _menuAnimation
                            : const AlwaysStoppedAnimation<double>(1),
                        child: _PixelAlignedSlide(
                          position: _slideAnimation,
                          height:
                              widget.items.length *
                                  EcjtuMetrics.pickerItemHeight +
                              2,
                          child: RepaintBoundary(
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                key: _panelKey,
                                width: menuWidth,
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: border),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(28, 31, 37, 0.12),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: widget.items
                                      .map((item) {
                                        final active = item == _hoveredItem;
                                        return MouseRegion(
                                          onEnter: (_) {
                                            _hoveredItem = item;
                                            _entry?.markNeedsBuild();
                                          },
                                          onExit: (_) {
                                            if (_hoveredItem == item) {
                                              _hoveredItem = null;
                                              _entry?.markNeedsBuild();
                                            }
                                          },
                                          child: SizedBox(
                                            height:
                                                EcjtuMetrics.pickerItemHeight,
                                            child: Material(
                                              color: active
                                                  ? palette?.hover ??
                                                        (dark
                                                            ? EcjtuColors
                                                                  .darkSelectionActive
                                                            : const Color(
                                                                0xFF287FD0,
                                                              ))
                                                  : Colors.transparent,
                                              child: InkWell(
                                                hoverColor:
                                                    palette?.hover ??
                                                    (dark
                                                        ? const Color(
                                                            0x143D95E8,
                                                          )
                                                        : const Color(
                                                            0x140475CC,
                                                          )),
                                                onTap: () async {
                                                  if (_closing) return;
                                                  await _close();
                                                  await WidgetsBinding
                                                      .instance
                                                      .endOfFrame;
                                                  if (mounted) {
                                                    widget.onSelected(item);
                                                  }
                                                },
                                                child: Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Text(
                                                      widget.labelBuilder(item),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: active
                                                            ? palette?.foreground ??
                                                                  Colors.white
                                                            : text,
                                                        fontFamily: fontFamily,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
    if (widget.onOverlayBoundsChanged != null) {
      _observePanelBounds(++_boundsGeneration);
    }
    setState(() {});
    _controller.forward(from: 0);
  }

  Future<void> _close() {
    if (_entry == null) return Future<void>.value();
    if (_closing) return _closeFuture ?? Future<void>.value();
    if (!TickerMode.valuesOf(context).enabled) {
      _removeMenu();
      return Future<void>.value();
    }
    _closing = true;
    return _closeFuture = _controller
        .reverse()
        .orCancel
        .then((_) {
          if (!mounted) return;
          _removeMenu();
        })
        .catchError((Object _) {});
  }

  void _removeMenu() {
    if (identical(_openSelectOwner, this)) {
      _openSelectOwner = null;
      _closeOpenSelect = null;
    }
    final wasOpen = _entry != null;
    _entry?.remove();
    _entry = null;
    _closing = false;
    _closeFuture = null;
    ++_boundsGeneration;
    _reportedBounds = null;
    if (wasOpen) widget.onOverlayBoundsChanged?.call(null);
    _controller.reset();
    _hoveredItem = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? (EcjtuColors.textFor(context));
    return TapRegion(
      groupId: this,
      onTapOutside: (_) => _close(),
      child: CompositedTransformTarget(
        link: _link,
        child: InkWell(
          borderRadius: BorderRadius.circular(EcjtuMetrics.pickerRadius),
          onTap: _toggle,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.more_horiz_rounded, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _EcjtuSelectBoxState<T> extends State<EcjtuSelectBox<T>>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _entryScrollControllers = <ScrollController>[];
  late final AnimationController _openController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late T _value = widget.value;
  OverlayEntry? _entry;
  ScrollPosition? _ancestorScrollPosition;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    final curve = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _openController,
      curve: Curves.easeOutQuad,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.035),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void dispose() {
    _stopWatchingAncestorScroll();
    if (identical(_openSelectOwner, this)) {
      _openSelectOwner = null;
      _closeOpenSelect = null;
    }
    _entry?.remove();
    _entry = null;
    for (final controller in _entryScrollControllers) {
      controller.dispose();
    }
    _entryScrollControllers.clear();
    _openController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EcjtuSelectBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_entry != null) {
      _close();
      return;
    }
    if (!identical(_openSelectOwner, this)) {
      _closeOpenSelect?.call();
    }
    _openSelectOwner = this;
    _closeOpenSelect = _close;
    _startWatchingAncestorScroll();
    final renderBox = context.findRenderObject() as RenderBox?;
    final buttonWidth = renderBox?.size.width ?? 120;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final media = MediaQuery.of(context).copyWith(size: overlayBox.size);
    final origin = renderBox == null
        ? Offset.zero
        : _originInOverlay(context, renderBox);
    var widest = buttonWidth;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(
          text: widget.labelBuilder(item),
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            fontSize: _fontSize(context),
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (painter.width + 24 > widest) widest = painter.width + 24;
      painter.dispose();
    }
    final width = widest.clamp(0.0, media.size.width - 16);
    final horizontalOffset = ((buttonWidth - width) / 2).clamp(
      8 - origin.dx,
      media.size.width - 8 - origin.dx - width,
    );
    var itemHeight = _itemHeight;
    for (final item in widget.items) {
      final painter = TextPainter(
        text: TextSpan(
          text: widget.labelBuilder(item),
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            fontSize: _fontSize(context),
            height: 1,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: (width - 16).clamp(1, double.infinity));
      if (painter.height + 12 > itemHeight) itemHeight = painter.height + 12;
      painter.dispose();
    }
    final below =
        media.size.height -
        media.viewInsets.bottom -
        media.padding.bottom -
        origin.dy -
        (renderBox?.size.height ?? 32);
    final above = origin.dy - media.padding.top;
    final openAbove = below < itemHeight * 5 + 6 && above > below;
    final available = openAbove ? above : below;
    final rowCount = ((available - 6) / itemHeight).floor().clamp(1, 5);
    final targetAnchor = openAbove ? Alignment.topLeft : Alignment.bottomLeft;
    final followerOffset = _pixelAlignedFollowerOffset(
      context,
      targetAnchor: targetAnchor,
      gap: openAbove ? -4 : 4,
    );
    // Precompute the scroll offset so the menu opens with the selected item
    // already centered — jumping after the first frame makes it visibly
    // twitch (e.g. picking 2:05, opening the minute column).
    final selectedIndex = widget.items.indexOf(_value);
    final contentHeight = widget.items.length * itemHeight;
    final menuHeight = itemHeight * rowCount + 2;
    final viewport = contentHeight.clamp(1.0, menuHeight - 2);
    final maxOffset = (contentHeight - viewport).clamp(0.0, double.infinity);
    final initialOffset = selectedIndex < 0
        ? 0.0
        : (selectedIndex * itemHeight - (viewport - itemHeight) / 2).clamp(
            0.0,
            maxOffset,
          );
    final scrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );
    _entryScrollControllers.add(scrollController);
    final themes = InheritedTheme.capture(
      from: context,
      to: Overlay.of(context).context,
    );
    _entry = OverlayEntry(
      builder: (overlayContext) => themes.wrap(
        Stack(
          clipBehavior: Clip.none,
          children: [
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: targetAnchor,
              followerAnchor: openAbove
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: followerOffset + Offset(horizontalOffset, 0),
              child: TapRegion(
                groupId: this,
                child: _PixelAlignedSlide(
                  position: _slideAnimation,
                  height: (contentHeight + 2).clamp(1.0, menuHeight),
                  child: RepaintBoundary(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: width,
                        constraints: BoxConstraints(maxHeight: menuHeight),
                        decoration: BoxDecoration(
                          color: _surface(overlayContext),
                          borderRadius: BorderRadius.circular(
                            EcjtuControlPalette.maybeOf(overlayContext) == null
                                ? 1
                                : 6,
                          ),
                          border: Border.all(color: _border(overlayContext)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(28, 31, 37, 0.12),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              final active = item == _value;
                              final dark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final palette = EcjtuControlPalette.maybeOf(
                                context,
                              );
                              return SizedBox(
                                height: itemHeight,
                                child: Material(
                                  color: active
                                      ? palette?.selected ??
                                            (dark
                                                ? EcjtuColors
                                                      .darkSelectionActive
                                                : const Color(0xFF287FD0))
                                      : Colors.transparent,
                                  child: InkWell(
                                    hoverColor:
                                        palette?.hover ??
                                        (dark
                                            ? const Color(0x143D95E8)
                                            : const Color(0x140475CC)),
                                    onTap: () {
                                      if (widget.optimistic) _value = item;
                                      _close();
                                      widget.onChanged(item);
                                    },
                                    child: Align(
                                      alignment: _menuTextAlignment(),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          widget.labelBuilder(item),
                                          softWrap: true,
                                          textAlign: widget.textAlign,
                                          style: TextStyle(
                                            fontFamily: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.fontFamily,
                                            fontSize: _fontSize(context),
                                            fontWeight: FontWeight.w400,
                                            height: 1,
                                            color: active
                                                ? palette?.foreground ??
                                                      Colors.white
                                                : _text(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
    if (widget.animateOpen) {
      _openController.forward(from: 0);
    } else {
      _openController.value = 1;
    }
  }

  void _close() {
    _stopWatchingAncestorScroll();
    if (identical(_openSelectOwner, this)) {
      _openSelectOwner = null;
      _closeOpenSelect = null;
    }
    final entry = _entry;
    _entry = null;
    entry?.remove();
    _openController.reset();
    for (final controller in _entryScrollControllers) {
      controller.dispose();
    }
    _entryScrollControllers.clear();
    if (mounted) setState(() {});
  }

  void _startWatchingAncestorScroll() {
    _stopWatchingAncestorScroll();
    _ancestorScrollPosition = Scrollable.maybeOf(context)?.position;
    _ancestorScrollPosition?.isScrollingNotifier.addListener(
      _handleAncestorScroll,
    );
  }

  void _stopWatchingAncestorScroll() {
    _ancestorScrollPosition?.isScrollingNotifier.removeListener(
      _handleAncestorScroll,
    );
    _ancestorScrollPosition = null;
  }

  void _handleAncestorScroll() {
    if (_ancestorScrollPosition?.isScrollingNotifier.value ?? false) {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: TapRegion(
        groupId: this,
        onTapOutside: (_) => _close(),
        child: CompositedTransformTarget(
          link: _link,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? _toggle : null,
            child: Container(
              constraints: BoxConstraints(
                minHeight:
                    widget.height ?? (_phone ? 32 : EcjtuMetrics.pickerHeight),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: _surface(context),
                borderRadius: BorderRadius.circular(EcjtuMetrics.pickerRadius),
                border: Border.all(color: _border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.labelBuilder(_value),
                      softWrap: true,
                      textAlign: widget.textAlign,
                      style: TextStyle(
                        color: _text(context),
                        fontFamily: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.fontFamily,
                        fontSize: _fontSize(context),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _entry == null ? 0.125 : 0.625,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: _text(context), width: 1.5),
                          bottom: BorderSide(color: _text(context), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _surface(BuildContext context) {
    return EcjtuControlPalette.maybeOf(context)?.surface ??
        (EcjtuColors.surfaceFor(context));
  }

  Color _border(BuildContext context) {
    return EcjtuControlPalette.maybeOf(context)?.border ??
        (EcjtuColors.borderFor(context));
  }

  Color _text(BuildContext context) {
    return EcjtuControlPalette.maybeOf(context)?.foreground ??
        (EcjtuColors.textFor(context));
  }

  Alignment _menuTextAlignment() {
    return switch (widget.textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }

  bool get _phone =>
      Theme.of(context).platform == TargetPlatform.android ||
      Theme.of(context).platform == TargetPlatform.iOS;
  double get _itemHeight => _phone
      ? (28 * MediaQuery.textScalerOf(context).scale(14) / 14).clamp(28, 56)
      : EcjtuMetrics.pickerItemHeight;

  double _fontSize(BuildContext context) {
    return widget.fontSize ??
        (Theme.of(context).platform == TargetPlatform.android ||
                Theme.of(context).platform == TargetPlatform.iOS
            ? 14
            : EcjtuMetrics.fontCaptionFor(MediaQuery.sizeOf(context)));
  }
}
