// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/ecjtu_control_palette.dart';
import '../theme/ecjtu_glass.dart';

import '../theme/ecjtu_theme.dart';
import 'ecjtu_icon.dart';
import 'ecjtu_desktop_navigation_scope.dart';
import 'ecjtu_mobile_insets.dart';

export 'ecjtu_dialog.dart';

class EcjtuPageScrollScope extends Notification {
  const EcjtuPageScrollScope(this.details);
  final bool details;
}

class EcjtuPageScrollAnchor extends Notification {
  const EcjtuPageScrollAnchor(this.active, {this.contentEndKey});
  final bool active;
  final GlobalKey? contentEndKey;
}

class _EcjtuAnchoredScrollPhysics extends ClampingScrollPhysics {
  const _EcjtuAnchoredScrollPhysics(this.maxOffset, {super.parent});

  final double Function() maxOffset;

  @override
  _EcjtuAnchoredScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _EcjtuAnchoredScrollPhysics(maxOffset, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final limit = maxOffset();
    if (value > position.pixels && value > limit) {
      return value - math.max(limit, position.pixels);
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class EcjtuPageColumn extends StatefulWidget {
  const EcjtuPageColumn({
    super.key,
    required this.child,
    this.contentFrameMaxWidth,
    this.controller,
  });

  final Widget child;
  final double? contentFrameMaxWidth;
  final ScrollController? controller;

  @override
  State<EcjtuPageColumn> createState() => _EcjtuPageColumnState();
}

class _EcjtuPageColumnState extends State<EcjtuPageColumn> {
  late final _main = widget.controller ?? ScrollController();
  final _contentKey = GlobalKey();
  final _viewportKey = GlobalKey();
  double _mainOffset = 0;
  double? _anchorOffset;
  double? _searchHeight;
  double _naturalMaxOffset = 0;
  GlobalKey? _contentEndKey;

  @override
  void dispose() {
    if (widget.controller == null) _main.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<EcjtuPageScrollAnchor>(
      onNotification: (event) {
        setState(() {
          if (event.active) {
            _anchorOffset = _main.hasClients ? _main.offset : 0;
            _searchHeight ??= _main.hasClients
                ? _main.position.maxScrollExtent +
                      _main.position.viewportDimension
                : 0;
            _contentEndKey = event.contentEndKey;
          } else {
            _anchorOffset = null;
            _searchHeight = null;
            _contentEndKey = null;
          }
        });
        return true;
      },
      child: NotificationListener<EcjtuPageScrollScope>(
        onNotification: (event) {
          if (_main.hasClients) {
            if (event.details) {
              _mainOffset = _main.offset;
              _main.jumpTo(0);
            } else {
              _main.jumpTo(_mainOffset);
            }
          }
          return true;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = EcjtuMetrics.columnForContext(
              context,
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            final bottomPadding =
                metrics.bottomPadding + EcjtuMobileInsets.bottomOf(context);
            final rightPadding =
                metrics.horizontalPadding +
                (constraints.maxWidth >= 1000 ? 8 : 0);
            final measuredChild = KeyedSubtree(
              key: _contentKey,
              child: widget.child,
            );
            final content = widget.contentFrameMaxWidth == null
                ? measuredChild
                : Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: math.min(
                        widget.contentFrameMaxWidth!,
                        math.max(
                          0,
                          constraints.maxWidth -
                              metrics.horizontalPadding -
                              rightPadding,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: measuredChild,
                      ),
                    ),
                  );
            if (_anchorOffset != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _anchorOffset == null) return;
                final height = _contentKey.currentContext?.size?.height;
                if (height == null) return;
                var naturalMax = math.max(
                  0.0,
                  height +
                      metrics.topPadding +
                      bottomPadding -
                      constraints.maxHeight,
                );
                final endBox = _contentEndKey?.currentContext
                    ?.findRenderObject();
                final viewportBox = _viewportKey.currentContext
                    ?.findRenderObject();
                if (endBox is RenderBox &&
                    endBox.hasSize &&
                    viewportBox is RenderBox &&
                    viewportBox.hasSize &&
                    _main.hasClients) {
                  final endBottom = endBox
                      .localToGlobal(Offset(0, endBox.size.height))
                      .dy;
                  final viewportBottom = viewportBox
                      .localToGlobal(Offset(0, viewportBox.size.height))
                      .dy;
                  naturalMax = math.max(
                    0.0,
                    _main.offset + endBottom - viewportBottom,
                  );
                }
                _naturalMaxOffset = naturalMax;
              });
            }
            final scrollView = SingleChildScrollView(
              key: _viewportKey,
              controller: _main,
              physics: _anchorOffset != null
                  ? _EcjtuAnchoredScrollPhysics(
                      () => math.max(_anchorOffset!, _naturalMaxOffset),
                    )
                  : null,
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                rightPadding,
                bottomPadding,
              ),
              child: _searchHeight == null
                  ? content
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          _searchHeight! - metrics.topPadding - bottomPadding,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: content,
                      ),
                    ),
            );
            if (EcjtuMetrics.phoneLayout(context)) return scrollView;
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ScrollbarTheme(
                data: ScrollbarTheme.of(
                  context,
                ).copyWith(crossAxisMargin: 3, mainAxisMargin: 12),
                child: Scrollbar(
                  controller: _main,
                  thumbVisibility: false,
                  radius: const Radius.circular(8),
                  thickness: 6,
                  interactive: true,
                  child: scrollView,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class EcjtuCard extends StatelessWidget {
  const EcjtuCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(EcjtuMetrics.cardPadding),
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            color ??
            EcjtuControlPalette.maybeOf(context)?.surface ??
            (EcjtuColors.surfaceFor(context)),
        borderRadius: BorderRadius.circular(EcjtuMetrics.cardRadius),
        border: Border.all(
          color:
              borderColor ??
              EcjtuControlPalette.maybeOf(context)?.border ??
              (EcjtuColors.borderFor(context)),
        ),
      ),
      child: child,
    );
  }
}

class EcjtuEntryCard extends StatefulWidget {
  const EcjtuEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.onPressed,
    this.fixedPreview = false,
    this.selected = false,
  });

  final String icon;
  final String title;
  final String detail;
  final VoidCallback? onPressed;
  final bool fixedPreview;
  final bool selected;

  @override
  State<EcjtuEntryCard> createState() => _EcjtuEntryCardState();
}

class _EcjtuEntryCardState extends State<EcjtuEntryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final mobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    final bodyFontSize = mobile
        ? 17.0
        : EcjtuMetrics.smartWorkBodyFontSizeFor(size);
    final colors = EcjtuGlass.of(context);
    final radius = mobile ? 12.0 : 7.0;
    final palette = EcjtuControlPalette.maybeOf(context);
    final captionFontSize = mobile ? 14.0 : EcjtuMetrics.fontCaptionFor(size);
    final iconColor =
        palette?.focus ??
        (dark ? const Color(0xFF77BCEB) : EcjtuColors.smartWorkIcon);
    final accentColor = _hovered
        ? (dark ? const Color(0xFF5085A3) : const Color(0xFF8DB7D0))
        : (dark ? const Color(0xFF61ADFF) : EcjtuColors.smartWorkIcon);
    final borderColor = mobile
        ? Color.lerp(colors.contentBorder, colors.accent, dark ? .18 : .16)!
        : palette?.border ??
              (_hovered
                  ? (dark ? const Color(0xFF5085A3) : const Color(0xFF8DB7D0))
                  : (EcjtuColors.borderFrom(
                      context,
                      dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
                    )));
    final content = Container(
      width: double.infinity,
      constraints: widget.fixedPreview
          ? BoxConstraints.tightFor(
              height:
                  (mobile ? 76 : 64) *
                  MediaQuery.textScalerOf(context).scale(14) /
                  14,
            )
          : BoxConstraints(minHeight: mobile ? 76 : 64),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 16 : 17,
            vertical: widget.fixedPreview ? 8 : (mobile ? 16 : 15),
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? colors.selected
                : mobile
                ? (_hovered
                      ? colors.hover
                      : Color.lerp(
                          colors.card,
                          colors.selected,
                          dark ? .20 : .12,
                        ))
                : palette != null
                ? (_hovered ? palette.hover : palette.surface)
                : _hovered
                ? (EcjtuColors.surfaceFrom(
                    context,
                    dark ? const Color(0xFF172B42) : const Color(0xFFEEF7FC),
                  ))
                : (EcjtuColors.surfaceFrom(
                    context,
                    dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD),
                  )),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(radius),
          ),
          foregroundDecoration: mobile || palette == null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: mobile
                          ? colors.accent.withValues(alpha: .65)
                          : accentColor,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: mobile ? 36 : 38,
                height: 28,
                child: EcjtuIcon(
                  widget.icon,
                  size: mobile ? 28 : 22,
                  color: iconColor,
                ),
              ),
              SizedBox(width: mobile ? 16 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      maxLines: widget.fixedPreview ? 1 : null,
                      overflow: widget.fixedPreview ? TextOverflow.clip : null,
                      style: TextStyle(
                        color:
                            palette?.foreground ??
                            (EcjtuColors.textFrom(
                              context,
                              dark
                                  ? const Color(0xFFE1EDFF)
                                  : EcjtuColors.smartWorkStrongText,
                            )),
                        fontSize: bodyFontSize,
                        fontWeight: palette != null
                            ? FontWeight.w600
                            : FontWeight.w700,
                        letterSpacing: 0,
                        height: 1.3,
                      ),
                    ),
                    if ((widget.fixedPreview || mobile || palette == null) &&
                        widget.detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.detail,
                        maxLines: widget.fixedPreview ? 1 : null,
                        overflow: widget.fixedPreview
                            ? TextOverflow.clip
                            : null,
                        style: TextStyle(
                          color:
                              palette?.muted ??
                              (EcjtuColors.mutedFrom(
                                context,
                                dark
                                    ? EcjtuColors.darkTextSecondary
                                    : const Color(0xFF667B8E),
                              )),
                          fontSize: captionFontSize,
                          letterSpacing: 0,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final card = content;

    if (widget.onPressed == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.title,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            onTap: widget.onPressed,
            child: card,
          ),
        ),
      ),
    );
  }
}

class EcjtuSectionTitle extends StatelessWidget {
  const EcjtuSectionTitle(
    this.title, {
    super.key,
    this.action,
    this.lineHeight = 1.2,
  });

  final String title;
  final Widget? action;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mobile = EcjtuMetrics.phoneLayout(context);
    final fontSize = mobile
        ? EcjtuMetrics.mobileSectionTitleFor(context)
        : EcjtuMetrics.sectionTitleFor(size);
    final scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...[
          Container(
            key: ValueKey('section-title-marker-$title'),
            width: 3,
            height: mobile ? scaledFontSize * .72 : 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: mobile ? scaledFontSize * .5 : 10),
        ],
        Expanded(
          child: Text(
            title,
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: mobile ? FontWeight.w700 : FontWeight.w600,
              height: lineHeight,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class EcjtuSubpageTitle extends StatelessWidget {
  const EcjtuSubpageTitle({
    super.key,
    required this.title,
    required this.backTitle,
    required this.onBack,
  });
  final String title;
  final String backTitle;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: EcjtuMetrics.pageHeaderHeightFor(context),
    child: EcjtuSectionTitle(
      title,
      lineHeight: 1.15,
      action:
          const {'返回工作台', '返回教务工具', '返回智慧学工', '返回通知与校历'}.contains(backTitle) &&
              EcjtuDesktopNavigationScope.secondaryOf(context)
          ? null
          : EcjtuBackAction(label: backTitle, onPressed: onBack),
    ),
  );
}

class EcjtuBackAction extends StatelessWidget {
  const EcjtuBackAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  static double fontSizeFor(BuildContext context) {
    if (EcjtuMetrics.phoneLayout(context)) {
      final view = View.of(context);
      final size = view.physicalSize / view.devicePixelRatio;
      return size.shortestSide >= 600 ? 15 : 13;
    }
    return EcjtuMetrics.isCompact(MediaQuery.sizeOf(context)) ? 13 : 15;
  }

  static double heightFor(BuildContext context) => math.max(
    EcjtuMetrics.phoneLayout(context)
        ? 36
        : EcjtuMetrics.actionHeightFor(context),
    MediaQuery.textScalerOf(context).scale(fontSizeFor(context)) + 12,
  );
  static ButtonStyle styleFor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final palette = EcjtuControlPalette.maybeOf(context);
    final normalBackground =
        palette?.surface ??
        (EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF14263A) : const Color(0xFFF2F8FC),
        ));
    final hoverBackground =
        palette?.hover ??
        (EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF1B334A) : const Color(0xFFE4F1F8),
        ));
    final normalBorder =
        palette?.border ??
        (EcjtuColors.borderFrom(
          context,
          dark ? const Color(0xFF426B83) : const Color(0xFFA9C9DC),
        ));
    final hoverBorder =
        palette?.focus ??
        (dark ? const Color(0xFF6797B4) : const Color(0xFF6B9FBC));
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, heightFor(context))),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      ),
      foregroundColor: WidgetStatePropertyAll(
        palette?.foreground ??
            EcjtuColors.textFrom(
              context,
              dark ? const Color(0xFFEDEDED) : const Color(0xFF222222),
            ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.hovered)
            ? hoverBackground
            : normalBackground,
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => BorderSide(
          color: states.contains(WidgetState.hovered)
              ? hoverBorder
              : normalBorder,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSizeFor(context),
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) =>
      EcjtuVisibleDirectoryScope.hidesReturn(context, label)
      ? const SizedBox.shrink()
      : TextButton(
          onPressed: onPressed,
          style: styleFor(context),
          child: Text(
            label.startsWith('返回') ? label : '返回$label',
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        );
}
