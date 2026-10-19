// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_glass.dart';
import '../../widgets/ecjtu_widgets.dart';
import 'arrangement_models.dart';
import 'arrangement_visuals.dart';

class ArrangementFilters extends StatelessWidget {
  const ArrangementFilters({
    super.key,
    required this.section,
    this.allowAllWeeks = true,
    required this.terms,
    required this.weeks,
    required this.selectedTerm,
    required this.selectedWeek,
    required this.onTermChanged,
    required this.onWeekChanged,
  });

  final ArrangementSection section;
  final bool allowAllWeeks;
  final List<String> terms;
  final List<int> weeks;
  final String? selectedTerm;
  final int? selectedWeek;
  final ValueChanged<String> onTermChanged;
  final ValueChanged<int?> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    final compact =
        EcjtuMetrics.phoneLayout(context) ||
        EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    final controls = <Widget>[];
    if (terms.isNotEmpty) {
      controls.add(
        SizedBox(
          width: compact ? 112 : 132,
          child: EcjtuSelectBox<String>(
            value: selectedTerm ?? terms.first,
            items: terms,
            labelBuilder: (value) => value == 'all' ? '全部学期' : value,
            onChanged: onTermChanged,
          ),
        ),
      );
    }
    if (section == ArrangementSection.courses && weeks.isNotEmpty) {
      if (controls.isNotEmpty) controls.add(const SizedBox(width: 4));
      controls.add(
        SizedBox(
          width: compact ? 104 : 116,
          child: EcjtuSelectBox<int?>(
            value: allowAllWeeks ? selectedWeek : selectedWeek ?? weeks.first,
            items: <int?>[if (allowAllWeeks) null, ...weeks],
            labelBuilder: (value) => value == null ? '全部周次' : '第 $value 周',
            onChanged: onWeekChanged,
          ),
        ),
      );
    }
    if (controls.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: controls);
  }
}

class ArrangementSegmentedControl extends StatefulWidget {
  const ArrangementSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ArrangementSection value;
  final ValueChanged<ArrangementSection> onChanged;

  @override
  State<ArrangementSegmentedControl> createState() =>
      _ArrangementSegmentedControlState();
}

class _ArrangementSegmentedControlState
    extends State<ArrangementSegmentedControl> {
  late ArrangementSection _value = widget.value;

  @override
  void didUpdateWidget(covariant ArrangementSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  void _select(ArrangementSection value) {
    if (value == _value) return;
    setState(() => _value = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EcjtuSlidingSegments(
      items: [for (final section in ArrangementSection.values) section.title],
      selectedIndex: ArrangementSection.values.indexOf(_value),
      onChanged: (index) => _select(ArrangementSection.values[index]),
    );
  }
}

class ArrangementSegmentChoices extends StatelessWidget {
  const ArrangementSegmentChoices({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context))
            ? 13.0
            : 16.0;
        final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        );
        var minimum = 70.0;
        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          if (painter.width + 20 > minimum) minimum = painter.width + 20;
          painter.dispose();
        }
        final columns = ((constraints.maxWidth - 8) / minimum).floor().clamp(
          1,
          labels.length,
        );
        return EcjtuSlidingSegments(
          items: labels,
          selectedIndex: selectedIndex,
          onChanged: onChanged,
          columns: columns,
          height: 40,
          fontSize: fontSize,
        );
      },
    );
  }
}

class ArrangementActionButton extends StatelessWidget {
  const ArrangementActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = EcjtuGlass.of(context);
    final originalBlue = !colors.dark && colors.blue;
    return MouseRegion(
      cursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Opacity(
            opacity: onPressed == null ? .5 : 1,
            child: Container(
              height: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.dark ? colors.selected : Colors.white,
                border: Border.all(
                  color: originalBlue
                      ? const Color(0xFFCADDEA)
                      : EcjtuColors.borderFor(context),
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: originalBlue ? const Color(0xFF0B5F99) : colors.accent,
                  fontSize: EcjtuMetrics.phoneLayout(context)
                      ? 14
                      : EcjtuMetrics.isCompact(MediaQuery.sizeOf(context))
                      ? 13
                      : 16,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleDisplayOptions extends StatelessWidget {
  const ScheduleDisplayOptions({
    super.key,
    required this.showHours,
    required this.showCredit,
    required this.showSmallClass,
    required this.onHoursChanged,
    required this.onCreditChanged,
    required this.onSmallClassChanged,
    this.leading,
  });

  final bool showHours;
  final bool showCredit;
  final bool showSmallClass;
  final ValueChanged<bool> onHoursChanged;
  final ValueChanged<bool> onCreditChanged;
  final ValueChanged<bool> onSmallClassChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final mobile = EcjtuMetrics.phoneLayout(context);
    final spacing = mobile ? 8.0 : 18.0;
    final options = <Widget>[
      _ScheduleOption(title: '学时', value: showHours, onChanged: onHoursChanged),
      SizedBox(width: spacing),
      _ScheduleOption(
        title: '学分',
        value: showCredit,
        onChanged: onCreditChanged,
      ),
      SizedBox(width: spacing),
      _ScheduleOption(
        title: '小班信息',
        value: showSmallClass,
        onChanged: onSmallClassChanged,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        widthFactor: mobile ? null : 1,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: leading != null && mobile && constraints.hasBoundedWidth
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            if (leading != null) ...[
              if (mobile && constraints.hasBoundedWidth)
                Expanded(child: leading!)
              else
                leading!,
              SizedBox(width: spacing),
            ],
            ...options,
          ],
        ),
      ),
    );
  }
}

class ScheduleViewModeControl extends StatefulWidget {
  const ScheduleViewModeControl({
    super.key,
    required this.showFullSchedule,
    required this.onChanged,
  });

  final bool showFullSchedule;
  final ValueChanged<bool> onChanged;

  @override
  State<ScheduleViewModeControl> createState() =>
      _ScheduleViewModeControlState();
}

class _ScheduleViewModeControlState extends State<ScheduleViewModeControl> {
  late bool _showFullSchedule = widget.showFullSchedule;

  @override
  void didUpdateWidget(covariant ScheduleViewModeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFullSchedule != oldWidget.showFullSchedule &&
        widget.showFullSchedule != _showFullSchedule) {
      _showFullSchedule = widget.showFullSchedule;
    }
  }

  void _select(bool value) {
    if (value == _showFullSchedule) return;
    setState(() => _showFullSchedule = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: EcjtuMetrics.phoneLayout(context)
          ? MediaQuery.sizeOf(context).width - 48
          : 340,
      child: EcjtuSlidingSegments(
        items: const ['日程表', '完整课表'],
        duration: const Duration(milliseconds: 140),
        selectedIndex: _showFullSchedule ? 1 : 0,
        onChanged: (index) => _select(index == 1),
      ),
    );
  }
}

class _ScheduleOption extends StatefulWidget {
  const _ScheduleOption({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_ScheduleOption> createState() => _ScheduleOptionState();
}

class _ScheduleOptionState extends State<_ScheduleOption> {
  late bool _value = widget.value;

  @override
  void didUpdateWidget(covariant _ScheduleOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  void _toggle() {
    final value = !_value;
    setState(() => _value = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: EcjtuAnimation.navigation,
              curve: const Cubic(.25, .1, .25, 1),
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: _value
                    ? (dark ? const Color(0xFF3D95E8) : EcjtuColors.primary)
                    : EcjtuColors.switchOff,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 14, height: 14),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              widget.title,
              style: TextStyle(
                color: dark
                    ? const Color(0xFFB4C3D8)
                    : EcjtuColors.textSecondary,
                fontSize: EcjtuMetrics.phoneLayout(context)
                    ? 12
                    : compact
                    ? 11
                    : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeekdaySegmentedControl extends StatefulWidget {
  const WeekdaySegmentedControl({
    super.key,
    required this.selectedDay,
    required this.onChanged,
  });

  final int selectedDay;
  final ValueChanged<int> onChanged;

  @override
  State<WeekdaySegmentedControl> createState() =>
      _WeekdaySegmentedControlState();
}

class _WeekdaySegmentedControlState extends State<WeekdaySegmentedControl> {
  late int _selectedDay = widget.selectedDay;

  @override
  void didUpdateWidget(covariant WeekdaySegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay &&
        widget.selectedDay != _selectedDay) {
      _selectedDay = widget.selectedDay;
    }
  }

  void _select(int value) {
    if (value == _selectedDay) return;
    setState(() => _selectedDay = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark
            ? EcjtuGlass.of(context).segmentedTrack
            : EcjtuGlass.of(context).green
            ? const Color(0xFFEAF4EE)
            : EcjtuColors.weekdaySurface,
        borderRadius: BorderRadius.circular(7),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth / ArrangementWeekdayPalette.labels.length;
          final background = dark
              ? Color.lerp(
                  const Color(0xFF191919),
                  ArrangementWeekdayPalette.foreground[_selectedDay],
                  .25,
                )!
              : ArrangementWeekdayPalette.background[_selectedDay];
          return Stack(
            children: [
              AnimatedPositioned(
                key: const ValueKey('weekday-selection-thumb'),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 140),
                curve: const Cubic(.25, .1, .25, 1),
                left: _selectedDay * width,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Row(
                children: [
                  for (
                    var index = 0;
                    index < ArrangementWeekdayPalette.labels.length;
                    index++
                  )
                    Expanded(
                      child: _WeekdaySegment(
                        title: ArrangementWeekdayPalette.labels[index],
                        selected: _selectedDay == index,
                        foreground: dark
                            ? Color.lerp(
                                ArrangementWeekdayPalette.foreground[index],
                                Colors.white,
                                .58,
                              )!
                            : ArrangementWeekdayPalette.foreground[index],
                        background: Colors.transparent,
                        onPressed: () => _select(index),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekdaySegment extends StatelessWidget {
  const _WeekdaySegment({
    required this.title,
    required this.selected,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  final String title;
  final bool selected;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: const Cubic(.25, .1, .25, 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? background : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? foreground : (EcjtuColors.mutedFor(context)),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
