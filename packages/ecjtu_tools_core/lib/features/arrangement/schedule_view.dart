// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'arrangement_controls.dart';
import 'dart:ui' show PointerDeviceKind;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_control_palette.dart';
import 'arrangement_models.dart';
import 'arrangement_visuals.dart';
import 'small_class_models.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({
    super.key,
    required this.records,
    required this.term,
    required this.week,
    required this.day,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
    this.onRequestSync,
    this.compactOverride,
    this.onViewDetails,
  });

  final List<ScheduleRecord> records;
  final String? term;
  final int? week;
  final int day;
  final bool showHours;
  final bool showCredit;
  final bool showSmallClass;
  final VoidCallback? onRequestSync;
  final bool? compactOverride;
  final ValueChanged<ScheduleRecord>? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final filtered = records
        .where(
          (record) =>
              (term == null || record.term == term) &&
              !record.noScheduledTime &&
              record.occursInWeek(week),
        )
        .toList();
    if (compactOverride ?? EcjtuMetrics.isCompact(MediaQuery.sizeOf(context))) {
      return _ScheduleDetailsScope(
        callback: onViewDetails,
        child: _CompactSchedule(
          records: filtered,
          day: day,
          showHours: showHours,
          showCredit: showCredit,
          showSmallClass: showSmallClass,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = EcjtuMetrics.phoneLayout(context) ? .82 : 1.0;
        final child = _ScheduleDetailsScope(
          callback: onViewDetails,
          child: _FullSchedule(
            records: filtered,
            showHours: showHours,
            showCredit: showCredit,
            showSmallClass: showSmallClass,
          ),
        );
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: constraints.maxWidth,
            child: FittedBox(
              alignment: Alignment.topLeft,
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: constraints.maxWidth / scale,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleDetailsScope extends InheritedWidget {
  const _ScheduleDetailsScope({required this.callback, required super.child});
  final ValueChanged<ScheduleRecord>? callback;
  static ValueChanged<ScheduleRecord>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ScheduleDetailsScope>()
      ?.callback;
  @override
  bool updateShouldNotify(_ScheduleDetailsScope oldWidget) =>
      callback != oldWidget.callback;
}

class _CompactSchedule extends StatelessWidget {
  const _CompactSchedule({
    required this.records,
    required this.day,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
  });
  final List<ScheduleRecord> records;
  final int day;
  final bool showHours, showCredit, showSmallClass;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final grouped = _groupRecords(records);
      final compact =
          EcjtuMetrics.phoneLayout(context) ||
          EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
      final hasDetails = _ScheduleDetailsScope.of(context) != null;
      final width = math.max(1.0, constraints.maxWidth - 46 - 32);
      double measure(String text, TextStyle style, double available) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: math.max(1, available));
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final heights = <String, double>{};
      for (final record in grouped) {
        final title = measure(
          record.courseName,
          _courseTitle(context, compact ? 14 : 15),
          width - (hasDetails ? 106 : 0),
        );
        final details = _compactDetails(record);
        final detailHeight = details.isEmpty
            ? 0.0
            : 5 +
                  measure(
                    details,
                    _courseDetail(context, compact ? 11 : 14),
                    width,
                  );
        final supplement = _compactSupplement(
          record,
          showHours,
          showCredit,
          showSmallClass,
        );
        final extraHeight = supplement.isEmpty
            ? 0.0
            : 6 +
                  measure(
                    supplement,
                    _courseDetail(context, compact ? 11 : 14),
                    width,
                  );
        final height =
            32 +
            math.max(title, hasDetails ? 32.0 : 0.0) +
            detailHeight +
            extraHeight;
        final slot = '${record.weekday}|${(record.sectionStart - 1) ~/ 2}';
        heights[slot] =
            (heights[slot] ?? 0) + math.max(58, height).ceilToDouble() + 7;
      }
      // Measure the whole week so changing the selected day never shifts a slot.
      final slotHeight = heights.values.fold<double>(
        66,
        (height, value) => math.max(height, value - 7),
      );
      final last = grouped.any((record) => record.sectionStart > 10) ? 12 : 10;
      return Column(
        children: [
          for (var start = 1; start <= last; start += 2) ...[
            _PeriodSlot(
              start: start,
              end: start + 1,
              height: slotHeight,
              showHours: showHours,
              showCredit: showCredit,
              showSmallClass: showSmallClass,
              records: grouped
                  .where(
                    (record) =>
                        record.weekday == day + 1 &&
                        record.sectionStart >= start &&
                        record.sectionStart <= start + 1,
                  )
                  .toList(),
            ),
            if (start < last - 1) const SizedBox(height: 7),
          ],
        ],
      );
    },
  );
}

String _compactDetails(ScheduleRecord record) => [
  if (record.needsSectionLabel) '${record.sectionLabel}节',
  record.classroom,
  record.teacher,
  record.compactWeekRange,
].where((value) => value.isNotEmpty).join(' · ');

String _compactSupplement(
  ScheduleRecord record,
  bool hours,
  bool credit,
  bool smallClass,
) => [
  if (hours && (record.hours ?? 0) > 0) '${_formatNumber(record.hours!)}学时',
  if (credit && (record.credit ?? 0) > 0) '${_formatNumber(record.credit!)}学分',
  if (smallClass)
    fullSmallClassLabel(
      full: record.smallClassFull,
      small: record.smallClass,
      number: record.smallClassNumber,
    ),
].where((value) => value.isNotEmpty).join(' · ');

class _PeriodSlot extends StatelessWidget {
  const _PeriodSlot({
    required this.start,
    required this.end,
    required this.height,
    required this.records,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
  });

  final int start;
  final int end;
  final double height;
  final List<ScheduleRecord> records;
  final bool showHours, showCredit, showSmallClass;

  @override
  Widget build(BuildContext context) {
    final compact =
        EcjtuMetrics.phoneLayout(context) ||
        EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: height, end: height),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: const Cubic(.25, .1, .25, 1),
      builder: (context, value, child) => SizedBox(
        height: value,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: child,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 17),
              child: Text(
                '$start–$end',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF98A2B3),
                  fontSize: compact ? 12 : 14,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 66),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < records.length; index++) ...[
                    _CompactCourse(
                      record: records[index],
                      showHours: showHours,
                      showCredit: showCredit,
                      showSmallClass: showSmallClass,
                    ),
                    if (index < records.length - 1) const SizedBox(height: 7),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCourse extends StatelessWidget {
  const _CompactCourse({
    required this.record,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
  });

  final ScheduleRecord record;
  final bool showHours, showCredit, showSmallClass;

  @override
  Widget build(BuildContext context) {
    final details = _compactDetails(record);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact =
        EcjtuMetrics.phoneLayout(context) ||
        EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? EcjtuColors.darkControlSurface : Colors.white,
        ),
        border: Border.all(color: EcjtuColors.borderFor(context)),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.03),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  record.courseName,
                  style: _courseTitle(context, compact ? 14 : 15),
                ),
              ),
              if (_ScheduleDetailsScope.of(context) != null) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: ArrangementActionButton(
                    onPressed: () => _ScheduleDetailsScope.of(context)!(record),
                    label: '查看详情',
                  ),
                ),
              ],
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(details, style: _courseDetail(context, compact ? 11 : 14)),
          ],
          _ScheduleSupplement(
            key: const ValueKey('day-schedule-supplement'),
            text: _compactSupplement(
              record,
              showHours,
              showCredit,
              showSmallClass,
            ),
            padding: 6,
            textAlign: TextAlign.left,
            style: _courseDetail(context, compact ? 11 : 14),
          ),
        ],
      ),
    );
  }
}

class _FullSchedule extends StatefulWidget {
  const _FullSchedule({
    required this.records,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
  });

  final List<ScheduleRecord> records;
  final bool showHours;
  final bool showCredit;
  final bool showSmallClass;

  @override
  State<_FullSchedule> createState() => _FullScheduleState();
}

class _FullScheduleState extends State<_FullSchedule> {
  final _horizontalController = ScrollController();
  List<ScheduleRecord>? _groupedSource;
  final _byDay = <int, List<ScheduleRecord>>{};

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!listEquals(_groupedSource, widget.records)) {
      _groupedSource = List.of(widget.records);
      _byDay.clear();
      for (final record in _groupRecords(widget.records)) {
        _byDay.putIfAbsent(record.weekday, () => []).add(record);
      }
    }
    final byDay = _byDay;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            EcjtuMetrics.phoneLayout(context) ||
            EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
        final minimumWidth = compact ? 760.0 : 900.0;
        final tableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(minimumWidth, double.infinity)
            : minimumWidth;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: RepaintBoundary(
              child: Container(
                width: tableWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? EcjtuControlPalette.maybeOf(context)?.surface ??
                            const Color(0xFF0D1525)
                      : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? EcjtuControlPalette.maybeOf(context)?.border ??
                                const Color(0xFF2A3952)
                          : EcjtuColors.frameBorder,
                    ),
                    left: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? EcjtuControlPalette.maybeOf(context)?.border ??
                                const Color(0xFF2A3952)
                          : EcjtuColors.frameBorder,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _headerRow(compact),
                    for (var start = 1; start <= 12; start += 2)
                      _courseRow(start, start + 1, byDay, compact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerRow(bool compact) {
    return SizedBox(
      height: 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimetableCell(
            width: compact ? 58 : 76,
            corner: true,
            lightBackgroundColor: Color(0xFFE1EDF3),
            child: Text('节次'),
          ),
          for (
            var index = 0;
            index < ArrangementWeekdayPalette.names.length;
            index++
          )
            Expanded(
              child: _TimetableCell(
                lightTextColor: ArrangementWeekdayPalette.foreground[index],
                lightBackgroundColor:
                    ArrangementWeekdayPalette.background[index],
                child: Text(ArrangementWeekdayPalette.names[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _courseRow(
    int start,
    int end,
    Map<int, List<ScheduleRecord>> byDay,
    bool compact,
  ) {
    final recordsByDay = <int, List<ScheduleRecord>>{
      for (var day = 1; day <= 7; day++)
        day: _matchingCourses(
          byDay[day] ?? const <ScheduleRecord>[],
          start,
          end,
        ),
    };
    final mobile = EcjtuMetrics.phoneLayout(context);
    Widget courses(List<ScheduleRecord> records) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _courseWidgets(records),
    );
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TimetableCell(
          width: compact ? 58 : 76,
          period: true,
          child: Text('$start–$end'),
        ),
        for (var day = 1; day <= 7; day++)
          Expanded(
            child: _TimetableCell(
              header: false,
              alignment: Alignment.topLeft,
              horizontalPadding: compact ? 5 : 11,
              child: mobile
                  ? courses(recordsByDay[day]!)
                  : _NaturalHeightCourseCell(
                      child: courses(recordsByDay[day]!),
                    ),
            ),
          ),
      ],
    );
    if (mobile)
      return ConstrainedBox(
        key: ValueKey('full-schedule-row-$start'),
        constraints: const BoxConstraints(minHeight: 80),
        child: IntrinsicHeight(child: row),
      );
    return _AnimatedTimetableRow(
      key: ValueKey('full-schedule-row-$start'),
      child: row,
    );
  }

  List<ScheduleRecord> _matchingCourses(
    List<ScheduleRecord> records,
    int start,
    int end,
  ) {
    return records
        .where((item) => item.sectionStart >= start && item.sectionStart <= end)
        .toList();
  }

  List<Widget> _courseWidgets(List<ScheduleRecord> records) {
    return [
      for (var index = 0; index < records.length; index++)
        _FullCourse(
          record: records[index],
          separated: index > 0,
          showHours: widget.showHours,
          showCredit: widget.showCredit,
          showSmallClass: widget.showSmallClass,
        ),
    ];
  }
}

class _NaturalHeightCourseCell extends SingleChildRenderObjectWidget {
  const _NaturalHeightCourseCell({required super.child});

  @override
  RenderConstrainedOverflowBox createRenderObject(BuildContext context) =>
      _RenderNaturalHeightCourseCell();
}

class _RenderNaturalHeightCourseCell extends RenderConstrainedOverflowBox {
  _RenderNaturalHeightCourseCell()
    : super(
        minHeight: 0,
        maxHeight: double.infinity,
        fit: OverflowBoxFit.deferToChild,
        alignment: Alignment.topLeft,
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    child?.getDryLayout(
          BoxConstraints(
            minWidth: constraints.minWidth,
            maxWidth: constraints.maxWidth,
          ),
        ) ??
        constraints.smallest,
  );
}

class _AnimatedTimetableRow extends StatefulWidget {
  const _AnimatedTimetableRow({super.key, required this.child})
    : animateHeight = true;
  final Widget child;
  final bool animateHeight;

  @override
  State<_AnimatedTimetableRow> createState() => _AnimatedTimetableRowState();
}

class _AnimatedTimetableRowState extends State<_AnimatedTimetableRow>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    value: 1,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: _TimetableRowLayout(
      controller: _controller,
      animate: widget.animateHeight && !MediaQuery.disableAnimationsOf(context),
      child: widget.child,
    ),
  );
}

class _TimetableRowLayout extends SingleChildRenderObjectWidget {
  const _TimetableRowLayout({
    required this.controller,
    required this.animate,
    required super.child,
  });
  final AnimationController controller;
  final bool animate;

  @override
  _RenderTimetableRow createRenderObject(BuildContext context) =>
      _RenderTimetableRow(controller, animate);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTimetableRow renderObject,
  ) {
    renderObject.animate = animate;
    renderObject.markNeedsLayout();
  }
}

class _RenderTimetableRow extends RenderProxyBox {
  _RenderTimetableRow(this.controller, this.animate) {
    controller.addListener(_tick);
  }
  final AnimationController controller;
  bool animate;
  double? _target, _width;
  double _begin = 116;
  bool _layingOut = false;

  void _tick() {
    if (!_layingOut) markNeedsLayout();
  }

  double _contentHeight(double width) {
    final row = child! as RenderFlex;
    final period = row.firstChild!;
    final periodWidth = period.getMaxIntrinsicWidth(double.infinity);
    final dayWidth = math.max(0.0, (width - periodWidth) / 7);
    var height = 116.0;
    RenderBox? cell = period;
    while (cell != null) {
      final cellWidth = identical(cell, period) ? periodWidth : dayWidth;
      height = math.max(
        height,
        cell.getDryLayout(BoxConstraints.tightFor(width: cellWidth)).height,
      );
      cell = row.childAfter(cell);
    }
    return height;
  }

  @override
  void performLayout() {
    _layingOut = true;
    final width = constraints.maxWidth;
    final target = _contentHeight(width);
    if (_target != target || _width != width) {
      final snap = _target == null || _width != width || !animate;
      _begin = snap ? target : size.height;
      _target = target;
      _width = width;
      if (snap) {
        controller.value = 1;
      } else {
        controller.forward(from: 0);
      }
    }
    final height =
        _begin +
        (_target! - _begin) *
            const Cubic(
              .25,
              .1,
              .25,
              1,
            ).transform(animate ? controller.value : 1);
    size = constraints.constrain(Size(width, height));
    // Stretch the cell frames to the animated extent, not only the outer row.
    child!.layout(BoxConstraints.tight(size), parentUsesSize: true);
    _layingOut = false;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(constraints.maxWidth, _contentHeight(constraints.maxWidth)),
  );

  @override
  void dispose() {
    controller.removeListener(_tick);
    super.dispose();
  }
}

class _FullCourse extends StatelessWidget {
  const _FullCourse({
    required this.record,
    required this.separated,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
  });

  final ScheduleRecord record;
  final bool separated;
  final bool showHours;
  final bool showCredit;
  final bool showSmallClass;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final desktop = !EcjtuMetrics.phoneLayout(context);
    final smallSize = desktop
        ? (size.width >= 1280 ? 16.0 : 14.0)
        : _pluginSmallFontSize(size);
    final captionSize = desktop
        ? (size.width >= 1280 ? 14.0 : 12.0)
        : _pluginCaptionFontSize(size);
    final details = [
      if (record.teacher.isNotEmpty) record.teacher,
      if (record.classroom.isNotEmpty) '@${record.classroom}',
    ].join(' ');
    final range = [
      if (record.needsSectionLabel) '${record.sectionLabel}节',
      if (record.compactWeekRange.isNotEmpty) '第 ${record.compactWeekRange} 周',
      if (record.singleDouble.isNotEmpty) '${record.singleDouble}周',
    ].join(' · ');
    final workload = [
      if (showHours && record.hours != null && record.hours! > 0)
        '${_formatNumber(record.hours!)}学时',
      if (showCredit && record.credit != null && record.credit! > 0)
        '${_formatNumber(record.credit!)}学分',
    ].join(' · ');
    final smallClass = [
      if (record.smallClassFull.isNotEmpty)
        record.smallClassFull
      else if (record.smallClass.isNotEmpty)
        record.smallClass,
      if (record.smallClassNumber.isNotEmpty) '${record.smallClassNumber}号',
    ].join(' · ');
    final dark = Theme.of(context).brightness == Brightness.dark;
    final line =
        EcjtuControlPalette.maybeOf(context)?.border ??
        (EcjtuColors.borderFrom(
          context,
          dark ? const Color(0xFF34445F) : EcjtuColors.border,
        ));
    final children = <Widget>[
      Text(
        record.courseName,
        textAlign: TextAlign.center,
        style: _courseTitle(context, smallSize),
      ),
    ];
    if (details.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 4),
        Text(
          details,
          textAlign: TextAlign.center,
          style: _timetableDetail(context, captionSize),
        ),
      ]);
    }
    if (range.isNotEmpty) {
      children.addAll([
        SizedBox(height: details.isNotEmpty ? 2 : 4),
        Text(
          range,
          textAlign: TextAlign.center,
          style: _timetableDetail(context, captionSize),
        ),
      ]);
    }
    if (desktop) {
      if (workload.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              workload,
              textAlign: TextAlign.center,
              style: _timetableWorkload(context, captionSize),
            ),
          ),
        );
      }
      if (showSmallClass && smallClass.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              smallClass,
              textAlign: TextAlign.center,
              style: _timetableExtra(context, captionSize),
            ),
          ),
        );
      }
    } else {
      children.addAll([
        _ScheduleSupplement(
          key: const ValueKey('schedule-workload'),
          text: workload,
          padding: 4,
          style: _timetableWorkload(context, captionSize),
        ),
        _ScheduleSupplement(
          key: const ValueKey('schedule-small-class'),
          text: showSmallClass ? smallClass : '',
          padding: 6,
          style: _timetableExtra(context, captionSize),
        ),
      ]);
    }
    if (_ScheduleDetailsScope.of(context) != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () => _ScheduleDetailsScope.of(context)!(record),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '查看详情',
                  textAlign: TextAlign.center,
                  style: _timetableDetail(context, captionSize),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: separated ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(0, separated ? 12 : 5, 0, 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: separated ? Border(top: BorderSide(color: line)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _ScheduleSupplement extends StatefulWidget {
  const _ScheduleSupplement({
    super.key,
    required this.text,
    required this.padding,
    required this.style,
    this.textAlign = TextAlign.center,
  });
  final String text;
  final double padding;
  final TextStyle style;
  final TextAlign textAlign;
  @override
  State<_ScheduleSupplement> createState() => _ScheduleSupplementState();
}

class _ScheduleSupplementState extends State<_ScheduleSupplement>
    with SingleTickerProviderStateMixin {
  late String _text = widget.text;
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: widget.text.isEmpty ? 0 : 1,
  );
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(.25, .1, .25, 1),
    reverseCurve: const FlippedCurve(Cubic(.25, .1, .25, 1)),
  );
  @override
  void didUpdateWidget(_ScheduleSupplement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text.isNotEmpty) _text = widget.text;
    if (oldWidget.text.isEmpty != widget.text.isEmpty) {
      if (!EcjtuMetrics.phoneLayout(context) ||
          MediaQuery.disableAnimationsOf(context)) {
        _controller.value = widget.text.isEmpty ? 0 : 1;
      } else if (widget.text.isEmpty) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _animation,
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(top: widget.padding),
        child: Text(_text, textAlign: widget.textAlign, style: widget.style),
      ),
    ),
  );
}

class _TimetableCell extends StatelessWidget {
  const _TimetableCell({
    required this.child,
    this.width,
    this.header = true,
    this.period = false,
    this.corner = false,
    this.horizontalPadding = 6,
    this.alignment = Alignment.center,
    this.lightTextColor,
    this.lightBackgroundColor,
  });

  final Widget child;
  final double? width;
  final bool header;
  final bool period;
  final bool corner;
  final double horizontalPadding;
  final Alignment alignment;
  final Color? lightTextColor;
  final Color? lightBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final bodySize = EcjtuMetrics.phoneLayout(context)
        ? _pluginBodyFontSize(MediaQuery.sizeOf(context))
        : (MediaQuery.sizeOf(context).width >= 1280 ? 16.0 : 14.0);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    final line =
        palette?.border ??
        (EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF2A3952) : EcjtuColors.border,
        ));
    final surface = period
        ? (dark
              ? palette?.subtle ?? const Color(0xFF101A2B)
              : const Color(0xFFF5F8FA))
        : header
        ? (dark
              ? palette?.subtle ?? const Color(0xFF15243B)
              : lightBackgroundColor ?? const Color(0xFFF2F4F7))
        : (dark ? palette?.surface ?? const Color(0xFF0D1525) : Colors.white);
    final textColor = period
        ? (EcjtuColors.mutedFrom(
            context,
            dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
          ))
        : header
        ? (dark
              ? const Color(0xFFC6DDFF)
              : lightTextColor ?? const Color(0xFF344054))
        : (EcjtuColors.textFrom(
            context,
            dark ? const Color(0xFFEDF4FF) : const Color(0xFF344054),
          ));
    return Container(
      width: width,
      alignment: !header && !period ? Alignment.topLeft : alignment,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          right: BorderSide(color: line),
          bottom: BorderSide(color: line),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: corner && !dark ? const Color(0xFF577386) : textColor,
          fontSize: bodySize,
          height: period ? 1 : 1.2,
          fontWeight: period
              ? FontWeight.w700
              : header
              ? FontWeight.w600
              : FontWeight.w400,
        ),
        child: child,
      ),
    );
  }
}

List<ScheduleRecord> _groupRecords(Iterable<ScheduleRecord> records) {
  final grouped = <String, ScheduleRecord>{};
  for (final record in records) {
    final key = [
      record.courseName,
      record.weekday,
      record.sectionStart,
      record.sectionEnd,
      record.classroom,
    ].join('|');
    final previous = grouped[key];
    if (previous == null) {
      grouped[key] = record;
      continue;
    }
    final teachers = [
      previous.teacher,
      record.teacher,
    ].where((value) => value.isNotEmpty).toSet();
    final weeks = {...previous.weeks, ...record.weeks}.toList()..sort();
    grouped[key] = ScheduleRecord(
      term: record.term,
      weekday: record.weekday,
      sectionStart: record.sectionStart,
      sectionEnd: record.sectionEnd,
      courseName: record.courseName,
      courseCode: record.courseCode,
      courseType: record.courseType,
      examType: record.examType,
      teacher: teachers.length > 1
          ? '${teachers.length} 位教师'
          : teachers.firstOrNull ?? '',
      classroom: record.classroom,
      weekRange: weeks.isEmpty
          ? (record.weekRange.isNotEmpty
                ? record.weekRange
                : previous.weekRange)
          : _compactWeeks(weeks),
      singleDouble: record.singleDouble.isNotEmpty
          ? record.singleDouble
          : previous.singleDouble,
      weeks: weeks,
      hours: record.hours ?? previous.hours,
      credit: record.credit ?? previous.credit,
      smallClassFull: record.smallClassFull.isNotEmpty
          ? record.smallClassFull
          : previous.smallClassFull,
      smallClass: record.smallClass.isNotEmpty
          ? record.smallClass
          : previous.smallClass,
      smallClassNumber: record.smallClassNumber.isNotEmpty
          ? record.smallClassNumber
          : previous.smallClassNumber,
    );
  }
  return grouped.values.toList()
    ..sort((left, right) => left.sectionStart.compareTo(right.sectionStart));
}

TextStyle _timetableWorkload(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: Theme.of(
      context,
    ).textTheme.bodyMedium?.fontFamilyFallback,
    color: dark ? const Color(0xFFB0BFD6) : const Color(0xFF075FA5),
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );
}

TextStyle _timetableDetail(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: Theme.of(
      context,
    ).textTheme.bodyMedium?.fontFamilyFallback,
    color:
        EcjtuControlPalette.maybeOf(context)?.muted ??
        (dark ? const Color(0xFFB0BFD6) : const Color(0xFF667085)),
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

TextStyle _timetableExtra(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: Theme.of(
      context,
    ).textTheme.bodyMedium?.fontFamilyFallback,
    color: dark ? const Color(0xFFB0BFD6) : const Color(0xFF287591),
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

double _pluginCaptionFontSize(Size size) => EcjtuMetrics.fontCaptionFor(size);

double _pluginSmallFontSize(Size size) => EcjtuMetrics.fontSmallFor(size);

double _pluginBodyFontSize(Size size) => EcjtuMetrics.fontBodyFor(size);

String _compactWeeks(List<int> values) {
  if (values.isEmpty) return '';
  final sorted = values.toSet().toList()..sort();
  final groups = <String>[];
  var start = sorted.first;
  var previous = start;
  for (final week in sorted.skip(1)) {
    if (week == previous + 1) {
      previous = week;
      continue;
    }
    groups.add(start == previous ? '$start' : '$start-$previous');
    start = previous = week;
  }
  groups.add(start == previous ? '$start' : '$start-$previous');
  return groups.join(',');
}

String _formatNumber(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

TextStyle _courseTitle(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: Theme.of(
      context,
    ).textTheme.bodyMedium?.fontFamilyFallback,
    color: EcjtuColors.textFrom(
      context,
      dark ? EcjtuColors.darkTextPrimary : const Color(0xFF1D2939),
    ),
    fontSize: size,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );
}

TextStyle _courseDetail(
  BuildContext context,
  double size, {
  bool accent = false,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    fontFamilyFallback: Theme.of(
      context,
    ).textTheme.bodyMedium?.fontFamilyFallback,
    color: accent
        ? (dark ? EcjtuColors.darkPrimary : EcjtuColors.primary)
        : (EcjtuColors.mutedFor(context)),
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
