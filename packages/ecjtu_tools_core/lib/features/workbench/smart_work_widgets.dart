// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_glass.dart';
import '../../theme/ecjtu_desktop_tokens.dart';
import '../../theme/ecjtu_control_palette.dart';
import '../../widgets/ecjtu_widgets.dart';
import '../../widgets/ecjtu_desktop_navigation_scope.dart';
import 'smart_work_models.dart';

bool workbenchPhoneLayout(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.android ||
    Theme.of(context).platform == TargetPlatform.iOS;

class SmartWorkCategoryHeading extends StatelessWidget {
  const SmartWorkCategoryHeading(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Text(
      title,
      style: TextStyle(
        color: EcjtuColors.textFrom(
          context,
          EcjtuColors.textFrom(
            context,
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFE1EDFF)
                : EcjtuColors.smartWorkStrongText,
          ),
        ),
        fontSize: workbenchPhoneLayout(context)
            ? EcjtuMetrics.fontBodyFor(MediaQuery.sizeOf(context))
            : EcjtuDesktopType.heading,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    ),
  );
}

double workbenchEntryMaxWidth(BuildContext context) =>
    workbenchPhoneLayout(context) ? 520 : 390;

double workbenchHeaderGap(BuildContext context) =>
    EcjtuMetrics.pageHeaderGapFor(context);

double workbenchEntryGap(BuildContext context) => 12;

List<BoxShadow> physicsCardShadow(bool dark) => [
  BoxShadow(
    color: dark ? const Color(0x26000000) : const Color(0x121A4160),
    blurRadius: 14,
    offset: const Offset(0, 4),
  ),
];

class WorkbenchContentFrame extends StatelessWidget {
  const WorkbenchContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: math.min(1580, constraints.maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class WorkbenchSubpageColumn extends StatelessWidget {
  const WorkbenchSubpageColumn({
    super.key,
    required this.child,
    this.contentMaxWidth = double.infinity,
  });

  final Widget child;
  final double contentMaxWidth;

  @override
  Widget build(BuildContext context) {
    return EcjtuPageColumn(
      child: WorkbenchContentFrame(
        child: LayoutBuilder(
          builder: (context, constraints) => Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: math.min(contentMaxWidth, constraints.maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SmartWorkPageSwitcher extends StatelessWidget {
  const SmartWorkPageSwitcher({
    super.key,
    required this.pageKey,
    required this.child,
  });

  final Key pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: pageKey, child: child);
}

class SmartWorkTileGrid extends StatelessWidget {
  const SmartWorkTileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, bool compact)
  itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final platform = Theme.of(context).platform;
        final mobile =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        final compact = mobile && width < 600;
        const gap = 8.0;
        final minimumWidth = compact ? 100.0 : 150.0;
        final columns = math.max(
          1,
          ((width + gap) / (minimumWidth + gap)).floor(),
        );
        final tileWidth = mobile
            ? (width - (columns - 1) * gap) / columns
            : math.min(158.0, width);
        final children = [
          for (var index = 0; index < itemCount; index++)
            itemBuilder(context, index, compact),
        ];
        var tileHeight = compact ? 74.0 : 82.0;
        for (final child in children.whereType<SmartWorkMenuTile>()) {
          final painter = TextPainter(
            text: TextSpan(
              text: child.title,
              style: DefaultTextStyle.of(context).style.merge(
                TextStyle(
                  fontSize: EcjtuMetrics.fontBodyFor(
                    MediaQuery.sizeOf(context),
                  ),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: math.max(1, tileWidth - 18));
          tileHeight = math.max(
            tileHeight,
            painter.height + 31 + (compact ? 18 : 22),
          );
          painter.dispose();
        }
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < itemCount; index++)
              SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: children[index],
              ),
          ],
        );
      },
    );
  }
}

class SmartWorkMenuTile extends StatefulWidget {
  const SmartWorkMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.compact = false,
    this.selected = false,
  });

  final String title;
  final String icon;
  final VoidCallback onPressed;
  final bool compact;
  final bool selected;

  @override
  State<SmartWorkMenuTile> createState() => _SmartWorkMenuTileState();
}

class _SmartWorkMenuTileState extends State<SmartWorkMenuTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mobile = workbenchPhoneLayout(context);
    final colors = EcjtuGlass.of(context);
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Container(
            constraints: BoxConstraints(minHeight: widget.compact ? 74 : 82),
            padding: EdgeInsets.fromLTRB(
              8,
              widget.compact ? 10 : 12,
              8,
              widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colors.selected
                  : mobile
                  ? (_hovered ? colors.hover : colors.card)
                  : _hovered
                  ? (EcjtuColors.hoverFrom(
                      context,
                      (dark
                          ? const Color(0xFF172B42)
                          : const Color(0xFFEEF7FC)),
                    ))
                  : EcjtuColors.surfaceFrom(
                      context,
                      (EcjtuColors.surfaceFrom(
                        context,
                        dark
                            ? const Color(0xFF101D31)
                            : EcjtuColors.smartWorkSurface,
                      )),
                    ),
              border: Border.all(
                color: mobile && widget.selected
                    ? colors.accent
                    : EcjtuColors.borderFrom(
                        context,
                        (_hovered
                            ? (dark
                                  ? const Color(0xFF5085A3)
                                  : const Color(0xFF8DB7D0))
                            : (EcjtuColors.borderFrom(
                                context,
                                dark
                                    ? const Color(0xFF31546B)
                                    : EcjtuColors.smartWorkBorder,
                              ))),
                      ),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EcjtuIcon(
                  widget.icon,
                  size: 28,
                  color:
                      EcjtuControlPalette.maybeOf(context)?.focus ??
                      (dark
                          ? const Color(0xFF77BCEB)
                          : EcjtuColors.smartWorkIcon),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EcjtuColors.textFrom(
                      context,
                      (dark
                          ? const Color(0xFFD6E6F3)
                          : EcjtuColors.smartWorkCardText),
                    ),
                    fontSize: EcjtuMetrics.fontBodyFor(size),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class SmartWorkInlineMessage extends StatelessWidget {
  const SmartWorkInlineMessage({
    super.key,
    required this.message,
    this.error = false,
  });

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final border = error
        ? (dark ? const Color(0xFF73484C) : const Color(0xFFE8C8C8))
        : (EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF31546B) : EcjtuColors.smartWorkBorder,
          ));
    final background = error
        ? (dark ? const Color(0xFF291C28) : const Color(0xFFFFF7F7))
        : (EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF101D31) : EcjtuColors.smartWorkSurface,
          ));
    final foreground = error
        ? (dark ? const Color(0xFFFFB7B7) : const Color(0xFF9C3D3D))
        : (EcjtuColors.mutedFrom(
            context,
            dark ? EcjtuColors.darkTextSecondary : const Color(0xFF667B8E),
          ));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontSize: error
              ? EcjtuMetrics.fontCaptionFor(size)
              : EcjtuMetrics.fontSmallFor(size),
          height: 1.45,
        ),
      ),
    );
  }
}

class SmartWorkPersonalNote extends StatelessWidget {
  const SmartWorkPersonalNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: EcjtuColors.surfaceFrom(
            context,
            (EcjtuColors.surfaceFrom(
              context,
              dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD),
            )),
          ),
          border: Border(
            top: BorderSide(
              color: EcjtuColors.borderFrom(
                context,
                (EcjtuColors.borderFrom(
                  context,
                  dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
                )),
              ),
            ),
            right: BorderSide(
              color: EcjtuColors.borderFrom(
                context,
                (EcjtuColors.borderFrom(
                  context,
                  dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
                )),
              ),
            ),
            bottom: BorderSide(
              color: EcjtuColors.borderFrom(
                context,
                (EcjtuColors.borderFrom(
                  context,
                  dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
                )),
              ),
            ),
            left: BorderSide(
              color: dark ? const Color(0xFF61ADFF) : const Color(0xFF3F82A6),
              width: 3,
            ),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: EcjtuColors.mutedFrom(
              context,
              (EcjtuColors.mutedFrom(
                context,
                dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E),
              )),
            ),
            fontSize: EcjtuMetrics.fontBodyFor(size),
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class SmartWorkGenericEmpty extends StatelessWidget {
  const SmartWorkGenericEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: EcjtuColors.mutedFrom(
            context,
            (EcjtuColors.mutedFrom(
              context,
              dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E),
            )),
          ),
          fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
          height: 1.4,
        ),
      ),
    );
  }
}

class SmartWorkLoading extends StatelessWidget {
  const SmartWorkLoading({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
      child: Center(
        child: SmartWorkLoadingText(
          message: message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SmartWorkLoadingText extends StatelessWidget {
  const SmartWorkLoadingText({
    super.key,
    required this.message,
    this.textKey,
    this.textAlign,
    this.maxLines,
  });
  final String message;
  final Key? textKey;
  final TextAlign? textAlign;
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      message,
      key: textKey,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        color: EcjtuColors.mutedFrom(
          context,
          dark ? const Color(0xFF9EACC3) : const Color(0xFF7B8492),
        ),
        fontSize: EcjtuMetrics.fontBodyFor(MediaQuery.sizeOf(context)),
        height: 1.4,
      ),
    );
  }
}

class SmartWorkUpdatedLabel extends StatelessWidget {
  const SmartWorkUpdatedLabel({super.key, this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    if (updatedAt == null) return const SizedBox.shrink();
    final value = updatedAt!.toLocal();
    final text =
        '本地更新：${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)} '
        '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: TextStyle(
          color: EcjtuColors.mutedFrom(
            context,
            dark ? const Color(0xFF91A7BA) : const Color(0xFF7B91A2),
          ),
          fontSize: EcjtuMetrics.fontCaptionFor(MediaQuery.sizeOf(context)),
          height: 1.4,
        ),
      ),
    );
  }
}

class SmartWorkSessionStatus extends StatelessWidget {
  const SmartWorkSessionStatus({
    super.key,
    required this.authenticated,
    this.pending = false,
    this.title,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final bool authenticated;
  final bool pending;
  final String? title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final titleColor = authenticated
        ? (dark ? const Color(0xFF71E0AA) : const Color(0xFF18794E))
        : (EcjtuColors.textFrom(
            context,
            dark ? const Color(0xFFE1EDFF) : const Color(0xFF29445D),
          ));
    final markColor = authenticated
        ? (dark ? const Color(0xFF55C894) : const Color(0xFF31966B))
        : (EcjtuColors.mutedFrom(
            context,
            dark ? const Color(0xFFAEBDD2) : const Color(0xFF8AA9BD),
          ));
    final borderColor = EcjtuColors.borderFrom(
      context,
      (EcjtuColors.borderFrom(
        context,
        dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
      )),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              top: authenticated ? 14 : 18,
              bottom: authenticated ? 10 : 14,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: authenticated ? 12 : 14,
              vertical: authenticated ? 9 : 12,
            ),
            decoration: BoxDecoration(
              color: EcjtuColors.surfaceFrom(
                context,
                (EcjtuColors.surfaceFrom(
                  context,
                  dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD),
                )),
              ),
              border: Border(
                top: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
                left: BorderSide(color: markColor, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: authenticated ? 21 : 25,
                  height: authenticated ? 21 : 25,
                  child: Center(
                    child: authenticated
                        ? ClipRect(
                            child: SizedBox(
                              width: 19,
                              height: 19,
                              child: OverflowBox(
                                maxWidth: 28,
                                maxHeight: 28,
                                minWidth: 28,
                                minHeight: 28,
                                alignment: Alignment.center,
                                child: EcjtuIcon(
                                  'smart_work_status.svg',
                                  size: 28,
                                  color: markColor,
                                ),
                              ),
                            ),
                          )
                        : EcjtuIcon(
                            'smart_work_status.svg',
                            size: 23,
                            color: markColor,
                          ),
                  ),
                ),
                SizedBox(width: authenticated ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? (authenticated ? '智慧学工会话可用' : '未确认登录状态'),
                        style: TextStyle(
                          color: titleColor,
                          fontSize: EcjtuMetrics.fontBodyFor(size),
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if ((detail ?? '').isNotEmpty || !authenticated)
                        Text(
                          detail ?? '可先查看本地保存的学工信息，有网络后可重新登录',
                          style: TextStyle(
                            color: EcjtuColors.mutedFrom(
                              context,
                              (EcjtuColors.mutedFrom(
                                context,
                                dark
                                    ? const Color(0xFF9EACC3)
                                    : const Color(0xFF667B8E),
                              )),
                            ),
                            fontSize: EcjtuMetrics.fontCaptionFor(size),
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: pending ? null : onAction,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: EcjtuColors.textFrom(
                        context,
                        dark
                            ? const Color(0xFFB7D9ED)
                            : const Color(0xFF275B7A),
                      ),
                    ),
                    child: Text(pending ? '正在登录' : actionLabel!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SmartWorkDetailHeading extends StatelessWidget {
  const SmartWorkDetailHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark
                          ? EcjtuColors.darkTextPrimary
                          : const Color(0xFF263E53),
                      fontSize: EcjtuMetrics.fontBodyFor(size),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark
                            ? EcjtuColors.darkTextSecondary
                            : const Color(0xFF667B8E),
                        fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SmartWorkPageHeader extends StatelessWidget {
  const SmartWorkPageHeader({
    super.key,
    required this.title,
    required this.backTitle,
    required this.onBack,
    this.trailing,
    this.inlineTrailing,
  });

  final String title;
  final String backTitle;
  final VoidCallback onBack;

  /// Optional extra control (e.g. a search button) shown before the back
  /// button in the header row.
  final Widget? trailing;
  final Widget? inlineTrailing;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hideBack =
        EcjtuDesktopNavigationScope.secondaryOf(context) &&
        const {
          '返回工作台',
          '返回智慧学工',
          '返回教务工具',
          '返回增强插件',
          '返回物理实验',
        }.contains(backTitle);
    final backButton = hideBack
        ? const SizedBox.shrink()
        : SmartWorkHeaderAction(label: backTitle, onPressed: onBack);

    return SizedBox(
      height: EcjtuMetrics.pageHeaderHeightFor(context),
      child: inlineTrailing != null && trailing != null
          ? Row(
              children: [
                Expanded(child: EcjtuSectionTitle(title, lineHeight: 1.15)),
                const SizedBox(width: 8),
                trailing!,
                const SizedBox(width: 8),
                SizedBox(
                  width: math.min(340, size.width * .32),
                  child: inlineTrailing!,
                ),
                const SizedBox(width: 8),
                backButton,
              ],
            )
          : EcjtuSectionTitle(
              title,
              lineHeight: 1.15,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  backButton,
                ],
              ),
            ),
    );
  }
}

class SmartWorkHeaderAction extends StatelessWidget {
  const SmartWorkHeaderAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  static ButtonStyle styleFor(BuildContext context) =>
      EcjtuBackAction.styleFor(context);

  @override
  Widget build(BuildContext context) =>
      EcjtuBackAction(label: label, onPressed: onPressed);
}

class SmartWorkStudentSection extends StatelessWidget {
  const SmartWorkStudentSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          (EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD),
          )),
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            (EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF),
            )),
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: EcjtuColors.borderFrom(
                    context,
                    dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
                  ),
                ),
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: EcjtuColors.textFrom(
                        context,
                        dark
                            ? const Color(0xFFE1EDFF)
                            : const Color(0xFF263E53),
                      ),
                      fontSize: EcjtuMetrics.fontBodyFor(size),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: EcjtuColors.mutedFrom(
                          context,
                          (EcjtuColors.mutedFrom(
                            context,
                            dark
                                ? const Color(0xFF9EACC3)
                                : const Color(0xFF667B8E),
                          )),
                        ),
                        fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(width: 12), action!],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class SmartWorkVisibilityButton extends StatelessWidget {
  const SmartWorkVisibilityButton({
    super.key,
    required this.visible,
    required this.onPressed,
    required this.label,
  });

  final bool visible;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: visible ? '隐藏$label' : '显示$label',
      child: Tooltip(
        message: visible ? '隐藏$label' : '显示$label',
        child: SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            splashRadius: 16,
            icon: EcjtuVisibilityGlyph(
              visible: visible,
              size: 17,
              color: dark ? const Color(0xFFA7C4D8) : const Color(0xFF50728A),
            ),
            color: dark ? const Color(0xFFA7C4D8) : const Color(0xFF50728A),
            hoverColor: EcjtuColors.surfaceFrom(
              context,
              dark ? const Color(0xFF1A324C) : const Color(0xFFE5F2FA),
            ),
          ),
        ),
      ),
    );
  }
}

class SmartWorkProfileCard extends StatelessWidget {
  const SmartWorkProfileCard({
    super.key,
    required this.profile,
    required this.identityVisible,
    required this.onToggleIdentity,
    this.onAvatarPressed,
  });

  final SmartWorkStudentProfile profile;
  final bool identityVisible;
  final VoidCallback onToggleIdentity;
  final VoidCallback? onAvatarPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final avatarSource = profile.avatar.trim().isNotEmpty
        ? profile.avatar.trim()
        : profile.avatarUrl.trim();
    final rows = <(String, String)>[
      ('学号', profile.studentId),
      ('姓名', profile.name),
      ('性别', profile.sex),
      ('民族', profile.nation),
      ('籍贯', profile.nativePlace),
      ('政治面貌', profile.politicalStatus),
      ('出生日期', profile.birthday),
      ('身份状态', profile.enrollmentStatus),
      ('入学类别', profile.admissionType),
      ('培养层次', profile.educationLevel),
      ('考生号', profile.candidateNumber),
      ('生源地', profile.sourcePlace),
      ('学习年限', profile.studyYears),
      ('学籍备注', profile.enrollmentNote),
      ('联系电话', profile.phone),
      ('电子邮箱', profile.email),
      ('QQ号码', profile.qq),
      ('紧急联系号码', profile.emergencyPhone),
      ('家庭联系号码', profile.familyPhone),
      ('邮政编码', profile.postcode),
      ('家庭住址', profile.address),
      ('户籍地址', profile.householdAddress),
      ('毕业中学', profile.graduationSchool),
      ('宗教信仰', profile.religiousBelief),
    ].where((row) => row.$2.trim().isNotEmpty).toList(growable: false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF101D31) : EcjtuColors.smartWorkSurface,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF31546B) : EcjtuColors.smartWorkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (avatarSource.isNotEmpty)
            _ProfileIdentity(
              profile: profile,
              source: avatarSource,
              dark: dark,
              onAvatarPressed: onAvatarPressed,
            ),
          for (final row in rows)
            SmartWorkProfileRow(label: row.$1, value: row.$2),
          if (profile.identityNumber.isNotEmpty)
            SmartWorkProfileRow(
              label: '身份证号',
              value: identityVisible
                  ? profile.identityNumber
                  : _maskIdentity(profile.identityNumber),
              action: SmartWorkVisibilityButton(
                visible: identityVisible,
                onPressed: onToggleIdentity,
                label: '身份证号',
              ),
            ),
        ],
      ),
    );
  }
}

class SmartWorkProfileRow extends StatelessWidget {
  const SmartWorkProfileRow({
    super.key,
    required this.label,
    required this.value,
    this.action,
  });

  final String label;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
            ),
          ),
        ),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 42,
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 84),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: dark
                          ? EcjtuColors.darkTextSecondary
                          : const Color(0xFF667B8E),
                      fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 100,
                child: Padding(
                  padding: EdgeInsets.only(right: action == null ? 0 : 34),
                  child: Text(
                    value,
                    softWrap: true,
                    style: TextStyle(
                      color: dark
                          ? EcjtuColors.darkTextPrimary
                          : const Color(0xFF263E53),
                      fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (action != null) Positioned(top: 0, right: 0, child: action!),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.profile,
    required this.source,
    required this.dark,
    this.onAvatarPressed,
  });

  final SmartWorkStudentProfile profile;
  final String source;
  final bool dark;
  final VoidCallback? onAvatarPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: onAvatarPressed == null ? '' : '查看完整照片',
            child: Semantics(
              button: onAvatarPressed != null,
              label: onAvatarPressed == null ? '学籍照片' : '查看完整照片',
              child: GestureDetector(
                onTap: onAvatarPressed,
                child: _SmartWorkAvatar(source: source),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              profile.name.isEmpty ? profile.studentId : profile.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark
                    ? EcjtuColors.darkTextPrimary
                    : const Color(0xFF263E53),
                fontSize: EcjtuMetrics.fontBodyFor(size),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartWorkAvatar extends StatelessWidget {
  const _SmartWorkAvatar({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2F8),
        border: Border.all(color: const Color(0xFFC4D9E9)),
        shape: BoxShape.circle,
      ),
      child: SmartWorkAvatarImage(
        source: source,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

class SmartWorkAvatarImage extends StatelessWidget {
  const SmartWorkAvatarImage({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String source;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:')) {
      final comma = source.indexOf(',');
      if (comma <= 0) return const SizedBox.shrink();
      try {
        return Image.memory(
          Uint8List.fromList(base64Decode(source.substring(comma + 1))),
          fit: fit,
          alignment: alignment,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.network(
      source,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

class SmartWorkAvatarDialog extends StatelessWidget {
  const SmartWorkAvatarDialog({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final maxWidth = math.min(size.width * .82, 390.0);
    final maxHeight = math.min(size.height * .78, 480.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: maxWidth,
        height: maxHeight,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EcjtuColors.surfaceFrom(
            context,
            (EcjtuColors.surfaceFrom(
              context,
              dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD),
            )),
          ),
          border: Border.all(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF395D7C) : const Color(0xFF5D7F98),
            ),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: '关闭',
              ),
            ),
            Expanded(
              child: Center(child: SmartWorkAvatarImage(source: source)),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartWorkRecordTable extends StatelessWidget {
  const SmartWorkRecordTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyLabel = '暂无记录',
    this.studentTable = false,
    this.embedded = false,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final String emptyLabel;
  final bool studentTable;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return SmartWorkInlineMessage(message: emptyLabel);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620 && studentTable) {
          return _CompactStudentTable(
            columns: columns,
            rows: rows,
            embedded: embedded,
          );
        }
        return _WideRecordTable(
          columns: columns,
          rows: rows,
          embedded: embedded,
        );
      },
    );
  }
}

class _WideRecordTable extends StatelessWidget {
  const _WideRecordTable({
    required this.columns,
    required this.rows,
    required this.embedded,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumWidth = columns.length * 130.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minimumWidth;
        final tableWidth = availableWidth > minimumWidth
            ? availableWidth
            : minimumWidth;
        final content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              defaultColumnWidth: const FlexColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: EcjtuColors.borderFrom(
                    context,
                    EcjtuColors.borderFrom(
                      context,
                      dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
                    ),
                  ),
                ),
              ),
              children: [
                _recordTableRow(context, columns, header: true, dark: dark),
                if (rows.isEmpty)
                  _recordTableRow(
                    context,
                    List<String>.filled(columns.length, '无'),
                    header: false,
                    dark: dark,
                  )
                else
                  for (final row in rows)
                    _recordTableRow(context, row, header: false, dark: dark),
              ],
            ),
          ),
        );
        if (embedded) return content;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: EcjtuColors.surfaceFrom(
              context,
              EcjtuColors.surfaceFrom(
                context,
                dark ? const Color(0xFF101D31) : EcjtuColors.smartWorkSurface,
              ),
            ),
            border: Border.all(
              color: EcjtuColors.borderFrom(
                context,
                EcjtuColors.borderFrom(
                  context,
                  dark ? const Color(0xFF31546B) : EcjtuColors.smartWorkBorder,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        );
      },
    );
  }
}

TableRow _recordTableRow(
  BuildContext context,
  List<String> values, {
  required bool header,
  required bool dark,
}) => TableRow(
  decoration: header
      ? BoxDecoration(
          color:
              EcjtuControlPalette.maybeOf(context)?.subtle ??
              (EcjtuColors.surfaceFrom(
                context,
                dark ? const Color(0xFF172B42) : const Color(0xFFEEF6FB),
              )),
        )
      : null,
  children: [
    for (final value in values)
      Builder(
        builder: (context) => Container(
          constraints: const BoxConstraints(minHeight: 42),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            value.isEmpty ? '无' : value,
            softWrap: true,
            style: TextStyle(
              color: EcjtuColors.textFrom(
                context,
                header
                    ? (dark ? const Color(0xFFA7C4D8) : const Color(0xFF4F6D82))
                    : (dark
                          ? EcjtuColors.darkTextPrimary
                          : const Color(0xFF263E53)),
              ),
              fontSize: EcjtuMetrics.fontSmallFor(MediaQuery.sizeOf(context)),
              fontWeight: header ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
          ),
        ),
      ),
  ],
);

class _CompactStudentTable extends StatelessWidget {
  const _CompactStudentTable({
    required this.columns,
    required this.rows,
    required this.embedded,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final displayRows = rows.isEmpty
        ? <List<String>>[List<String>.filled(columns.length, '无')]
        : rows;
    final content = Column(
      children: [
        for (final row in displayRows)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: EcjtuColors.borderFrom(
                    context,
                    dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
                  ),
                ),
              ),
            ),
            child: GridView.builder(
              itemCount: columns.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 54,
              ),
              itemBuilder: (context, index) {
                final value = index < row.length && row[index].isNotEmpty
                    ? row[index]
                    : '无';
                return Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        columns[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: EcjtuColors.mutedFrom(
                            context,
                            (EcjtuColors.mutedFrom(
                              context,
                              dark
                                  ? const Color(0xFF9EACC3)
                                  : const Color(0xFF667B8E),
                            )),
                          ),
                          fontSize: EcjtuMetrics.fontCaptionFor(size),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: EcjtuColors.textFrom(
                            context,
                            dark
                                ? const Color(0xFFE1EDFF)
                                : const Color(0xFF263E53),
                          ),
                          fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
    if (embedded) return content;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF101D31) : EcjtuColors.smartWorkSurface,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF31546B) : EcjtuColors.smartWorkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: content,
    );
  }
}

class SmartWorkDormitoryGrid extends StatelessWidget {
  const SmartWorkDormitoryGrid({super.key, required this.members});

  final List<SmartWorkDormitoryMember> members;

  @override
  Widget build(BuildContext context) {
    final gap = 10.0;
    const minimumCardWidth = 235.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = ((constraints.maxWidth + gap) / (minimumCardWidth + gap))
            .floor();
        if (columns < 1) columns = 1;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final member in members)
              SizedBox(
                width: cardWidth,
                child: SmartWorkDormitoryCard(member: member),
              ),
          ],
        );
      },
    );
  }
}

class SmartWorkDormitoryCard extends StatelessWidget {
  const SmartWorkDormitoryCard({super.key, required this.member});

  final SmartWorkDormitoryMember member;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Container(
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF101D31) : EcjtuColors.smartWorkSurface,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF31546B) : EcjtuColors.smartWorkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            color: Color.alphaBlend(
              Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: dark ? .14 : .06),
              dark ? const Color(0xFF242424) : Colors.white,
            ),
            child: Text(
              '${member.name.isEmpty ? '无' : member.name} · ${member.bed.isEmpty ? '无' : member.bed}',
              softWrap: true,
              style: TextStyle(
                color: EcjtuColors.textFor(context),
                fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          _DormitoryField(label: '学号', value: _display(member.studentId)),
          _DormitoryField(label: '学院', value: _display(member.college)),
          _DormitoryField(label: '班级', value: _display(member.className)),
        ],
      ),
    );
  }
}

class _DormitoryField extends StatelessWidget {
  const _DormitoryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: TextStyle(
                color: EcjtuColors.mutedFrom(
                  context,
                  (EcjtuColors.mutedFrom(
                    context,
                    dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E),
                  )),
                ),
                fontSize: EcjtuMetrics.fontCaptionFor(size),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: TextStyle(
                color: EcjtuColors.textFrom(
                  context,
                  dark ? const Color(0xFFE1EDFF) : const Color(0xFF263E53),
                ),
                fontSize: EcjtuMetrics.isCompact(size) ? 13 : 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartWorkRecordCardHeading extends StatelessWidget {
  const _SmartWorkRecordCardHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = EcjtuMetrics.fontBodyFor(MediaQuery.sizeOf(context));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF28465C) : const Color(0xFFDCEAF2),
            ),
          ),
        ),
      ),
      child: Text(
        title,
        softWrap: true,
        style: TextStyle(
          color: EcjtuColors.textFrom(
            context,
            dark ? const Color(0xFFE1EDFF) : const Color(0xFF263E53),
          ),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class SmartWorkSportCard extends StatelessWidget {
  const SmartWorkSportCard({super.key, required this.grade});

  final SmartWorkSportGrade grade;

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      ('总分', grade.totalScore),
      ('缓测分', grade.deferredScore),
      ('补测分', grade.retestScore),
      ('更正分', grade.correctionScore),
      ('奖励分', grade.rewardScore),
    ];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF101D31)
              : EcjtuColors.smartWorkSurface,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF31546B)
                : EcjtuColors.smartWorkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SmartWorkRecordCardHeading(
            title: grade.term.isEmpty ? '未知学年' : grade.term,
          ),
          for (final field in fields)
            SmartWorkProfileRow(label: field.$1, value: _display(field.$2)),
        ],
      ),
    );
  }
}

class SmartWorkEvaluationCard extends StatelessWidget {
  const SmartWorkEvaluationCard({super.key, required this.evaluation});

  final SmartWorkEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF101D31)
              : EcjtuColors.smartWorkSurface,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF31546B)
                : EcjtuColors.smartWorkBorder,
          ),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _SmartWorkRecordCardHeading(
            title: evaluation.batchName.isEmpty ? '未知批次' : evaluation.batchName,
          ),
          SmartWorkProfileRow(label: 'F', value: _display(evaluation.score)),
          SmartWorkProfileRow(
            label: '奖学金',
            value: _display(evaluation.scholarship),
          ),
        ],
      ),
    );
  }
}

String _display(String value) => value.trim().isEmpty ? '无' : value;

String _maskIdentity(String value) {
  final text = value.trim();
  if (text.length <= 4) return '*' * text.length;
  return '${text.substring(0, 2)}${'*' * (text.length - 4)}${text.substring(text.length - 2)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class SmartWorkUnreadBadge extends StatelessWidget {
  const SmartWorkUnreadBadge({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count 条未读消息',
    child: IgnorePointer(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
