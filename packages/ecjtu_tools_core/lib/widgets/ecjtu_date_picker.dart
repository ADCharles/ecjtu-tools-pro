// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';
import 'ecjtu_select_box.dart';
import 'ai_controls_scope.dart';
import 'ecjtu_pane_surface.dart';

Future<DateTime?> showEcjtuDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  List<int>? availableYears,
  double minimumWidth = 0,
}) {
  final lower = firstDate ?? DateTime(2000);
  final upper = lastDate ?? DateTime(2100);
  final clamped = _clampDate(initialDate, lower, upper);
  return _showAnchoredPicker<DateTime>(
    context: context,
    preferredWidth: 342,
    minimumWidth: minimumWidth,
    builder: (dialogContext) => _EcjtuDatePickerPanel(
      initialDate: clamped,
      firstDate: lower,
      lastDate: upper,
      availableYears: availableYears,
    ),
  );
}

Future<TimeOfDay?> showEcjtuTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return _showAnchoredPicker<TimeOfDay>(
    context: context,
    preferredWidth: 300,
    builder: (dialogContext) => _EcjtuTimePickerPanel(initialTime: initialTime),
  );
}

Future<T?> _showAnchoredPicker<T>({
  required BuildContext context,
  required double preferredWidth,
  required WidgetBuilder builder,
  double minimumWidth = 0,
}) {
  final origin = context;
  final navigator = Navigator.of(
    context,
    rootNavigator: !EcjtuPaneDialogScope.contains(context),
  );
  final overlay = navigator.overlay?.context.findRenderObject();
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final renderObject = context.findRenderObject();
  final anchor = renderObject is RenderBox && renderObject.hasSize
      ? renderObject.localToGlobal(
              Offset.zero,
              ancestor: overlay is RenderBox ? overlay : null,
            ) &
            renderObject.size
      : Rect.zero;
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: !EcjtuPaneDialogScope.contains(context),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) => themes.wrap(
      Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const margin = 12.0;
            const gap = 6.0;
            final availableWidth = math.max(
              0.0,
              constraints.maxWidth - margin * 2,
            );
            final anchorWidth = anchor.width > 0
                ? anchor.width
                : preferredWidth;
            final width = math.min(
              math.min(preferredWidth, math.max(anchorWidth, minimumWidth)),
              availableWidth,
            );
            final left = (anchor.center.dx - width / 2)
                .clamp(
                  margin,
                  math.max(margin, constraints.maxWidth - width - margin),
                )
                .toDouble();
            final below = anchor.bottom + gap;
            final top = below + 90 <= constraints.maxHeight - margin
                ? below
                : math.max(margin, anchor.top - gap - 90);
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: width,
                  child: AiControlsScope.captureDialog(
                    origin,
                    Builder(builder: builder),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _EcjtuDatePickerPanel extends StatefulWidget {
  const _EcjtuDatePickerPanel({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.availableYears,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<int>? availableYears;

  @override
  State<_EcjtuDatePickerPanel> createState() => _EcjtuDatePickerPanelState();
}

class _EcjtuDatePickerPanelState extends State<_EcjtuDatePickerPanel> {
  late int _year = widget.initialDate.year;
  late int _month = widget.initialDate.month;
  late int _day = widget.initialDate.day;

  @override
  Widget build(BuildContext context) {
    final yearStart = widget.firstDate.year;
    final yearEnd = widget.lastDate.year;
    final years =
        widget.availableYears == null
              ? <int>[for (var year = yearStart; year <= yearEnd; year++) year]
              : <int>{
                  ...widget.availableYears!,
                  widget.initialDate.year,
                }.where((year) => year >= yearStart && year <= yearEnd).toList()
          ..sort();
    final monthItems = <int>[
      for (var month = 1; month <= 12; month++)
        if (_monthIsAllowed(month)) month,
    ];
    final daysInMonth = _daysInMonth(_year, _month);
    final dayItems = <int>[
      for (var day = 1; day <= daysInMonth; day++)
        if (_dayIsAllowed(day)) day,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: EcjtuColors.surfaceFor(context),
          border: Border.all(color: EcjtuColors.borderFor(context)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24101828),
              blurRadius: 32,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 320;
            final yearWidth = narrow ? 82.0 : 94.0;
            const confirmWidth = 80.0;
            final datePartWidth = math.max(
              54.0,
              math.min(
                70.0,
                (constraints.maxWidth - yearWidth - confirmWidth - 15) / 2,
              ),
            );
            final selectors = Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: yearWidth,
                  child: EcjtuSelectBox<int>(
                    value: _year,
                    items: years,
                    labelBuilder: (value) => '$value年',
                    onChanged: (value) => setState(() {
                      _year = value;
                      _normalizeSelection();
                    }),
                  ),
                ),
                SizedBox(
                  width: datePartWidth,
                  child: EcjtuSelectBox<int>(
                    value: _month,
                    items: monthItems,
                    labelBuilder: (value) => '$value月',
                    onChanged: (value) => setState(() {
                      _month = value;
                      _normalizeSelection();
                    }),
                  ),
                ),
                SizedBox(
                  width: datePartWidth,
                  child: EcjtuSelectBox<int>(
                    value: _day,
                    items: dayItems,
                    labelBuilder: (value) => '$value日',
                    onChanged: (value) => setState(() => _day = value),
                  ),
                ),
                SizedBox(
                  width: confirmWidth,
                  height: EcjtuMetrics.pickerHeight,
                  child: FilledButton(
                    onPressed: _isCurrentSelectionAllowed ? _confirm : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: EcjtuColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: EcjtuColors.primary.withValues(
                        alpha: .35,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            fontSize: EcjtuMetrics.fontCaptionFor(
                              MediaQuery.sizeOf(context),
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    child: const Text('确定'),
                  ),
                ),
              ],
            );
            return selectors;
          },
        ),
      ),
    );
  }

  bool get _isCurrentSelectionAllowed {
    final date = DateTime(_year, _month, _day);
    return !_dateOnly(date).isBefore(_dateOnly(widget.firstDate)) &&
        !_dateOnly(date).isAfter(_dateOnly(widget.lastDate));
  }

  bool _monthIsAllowed(int month) {
    final first = DateTime(_year, month, 1);
    final last = DateTime(_year, month, _daysInMonth(_year, month));
    return !_dateOnly(last).isBefore(_dateOnly(widget.firstDate)) &&
        !_dateOnly(first).isAfter(_dateOnly(widget.lastDate));
  }

  bool _dayIsAllowed(int day) {
    final date = DateTime(_year, _month, day);
    return !_dateOnly(date).isBefore(_dateOnly(widget.firstDate)) &&
        !_dateOnly(date).isAfter(_dateOnly(widget.lastDate));
  }

  void _normalizeSelection() {
    final validMonths = [
      for (var month = 1; month <= 12; month++)
        if (_monthIsAllowed(month)) month,
    ];
    if (!validMonths.contains(_month)) _month = validMonths.first;
    final maxDay = _daysInMonth(_year, _month);
    _day = math.min(_day, maxDay);
    final validDays = [
      for (var day = 1; day <= maxDay; day++)
        if (_dayIsAllowed(day)) day,
    ];
    if (!validDays.contains(_day)) _day = validDays.first;
  }

  void _confirm() {
    Navigator.of(context).pop(DateTime(_year, _month, _day));
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _EcjtuTimePickerPanel extends StatefulWidget {
  const _EcjtuTimePickerPanel({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_EcjtuTimePickerPanel> createState() => _EcjtuTimePickerPanelState();
}

class _EcjtuTimePickerPanelState extends State<_EcjtuTimePickerPanel> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFor(context),
        border: Border.all(color: EcjtuColors.borderFor(context)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24101828),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: EcjtuSelectBox<int>(
              value: _hour,
              items: const [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23,
              ],
              labelBuilder: (value) => '${value.toString().padLeft(2, '0')}时',
              onChanged: (value) => setState(() => _hour = value),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: EcjtuSelectBox<int>(
              value: _minute,
              items: const [
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                12,
                13,
                14,
                15,
                16,
                17,
                18,
                19,
                20,
                21,
                22,
                23,
                24,
                25,
                26,
                27,
                28,
                29,
                30,
                31,
                32,
                33,
                34,
                35,
                36,
                37,
                38,
                39,
                40,
                41,
                42,
                43,
                44,
                45,
                46,
                47,
                48,
                49,
                50,
                51,
                52,
                53,
                54,
                55,
                56,
                57,
                58,
                59,
              ],
              labelBuilder: (value) => '${value.toString().padLeft(2, '0')}分',
              onChanged: (value) => setState(() => _minute = value),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 64,
            height: EcjtuMetrics.pickerHeight,
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(TimeOfDay(hour: _hour, minute: _minute)),
              style: FilledButton.styleFrom(
                backgroundColor: EcjtuColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: EcjtuMetrics.fontCaptionFor(size),
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
  final date = DateTime(value.year, value.month, value.day);
  final lower = DateTime(first.year, first.month, first.day);
  final upper = DateTime(last.year, last.month, last.day);
  if (date.isBefore(lower)) return lower;
  if (date.isAfter(upper)) return upper;
  return date;
}
