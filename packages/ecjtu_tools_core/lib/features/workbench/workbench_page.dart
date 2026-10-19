// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../../data/app_models.dart';
import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_control_palette.dart';
import '../../widgets/ecjtu_widgets.dart';
import 'smart_work_widgets.dart';

enum WorkbenchDestination {
  smartWork,
  physics,
  enhancements,
  mobileApplications,
  noticesAndCalendar,
}

class WorkbenchEntry {
  const WorkbenchEntry({
    required this.destination,
    required this.title,
    required this.detail,
    required this.icon,
  });

  final WorkbenchDestination destination;
  final String title;
  final String detail;
  final String icon;
}

class WorkbenchCatalog {
  const WorkbenchCatalog._();

  static const _fixedEntries = [
    WorkbenchEntry(
      destination: WorkbenchDestination.smartWork,
      title: '智慧学工',
      detail: '学籍、体测、综测与学工服务',
      icon: 'smart_work_grid.svg',
    ),
    WorkbenchEntry(
      destination: WorkbenchDestination.physics,
      title: '物理实验',
      detail: '实验平台与数据处理计算',
      icon: 'smart_work_physics.svg',
    ),
    WorkbenchEntry(
      destination: WorkbenchDestination.enhancements,
      title: '增强插件',
      detail: '学生互评、请假填写等辅助功能',
      icon: 'smart_work_enhance.svg',
    ),
  ];

  static const _mobileEntries = [
    WorkbenchEntry(
      destination: WorkbenchDestination.mobileApplications,
      title: '移动应用',
      detail: '官方手机端特有的电表、门禁、邮箱等服务',
      icon: 'smart_work_mobile_phone.svg',
    ),
  ];

  static const _noticeEntries = [
    WorkbenchEntry(
      destination: WorkbenchDestination.noticesAndCalendar,
      title: '通知与校历',
      detail: '校内通知与学年校历',
      icon: 'smart_work_notification.svg',
    ),
  ];

  static List<WorkbenchEntry> forAuthMode(AuthMode? authMode) {
    final effectiveAuthMode = authMode ?? AuthMode.cas;
    return [
      ..._fixedEntries,
      if (effectiveAuthMode == AuthMode.mobile) ..._mobileEntries,
      if (effectiveAuthMode != AuthMode.jwxt) ..._noticeEntries,
    ];
  }
}

class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({
    super.key,
    required this.visible,
    this.authMode,
    this.onOpen,
    this.onSearch,
    this.onCommunications,
    this.onSchoolCalendar,
  });

  final bool visible;
  final AuthMode? authMode;
  final ValueChanged<WorkbenchDestination>? onOpen;
  final VoidCallback? onSearch;
  final VoidCallback? onCommunications;
  final VoidCallback? onSchoolCalendar;

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  @override
  Widget build(BuildContext context) {
    final entries = WorkbenchCatalog.forAuthMode(widget.authMode);
    final mobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    return EcjtuPageColumn(
      child: WorkbenchContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: EcjtuMetrics.pageHeaderHeightFor(context),
              child: EcjtuSectionTitle(
                '工作台',
                lineHeight: 1.15,
                action: WorkbenchSearchButton(onPressed: widget.onSearch),
              ),
            ),
            SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
            Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: mobile ? double.infinity : 390,
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < entries.length; index++) ...[
                      EcjtuEntryCard(
                        icon: entries[index].icon,
                        title:
                            mobile &&
                                entries[index].destination ==
                                    WorkbenchDestination.noticesAndCalendar
                            ? '通知'
                            : entries[index].title,
                        detail: '',
                        onPressed: widget.onOpen == null
                            ? null
                            : () => widget.onOpen!(entries[index].destination),
                      ),
                      if (index < entries.length - 1)
                        const SizedBox(height: 12),
                      if (mobile &&
                          entries[index].destination ==
                              WorkbenchDestination.noticesAndCalendar) ...[
                        const SizedBox(height: 12),
                        EcjtuEntryCard(
                          icon: 'school_calendar.svg',
                          title: '校历',
                          detail: '',
                          onPressed: widget.onSchoolCalendar,
                        ),
                      ],
                    ],
                    if (widget.onCommunications != null) ...[
                      const SizedBox(height: 12),
                      EcjtuEntryCard(
                        icon: 'communication.svg',
                        title: '通讯',
                        detail: '',
                        onPressed: widget.onCommunications,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkbenchSearchButton extends StatelessWidget {
  const WorkbenchSearchButton({
    super.key,
    required this.onPressed,
    this.tooltip = '搜索工作台',
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    final normalBackground =
        palette?.surface ??
        (EcjtuColors.surfaceFrom(
          context,
          (dark ? const Color(0xFF16263D) : const Color(0xFFF2F8FC)),
        ));
    final hoverBackground =
        palette?.hover ??
        (EcjtuColors.hoverFrom(
          context,
          (dark ? const Color(0xFF1B3553) : const Color(0xFFE4F1F8)),
        ));
    final normalBorder =
        palette?.border ??
        (EcjtuColors.borderFrom(
          context,
          (dark ? const Color(0xFF3B5878) : const Color(0xFFA9C9DC)),
        ));
    final hoverBorder =
        palette?.focus ??
        (dark ? const Color(0xFF5CA7E8) : const Color(0xFF287AA8));
    final foreground =
        palette?.foreground ??
        (EcjtuColors.textFrom(
          context,
          dark ? const Color(0xFFD9EBFF) : const Color(0xFF275B7A),
        ));
    if (expanded) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: palette?.subtle ?? normalBackground,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  EcjtuIcon(
                    'smart_work_search.svg',
                    size: 17,
                    color: palette?.muted ?? foreground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '搜索',
                    style: TextStyle(
                      fontSize: 15,
                      color: palette?.muted ?? foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: EcjtuIcon(
          'smart_work_search.svg',
          size: 16,
          color:
              palette?.foreground ??
              (dark
                  ? EcjtuColors.darkSmartWorkSearchText
                  : EcjtuColors.smartWorkSecondaryText),
        ),
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size(34, 34)),
          minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: WidgetStatePropertyAll(foreground),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? hoverBackground
                : normalBackground,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered)
                  ? hoverBorder
                  : normalBorder,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
