// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';
import '../app/app_edition.dart';
import 'ecjtu_icon.dart';
import 'ecjtu_edition_badge.dart';

class EcjtuHeaderBar extends StatelessWidget {
  const EcjtuHeaderBar({
    super.key,
    required this.title,
    this.badge = AppEdition.badge,
    this.accountName,
    this.accountId,
    this.accountMode,
    this.weekStatusPrimary,
    this.weekStatusSecondary,
    this.syncFeedback = '尚未获取数据',
    this.onBack,
    this.onRefresh,
    this.onMessages,
    this.onAccount,
    this.isRefreshing = false,
    this.unreadCount = 0,
  });

  final String title;
  final String badge;
  final String? accountName;
  final String? accountId;
  final String? accountMode;
  final String? weekStatusPrimary;
  final String? weekStatusSecondary;
  final String? syncFeedback;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onMessages;
  final VoidCallback? onAccount;
  final bool isRefreshing;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final wideDateWidth = _dateWidth(context, compact: false);
    return _StableHeaderLayout(
      minimumWideWidth:
          260 +
          2 *
              math.max(
                _leadingWidth(
                  context,
                  compact: false,
                  fontSize: 22,
                  byline: true,
                ),
                _actionsWidth(
                  compact: false,
                  week: weekStatusPrimary != null,
                  dateWidth: wideDateWidth,
                ),
              ) +
          24,
      builder: (context, constraints, compact, visible) {
        final windowSize = MediaQuery.sizeOf(context);
        final availableWidth = constraints.maxWidth;
        // The header can be rendered inside the left workspace while a web
        // pane is open.  In that case the inherited MediaQuery still describes
        // the whole window, so using it for breakpoints would keep a desktop
        // header in a narrow workspace and clip its controls.
        final layoutSize = Size(availableWidth, windowSize.height);
        final phone = EcjtuMetrics.phoneLayout(context);
        final horizontalPadding = compact
            ? (availableWidth < 360 ? 4.0 : 8.0)
            : 8.0;
        final accountGap = accountName == null
            ? 0.0
            : (availableWidth < 360
                  ? 4.0
                  : compact
                  ? 6.0
                  : 8.0);
        final contentWidth = math.max(
          0.0,
          availableWidth - horizontalPadding * 2,
        );
        final brandFontSize = compact ? 14.0 : 22.0;
        final minimumAccountWidth =
            math
                .max(
                  _textWidth(
                    context,
                    accountName ?? '',
                    compact ? 11.5 : 15,
                    FontWeight.w700,
                  ),
                  _textWidth(
                    context,
                    accountMode ?? '',
                    compact ? 8.5 : 12,
                    FontWeight.w400,
                  ),
                )
                .ceilToDouble() +
            (compact ? 18 : 22);
        final baseAccountWidth = accountName == null
            ? 0.0
            : math.max(
                compact ? (availableWidth < 360 ? 64.0 : 82.0) : 260.0,
                minimumAccountWidth,
              );
        final dateWidth = _dateWidth(context, compact: compact);
        final bylineWidth = _leadingWidth(
          context,
          compact: compact,
          fontSize: brandFontSize,
          byline: true,
        );
        final completeAccountWidth = accountName == null
            ? 0.0
            : math.max(
                baseAccountWidth,
                _textWidth(
                      context,
                      '$accountName · ${accountId ?? ''}',
                      compact ? 11.5 : 15,
                      FontWeight.w700,
                    ).ceilToDouble() +
                    (compact ? 18 : 22),
              );
        final completeSideWidth = math.max(
          bylineWidth,
          _actionsWidth(
            compact: compact,
            week: weekStatusPrimary != null,
            dateWidth: dateWidth,
          ),
        );
        final showAccountId = visible(
          'account',
          accountId != null && accountId!.isNotEmpty,
          contentWidth,
          completeAccountWidth + 2 * completeSideWidth + accountGap,
        );
        final accountWidth = showAccountId
            ? completeAccountWidth
            : baseAccountWidth;
        final sideBudget = (contentWidth - accountWidth - accountGap) / 2;
        final compactActions = compact;
        final showWeekStatus = visible(
          'date',
          weekStatusPrimary != null,
          sideBudget,
          _actionsWidth(
            compact: compactActions,
            week: true,
            dateWidth: dateWidth,
          ),
        );
        final naturalRightWidth = _actionsWidth(
          compact: compactActions,
          week: showWeekStatus,
          dateWidth: dateWidth,
        );
        final showByline = visible('byline', true, sideBudget, bylineWidth);
        final leadingWidth = _leadingWidth(
          context,
          compact: compact,
          fontSize: brandFontSize,
          byline: showByline,
        );
        final syncWidth = phone
            ? math.max(
                84.0,
                math
                        .max(
                          _textWidth(
                            context,
                            syncFeedback?.split('\n').first ?? '',
                            compact ? 10 : 12,
                            compact ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: 'SourceHanSansCN',
                          ),
                          _textWidth(
                            context,
                            syncFeedback?.split('\n').skip(1).join('\n') ?? '',
                            compact ? 9 : 12,
                            compact ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: 'SourceHanSansCN',
                          ),
                        )
                        .ceilToDouble() +
                    4,
              )
            : compact
            ? math.max(
                0.0,
                math.min(
                  84.0,
                  contentWidth -
                      leadingWidth -
                      accountWidth -
                      accountGap -
                      (naturalRightWidth - 84),
                ),
              )
            : 160.0;
        final rightWidth = naturalRightWidth - (compact ? 84 : 160) + syncWidth;
        final visualHeight = compact
            ? EcjtuMetrics.compactHeaderHeight
            : EcjtuMetrics.fullHeaderHeight;
        final topInset = MediaQuery.paddingOf(context).top;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: visualHeight + topInset,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? const [
                      EcjtuColors.darkHeaderStart,
                      EcjtuColors.darkHeaderMiddle,
                      EcjtuColors.darkHeaderEnd,
                    ]
                  : const [
                      EcjtuColors.headerStart,
                      EcjtuColors.headerMiddle,
                      EcjtuColors.headerEnd,
                    ],
              stops: const [0, 0.5, 1],
            ),
            border: Border(
              bottom: BorderSide(
                color: dark
                    ? EcjtuColors.darkHeaderDivider
                    : EcjtuColors.headerDivider,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: topInset,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: SizedBox(
              height: visualHeight,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: layoutSize),
                child: DefaultTextStyle(
                  style: TextStyle(
                    inherit: false,
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.fontFamily,
                    fontFamilyFallback: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.fontFamilyFallback,
                    fontSize: 12,
                    letterSpacing: 0,
                    height: 1,
                    color: Colors.white,
                  ),
                  child: NavigationToolbar(
                    centerMiddle: true,
                    middleSpacing: accountGap / 2,
                    leading: phone
                        ? SizedBox(
                            width: math.max(0, sideBudget),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _HeaderLeading(
                                  badge: badge,
                                  onBack: onBack,
                                  title: title,
                                  fontSize: brandFontSize,
                                  compact: compact,
                                  showByline: showByline,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            widthFactor: 1,
                            child: _HeaderLeading(
                              badge: badge,
                              onBack: onBack,
                              title: title,
                              fontSize: brandFontSize,
                              compact: compact,
                              showByline: showByline,
                            ),
                          ),
                    middle: accountName == null
                        ? null
                        : Semantics(
                            button: onAccount != null,
                            label: '打开 AI 助手',
                            child: MouseRegion(
                              cursor: onAccount == null
                                  ? MouseCursor.defer
                                  : SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onAccount,
                                child: _AccountBadge(
                                  name: accountName!,
                                  accountId: accountId,
                                  mode: accountMode,
                                  compact: compact,
                                  showAccountId: showAccountId,
                                  width: accountWidth,
                                ),
                              ),
                            ),
                          ),
                    trailing: phone
                        ? SizedBox(
                            width: math.max(0, sideBudget),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: rightWidth,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _HeaderActions(
                                      dateWidth: dateWidth,
                                      compact: compactActions,
                                      showWeekStatus: showWeekStatus,
                                      weekStatusPrimary: weekStatusPrimary,
                                      weekStatusSecondary: weekStatusSecondary,
                                      syncFeedback: syncFeedback,
                                      syncWidth: syncWidth,
                                      onMessages: onMessages,
                                      onRefresh: onRefresh,
                                      isRefreshing: isRefreshing,
                                      unreadCount: unreadCount,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: rightWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _HeaderActions(
                                dateWidth: dateWidth,
                                compact: compactActions,
                                showWeekStatus: showWeekStatus,
                                weekStatusPrimary: weekStatusPrimary,
                                weekStatusSecondary: weekStatusSecondary,
                                syncFeedback: syncFeedback,
                                syncWidth: syncWidth,
                                onMessages: onMessages,
                                onRefresh: onRefresh,
                                isRefreshing: isRefreshing,
                                unreadCount: unreadCount,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _leadingWidth(
    BuildContext context, {
    required bool compact,
    required double fontSize,
    bool byline = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'ECJTU $title',
        style: TextStyle(
          fontFamily: 'SourceHanSansCN',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    double measure(String text, double font, FontWeight weight) {
      final label = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'SourceHanSansCN',
            fontSize: font,
            fontWeight: weight,
            letterSpacing: 0,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = label.width;
      label.dispose();
      return width;
    }

    final proWidth =
        measure(badge, compact ? 7.5 : 10, FontWeight.w700) +
        (compact ? 6 : 14);
    final markerAndGaps = compact ? 16.0 : 20.0;
    final backWidth = onBack == null
        ? 0.0
        : compact
        ? 28.0
        : 42.0;
    final bylineWidth = byline
        ? measure('By 阿东Charles', compact ? 9 : 12, FontWeight.w600) + 8
        : 0.0;
    final width =
        painter.width + proWidth + markerAndGaps + backWidth + bylineWidth;
    painter.dispose();
    return width;
  }

  double _actionsWidth({
    required bool compact,
    required bool week,
    bool sync = true,
    double dateWidth = 104,
  }) {
    var width = 0.0;
    if (week) width += dateWidth;
    if (sync) {
      if (week) width += compact ? 3 : 8;
      width += compact ? 84 : 160;
    }
    if ((sync || week) && (onMessages != null || onRefresh != null)) {
      width += compact ? 3 : 8;
    }
    if (onMessages != null) width += compact ? 24 : 34;
    if (onMessages != null && onRefresh != null) width += compact ? 3 : 8;
    if (onRefresh != null) width += compact ? 24 : 34;
    return width;
  }

  double _dateWidth(BuildContext context, {required bool compact}) =>
      math
          .max(
            _textWidth(
              context,
              weekStatusPrimary ?? '',
              compact ? 14 : 18,
              FontWeight.w600,
            ),
            _textWidth(
              context,
              weekStatusSecondary ?? '',
              compact ? 10 : 12,
              FontWeight.w400,
            ),
          )
          .ceilToDouble() +
      (compact ? 7 : 11);

  double _textWidth(
    BuildContext context,
    String value,
    double size,
    FontWeight weight, {
    String? fontFamily,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily:
              fontFamily ?? Theme.of(context).textTheme.bodyMedium?.fontFamily,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: 0,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _StableHeaderLayout extends StatefulWidget {
  const _StableHeaderLayout({
    required this.builder,
    required this.minimumWideWidth,
  });
  final double minimumWideWidth;

  final Widget Function(
    BuildContext,
    BoxConstraints,
    bool,
    bool Function(String, bool, double, double),
  )
  builder;

  @override
  State<_StableHeaderLayout> createState() => _StableHeaderLayoutState();
}

class _StableHeaderLayoutState extends State<_StableHeaderLayout> {
  bool? _compact;
  final _visible = <String, bool>{};

  bool _stabilize(String key, bool enabled, double available, double required) {
    final previous = _visible[key];
    final next = enabled && available >= required + (previous == false ? 8 : 0);
    _visible[key] = next;
    return next;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      _compact ??= width < widget.minimumWideWidth;
      // A dead band prevents resize rounding from alternating typography.
      if (!_compact! && width < widget.minimumWideWidth) _compact = true;
      if (_compact! && width >= widget.minimumWideWidth + 24) _compact = false;
      return widget.builder(context, constraints, _compact!, _stabilize);
    },
  );
}

class _HeaderLeading extends StatelessWidget {
  const _HeaderLeading({
    required this.onBack,
    required this.title,
    this.badge = AppEdition.badge,
    required this.compact,
    required this.showByline,
    required this.fontSize,
  });

  final VoidCallback? onBack;
  final String title;
  final String badge;
  final bool compact;
  final bool showByline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onBack != null) ...[
          _HeaderIconButton(
            icon: EcjtuBackGlyph(size: compact ? 17 : 18, color: Colors.white),
            tooltip: '返回',
            onPressed: onBack!,
            compact: compact,
          ),
          SizedBox(width: compact ? 4 : 8),
        ],
        _Brand(
          title: title,
          badge: badge,
          compact: compact,
          fontSize: fontSize,
          showByline: showByline,
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.dateWidth,
    required this.compact,
    required this.showWeekStatus,
    required this.weekStatusPrimary,
    required this.weekStatusSecondary,
    required this.syncFeedback,
    required this.syncWidth,
    required this.onMessages,
    required this.onRefresh,
    required this.isRefreshing,
    required this.unreadCount,
  });

  final bool compact;
  final double dateWidth;
  final bool showWeekStatus;
  final String? weekStatusPrimary;
  final String? weekStatusSecondary;
  final String? syncFeedback;
  final double syncWidth;
  final VoidCallback? onMessages;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncFeedback != null)
          _SyncFeedback(
            text: syncFeedback!,
            compact: compact,
            width: syncWidth,
          ),
        if (showWeekStatus && weekStatusPrimary != null && syncFeedback != null)
          SizedBox(width: compact ? 3 : 8),
        if (showWeekStatus && weekStatusPrimary != null)
          _WeekStatus(
            width: dateWidth,
            primary: weekStatusPrimary!,
            secondary: weekStatusSecondary,
            compact: compact,
          ),
        if ((syncFeedback != null ||
                (showWeekStatus && weekStatusPrimary != null)) &&
            (onMessages != null || onRefresh != null))
          SizedBox(width: compact ? 3 : 8),
        if (onMessages != null)
          _HeaderIconButton(
            icon: const EcjtuIcon(
              'smart_work_notification.svg',
              size: 16,
              color: Colors.white,
            ),
            tooltip: '通讯 (Beta)',
            onPressed: onMessages!,
            badge: unreadCount,
            compact: compact,
          ),
        if (onMessages != null && onRefresh != null)
          SizedBox(width: compact ? 3 : 8),
        if (onRefresh != null)
          _HeaderIconButton(
            icon: const EcjtuIcon(
              'smart_work_refresh.svg',
              size: 16,
              color: Colors.white,
            ),
            tooltip: '获取最新数据',
            onPressed: isRefreshing ? null : onRefresh,
            spinning: isRefreshing,
            compact: compact,
          ),
      ],
    );
  }
}

class _WeekStatus extends StatelessWidget {
  const _WeekStatus({
    required this.width,
    required this.primary,
    this.secondary,
    required this.compact,
  });

  final String primary;
  final double width;
  final String? secondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 48,
      padding: EdgeInsets.only(right: compact ? 6 : 10),
      decoration: BoxDecoration(
        border: EcjtuMetrics.phoneLayout(context)
            ? null
            : const Border(
                right: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.18)),
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            primary,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14 : 18,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          if (secondary != null && secondary!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              secondary!,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Color.fromRGBO(184, 212, 226, 1),
                fontSize: compact ? 10 : 12,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncFeedback extends StatelessWidget {
  const _SyncFeedback({
    required this.text,
    required this.compact,
    required this.width,
  });

  final String text;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text.split('\n').first),
              if (text.contains('\n'))
                TextSpan(
                  text: '\n${text.split('\n').skip(1).join('\n')}',
                  style: TextStyle(
                    fontSize: compact ? 9 : 12,
                    height: compact ? 1 : 1.3,
                    color: compact
                        ? Colors.white.withValues(alpha: .96)
                        : Colors.white,
                  ),
                ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: compact ? Colors.white.withValues(alpha: .92) : Colors.white,
            fontSize: compact ? 10 : 12,
            letterSpacing: 0,
            fontFamily: 'SourceHanSansCN',
            fontWeight: compact ? FontWeight.w700 : FontWeight.w500,
            height: compact ? 1.1 : 1.3,
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.title,
    this.badge = AppEdition.badge,
    required this.compact,
    required this.showByline,
    required this.fontSize,
  });

  final String title;
  final String badge;
  final bool compact;
  final bool showByline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final brandSize = fontSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: compact ? 22 : 28,
          decoration: BoxDecoration(
            color: const Color(0xFF9DDCFF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Text(
          'ECJTU $title',
          textHeightBehavior: const TextHeightBehavior(
            leadingDistribution: TextLeadingDistribution.even,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: Colors.white,
            fontSize: brandSize,
            fontFamily: 'SourceHanSansCN',
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            height: compact ? 15 / 14 : 1.2,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        EcjtuEditionBadge(
          label: badge,
          fontSize: compact ? 7.5 : 10,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 6,
            vertical: compact ? 1 : 2,
          ),
        ),
        if (showByline) ...[
          const SizedBox(width: 8),
          Text(
            'By 阿东Charles',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: compact ? 9 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountBadge extends StatefulWidget {
  const _AccountBadge({
    required this.name,
    this.accountId,
    this.mode,
    required this.compact,
    required this.showAccountId,
    required this.width,
  });
  final String name;
  final String? accountId;
  final String? mode;
  final bool compact;
  final bool showAccountId;
  final double width;
  @override
  State<_AccountBadge> createState() => _AccountBadgeState();
}

class _AccountBadgeState extends State<_AccountBadge>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: EcjtuAnimation.accountCurve,
  );
  late Animation<double> _width = AlwaysStoppedAnimation(widget.width);
  late Animation<double> _detail = AlwaysStoppedAnimation(
    widget.showAccountId ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _AccountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width == widget.width &&
        oldWidget.showAccountId == widget.showAccountId)
      return;
    final fromWidth = _width.value;
    final fromDetail = _detail.value;
    _width = Tween(begin: fromWidth, end: widget.width).animate(_curve);
    _detail = Tween(
      begin: fromDetail,
      end: widget.showAccountId ? 1.0 : 0.0,
    ).animate(_curve);
    _controller.duration = widget.width >= fromWidth
        ? EcjtuAnimation.accountForward
        : EcjtuAnimation.accountBack;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final compact = widget.compact;
        final basePadding = compact ? 8.0 : 10.0;
        final style = TextStyle(
          color: Colors.white,
          fontSize: compact ? 11.5 : 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.25,
        );
        var lineHeight = 0.0;
        double measure(String value) {
          final painter = TextPainter(
            text: TextSpan(
              text: value,
              style: DefaultTextStyle.of(context).style.merge(style),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final width = painter.width;
          lineHeight = painter.height;
          painter.dispose();
          return width;
        }

        final suffix = widget.accountId?.isNotEmpty == true
            ? ' · ${widget.accountId}'
            : '';
        final suffixWidth = measure(suffix);
        final effectiveWidth = math.min(_width.value, constraints.maxWidth);
        final padding = math.min(
          basePadding,
          math.max(0.0, (effectiveWidth - measure(widget.name) - 2) / 2),
        );
        final available = math.max(
          0.0,
          effectiveWidth - padding * 2 - 2 - measure(widget.name),
        );
        final revealWidth = math.min(available, suffixWidth * _detail.value);
        return Container(
          width: _width.value,
          height: compact
              ? math.max(
                  38.0,
                  lineHeight +
                      (widget.mode?.isNotEmpty == true
                          ? MediaQuery.textScalerOf(context).scale(8.5) * 1.25
                          : 0) +
                      8,
                )
              : 50,
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  key: const ValueKey('account-identity'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.name, maxLines: 1, style: style),
                    SizedBox(
                      width: revealWidth,
                      height: lineHeight,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: suffixWidth,
                          maxWidth: suffixWidth,
                          child: Opacity(
                            opacity: _detail.value,
                            child: Text(suffix, maxLines: 1, style: style),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.mode?.isNotEmpty == true)
                  Text(
                    widget.mode!,
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color.fromRGBO(222, 237, 248, .78),
                      fontSize: compact ? 8.5 : 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
    required this.compact,
    this.spinning = false,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final int badge;
  final bool compact;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 24.0 : 34.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: dimension,
          height: dimension,
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            icon: spinning ? _SpinningIcon(child: icon) : icon,
            padding: EdgeInsets.zero,
            splashRadius: dimension / 2,
            style: IconButton.styleFrom(
              minimumSize: Size.square(dimension),
              maximumSize: Size.square(dimension),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
              shape: const CircleBorder(),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF4C9BFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.child});

  final Widget child;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _controller, child: widget.child);
  }
}
