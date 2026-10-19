// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_widgets.dart';
import '../workbench/smart_work_widgets.dart';
import 'curriculum_models.dart';

String _formatCurriculumNumber(double value) {
  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({
    super.key,
    required this.snapshot,
    this.loading = false,
    this.synced = false,
    this.error,
    this.onRequestSync,
    this.onBack,
  });

  final CurriculumSnapshot snapshot;
  final bool loading;
  final bool synced;
  final String? error;
  final VoidCallback? onRequestSync;
  final VoidCallback? onBack;

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  static const _fullWidths = <double>[
    145,
    175,
    370,
    102,
    74,
    84,
    84,
    84,
    84,
    84,
    104,
  ];

  String _selectedPlatform = 'all';
  String _selectedSemester = 'all';
  String _selectedStatus = 'all';

  @override
  void didUpdateWidget(covariant CurriculumPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.snapshot.platforms.contains(_selectedPlatform)) {
      _selectedPlatform = 'all';
    }
    if (!widget.snapshot.semesters
        .map((value) => value.toString())
        .contains(_selectedSemester)) {
      _selectedSemester = 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    final records = widget.snapshot.records;
    final filtered = records.where(_matchesFilters).toList();
    final groups = _groupByPlatform(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onBack != null)
          SmartWorkPageHeader(
            key: const ValueKey('curriculum-header'),
            title: '培养方案',
            backTitle: '返回教务工具',
            onBack: widget.onBack!,
          )
        else
          SizedBox(
            key: const ValueKey('curriculum-header'),
            height: EcjtuMetrics.pageHeaderHeightFor(context),
            child: EcjtuSectionTitle('培养方案', lineHeight: 1.15),
          ),
        SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        if (records.isNotEmpty)
          KeyedSubtree(
            key: const ValueKey('curriculum-toolbar'),
            child: _buildToolbar(context, compact),
          ),
        if (records.isNotEmpty)
          SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        if (records.isEmpty &&
            (widget.loading || (!widget.synced && widget.error == null)))
          const SmartWorkLoading(message: '正在读取培养方案')
        else if (widget.error != null && records.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartWorkInlineMessage(message: widget.error!, error: true),
              if (widget.onRequestSync != null)
                EcjtuDialogAction(
                  label: '重新获取',
                  onPressed: widget.onRequestSync,
                ),
            ],
          )
        else if (records.isEmpty)
          _CurriculumEmpty(compact: compact, title: '尚未获取培养方案', detail: '')
        else if (filtered.isEmpty)
          _CurriculumEmpty(
            compact: compact,
            title: '当前筛选条件下没有课程',
            emphasized: false,
          )
        else
          for (var index = 0; index < groups.length; index += 1)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == groups.length - 1 ? 0 : 30,
              ),
              child: _PlatformGroup(
                index: index + 1,
                platform: groups[index].$1,
                records: groups[index].$2,
                compact: compact,
                widths: _fullWidths,
                showPlatformNumber: _selectedPlatform == 'all',
              ),
            ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool compact) {
    final platformItems = <String>['all', ...widget.snapshot.platforms];
    final semesterItems = <String>[
      'all',
      ...widget.snapshot.semesters.map((value) => value.toString()),
    ];
    final platformValue = platformItems.contains(_selectedPlatform)
        ? _selectedPlatform
        : 'all';
    final semesterValue = semesterItems.contains(_selectedSemester)
        ? _selectedSemester
        : 'all';
    if (platformValue != _selectedPlatform) _selectedPlatform = platformValue;
    if (semesterValue != _selectedSemester) _selectedSemester = semesterValue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final platformPicker = EcjtuSelectBox<String>(
          value: platformValue,
          items: platformItems,
          labelBuilder: (value) => value == 'all' ? '全部板块' : value,
          onChanged: (value) => setState(() => _selectedPlatform = value),
        );
        final semesterPicker = EcjtuSelectBox<String>(
          value: semesterValue,
          items: semesterItems,
          labelBuilder: (value) => value == 'all'
              ? '全部学期'
              : CurriculumRecord.labelForSemester(int.parse(value)),
          onChanged: (value) => setState(() => _selectedSemester = value),
        );
        final narrow = compact || constraints.maxWidth < 730;
        final statusSwitch = _CurriculumStatusSwitch(
          value: _selectedStatus,
          fill: narrow,
          onChanged: (value) => setState(() => _selectedStatus = value),
        );
        if (!narrow) {
          return Row(
            children: [
              SizedBox(width: 240, child: platformPicker),
              const SizedBox(width: 8),
              SizedBox(width: 150, child: semesterPicker),
              const SizedBox(width: 8),
              statusSwitch,
              const SizedBox(width: 10),
              Text(
                '${widget.snapshot.records.where(_matchesFilters).length} / ${widget.snapshot.records.length} 门',
              ),
            ],
          );
        }
        final selectWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(width: selectWidth, child: platformPicker),
            SizedBox(width: selectWidth, child: semesterPicker),
            SizedBox(
              width: constraints.maxWidth,
              child: Row(
                children: [
                  Expanded(child: statusSwitch),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.snapshot.records.where(_matchesFilters).length} / ${widget.snapshot.records.length} 门',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesFilters(CurriculumRecord record) {
    return (_selectedPlatform == 'all' ||
            record.platformLabel == _selectedPlatform) &&
        (_selectedSemester == 'all' ||
            record.semesterIndexes
                .map((value) => value.toString())
                .contains(_selectedSemester)) &&
        (_selectedStatus != 'pending' || !record.isPassed);
  }

  List<(String, List<CurriculumRecord>)> _groupByPlatform(
    List<CurriculumRecord> records,
  ) {
    final groups = <String, List<CurriculumRecord>>{};
    for (final record in records) {
      groups.putIfAbsent(record.platformLabel, () => []).add(record);
    }
    return [for (final entry in groups.entries) (entry.key, entry.value)];
  }
}

class _CurriculumStatusSwitch extends StatelessWidget {
  const _CurriculumStatusSwitch({
    required this.value,
    required this.onChanged,
    this.fill = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final control = EcjtuSlidingSegments(
      items: const ['全部课程', '未通过'],
      selectedIndex: value == 'pending' ? 1 : 0,
      onChanged: (index) => onChanged(index == 0 ? 'all' : 'pending'),
      height: EcjtuMetrics.phoneLayout(context)
          ? 42
          : EcjtuMetrics.pickerHeight,
      fontSize: EcjtuMetrics.smartWorkBodyFontSizeFor(
        MediaQuery.sizeOf(context),
      ),
    );
    return fill ? control : SizedBox(width: 210, child: control);
  }
}

class _PlatformGroup extends StatelessWidget {
  const _PlatformGroup({
    required this.index,
    required this.platform,
    required this.records,
    required this.compact,
    required this.widths,
    required this.showPlatformNumber,
  });

  final int index;
  final String platform;
  final List<CurriculumRecord> records;
  final bool compact;
  final List<double> widths;
  final bool showPlatformNumber;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final title = showPlatformNumber ? '$index、$platform' : platform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE8F3FF)
                        : const Color(0xFF101828),
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${records.length} 门课程',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: EcjtuMetrics.smartWorkCaptionFontSizeFor(size),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Divider(
          height: 2,
          thickness: 2,
          color: EcjtuColors.borderFrom(
            context,
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF365D88)
                : const Color(0xFFB9D6EA),
          ),
        ),
        if (compact)
          _CompactCurriculumTable(records: records)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const minimumWidths = <double>[
                100,
                130,
                230,
                76,
                58,
                64,
                64,
                64,
                64,
                64,
                80,
              ];
              final minimum = minimumWidths.fold<double>(
                0,
                (sum, value) => sum + value,
              );
              final extra = (constraints.maxWidth - minimum).clamp(
                0.0,
                double.infinity,
              );
              final flexibleWidths = [
                for (var i = 0; i < minimumWidths.length; i++)
                  minimumWidths[i] + extra * (i == 2 ? 0.4 : 0.06),
              ];
              return _FullCurriculumTable(
                records: records,
                widths: flexibleWidths,
              );
            },
          ),
      ],
    );
  }
}

class _FullCurriculumTable extends StatelessWidget {
  const _FullCurriculumTable({required this.records, required this.widths});

  final List<CurriculumRecord> records;
  final List<double> widths;

  double get _totalWidth => widths.fold(0, (total, width) => total + width);

  @override
  Widget build(BuildContext context) {
    final moduleGroups = <String, List<CurriculumRecord>>{};
    for (final record in records) {
      moduleGroups
          .putIfAbsent(record.module.isEmpty ? '其他课程' : record.module, () => [])
          .add(record);
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? EcjtuColors.surfaceFor(context) : Colors.white,
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF33445F) : const Color(0xFFCBD8E2),
          ),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: ScrollConfiguration(
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
          scrollDirection: Axis.horizontal,
          child: RepaintBoundary(
            child: SizedBox(
              width: _totalWidth,
              child: Column(
                children: [
                  _CurriculumTableHeader(widths: widths),
                  for (var index = 0; index < moduleGroups.length; index += 1)
                    _CurriculumModuleBlock(
                      module: moduleGroups.entries.elementAt(index).key,
                      records: moduleGroups.entries.elementAt(index).value,
                      widths: widths,
                      isLastModule: index == moduleGroups.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurriculumTableHeader extends StatelessWidget {
  const _CurriculumTableHeader({required this.widths});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF155D91) : const Color(0xFF1678AD);
    final border = dark ? const Color(0xFF3975A4) : const Color(0xFFD5DEE6);
    final headerRowHeight =
        MediaQuery.textScalerOf(
              context,
            ).scale(EcjtuMetrics.fluid(MediaQuery.sizeOf(context), 13, 14)) *
            3 +
        24;
    final labels = ['课程模块', '课程编号', '课程名称', '考核类型', '学分', '总学时', '课内学时'];
    final practiceWidth = widths[7] + widths[8] + widths[9];
    return Container(
      height: headerRowHeight * 2,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: background),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index += 1)
            _headerCell(
              context,
              labels[index],
              widths[index],
              height: headerRowHeight * 2,
              border: border,
              background: background,
            ),
          SizedBox(
            width: practiceWidth,
            height: headerRowHeight * 2,
            child: Column(
              children: [
                _headerCell(
                  context,
                  '实践学时',
                  practiceWidth,
                  height: headerRowHeight,
                  border: border,
                  background: background,
                ),
                Row(
                  children: [
                    _headerCell(
                      context,
                      '实验学时',
                      widths[7],
                      height: headerRowHeight,
                      border: border,
                      background: background,
                    ),
                    _headerCell(
                      context,
                      '上机学时',
                      widths[8],
                      height: headerRowHeight,
                      border: border,
                      background: background,
                    ),
                    _headerCell(
                      context,
                      '其他学时',
                      widths[9],
                      height: headerRowHeight,
                      border: border,
                      background: background,
                      rightBorder: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _headerCell(
            context,
            '修读学期',
            widths[10],
            height: headerRowHeight * 2,
            border: border,
            background: background,
            rightBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    BuildContext context,
    String label,
    double width, {
    required double height,
    required Color border,
    required Color background,
    bool rightBorder = true,
  }) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: rightBorder ? BorderSide(color: border) : BorderSide.none,
          bottom: BorderSide(color: border),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: EcjtuMetrics.fluid(MediaQuery.sizeOf(context), 13, 14),
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }
}

class _CurriculumModuleBlock extends StatefulWidget {
  const _CurriculumModuleBlock({
    required this.module,
    required this.records,
    required this.widths,
    required this.isLastModule,
  });

  final String module;
  final List<CurriculumRecord> records;
  final List<double> widths;
  final bool isLastModule;

  @override
  State<_CurriculumModuleBlock> createState() => _CurriculumModuleBlockState();
}

class _CurriculumModuleBlockState extends State<_CurriculumModuleBlock> {
  int? _hoveredRow;

  void _setHoveredRow(int index, bool hovered) {
    if (!mounted) return;
    setState(() {
      if (hovered) {
        _hoveredRow = index;
      } else if (_hoveredRow == index) {
        _hoveredRow = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final body = dark ? EcjtuColors.surfaceFor(context) : Colors.white;
    final border = EcjtuColors.borderFrom(
      context,
      dark ? const Color(0xFF2D3C55) : const Color(0xFFD5DEE6),
    );
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: widget.widths.first,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF13233A)
                  : _hoveredRow == 0
                  ? const Color(0xFFF3F8FC)
                  : const Color(0xFFF4F8FB),
              border: Border(
                right: BorderSide(color: border),
                bottom: widget.isLastModule
                    ? BorderSide.none
                    : BorderSide(color: border),
              ),
            ),
            child: Text(
              widget.module,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? const Color(0xFFC8DDF7) : const Color(0xFF244B66),
                fontSize: EcjtuMetrics.fluid(
                  MediaQuery.sizeOf(context),
                  13,
                  14,
                ),
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: widget.widths.first),
          child: SizedBox(
            width: widget.widths
                .skip(1)
                .fold<double>(0, (total, width) => total + width),
            child: Column(
              children: [
                for (var index = 0; index < widget.records.length; index += 1)
                  _CurriculumDataRow(
                    record: widget.records[index],
                    widths: widget.widths.skip(1).toList(),
                    body: body,
                    border: border,
                    hoverBody: dark
                        ? const Color(0xFF15243B)
                        : const Color(0xFFF3F8FC),
                    hovered: _hoveredRow == index,
                    onHover: (hovered) => _setHoveredRow(index, hovered),
                    isLastRow:
                        widget.isLastModule &&
                        index == widget.records.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CurriculumDataRow extends StatelessWidget {
  const _CurriculumDataRow({
    required this.record,
    required this.widths,
    required this.body,
    required this.border,
    required this.hoverBody,
    required this.hovered,
    required this.onHover,
    required this.isLastRow,
  });

  final CurriculumRecord record;
  final List<double> widths;
  final Color body;
  final Color border;
  final Color hoverBody;
  final bool hovered;
  final ValueChanged<bool> onHover;
  final bool isLastRow;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final codeMetaColor = dark
        ? switch (record.status) {
            '已过' => const Color(0xFF66D69E),
            '未修' => const Color(0xFFFF9D82),
            '在修' => const Color(0xFF72B7FF),
            _ => const Color(0xFFB6C5DA),
          }
        : switch (record.status) {
            '未修' => const Color(0xFFB42318),
            '在修' => const Color(0xFF0475CC),
            _ => const Color(0xFF566E80),
          };
    final codeMeta = [
      record.courseType,
      record.status,
    ].where((value) => value.isNotEmpty).join('，');
    final cells = <Widget>[
      _bodyCell(
        widths[0],
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record.courseCode.isEmpty ? '未标注' : record.courseCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? const Color(0xFFF4F7FF) : const Color(0xFF173F5F),
                fontSize: EcjtuMetrics.fluid(
                  MediaQuery.sizeOf(context),
                  13,
                  14,
                ),
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            if (codeMeta.isNotEmpty)
              Text(
                '【$codeMeta】',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: codeMetaColor,
                  fontSize: EcjtuMetrics.fluid(
                    MediaQuery.sizeOf(context),
                    10,
                    11,
                  ),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
      _bodyCell(
        widths[1],
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record.courseName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark ? const Color(0xFFF4F7FF) : const Color(0xFF173F5F),
                fontSize: EcjtuMetrics.fluid(
                  MediaQuery.sizeOf(context),
                  14,
                  15,
                ),
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            if (record.englishName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.englishName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFAABBD2)
                      : const Color(0xFF718494),
                  fontSize: EcjtuMetrics.fluid(
                    MediaQuery.sizeOf(context),
                    11,
                    12,
                  ),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
      _bodyText(
        context,
        widths[2],
        record.examType.isEmpty ? '未标注' : record.examType,
      ),
      _bodyText(context, widths[3], _numberLabel(record.credit)),
      _bodyText(context, widths[4], _numberLabel(record.totalHours)),
      _bodyText(context, widths[5], _numberLabel(record.inClassHours)),
      _bodyText(context, widths[6], _numberLabel(record.experimentHours)),
      _bodyText(context, widths[7], _numberLabel(record.computerHours)),
      _bodyText(context, widths[8], _numberLabel(record.otherHours)),
      _bodyText(context, widths[9], record.semesterLabel, rightBorder: false),
    ];
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: CustomPaint(
        foregroundPainter: _CurriculumRowLines(widths, border, isLastRow),
        child: ColoredBox(
          color: hovered ? hoverBody : body,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          ),
        ),
      ),
    );
  }

  Widget _bodyCell(double width, Widget child, {bool rightBorder = true}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      child: child,
    );
  }

  Widget _bodyText(
    BuildContext context,
    double width,
    String value, {
    bool rightBorder = true,
  }) {
    return _bodyCell(
      width,
      Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFDCE8FA)
              : const Color(0xFF111827),
          fontSize: EcjtuMetrics.fluid(MediaQuery.sizeOf(context), 12, 13),
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
      rightBorder: rightBorder,
    );
  }

  String _numberLabel(double value) => _formatCurriculumNumber(value);
}

class _CompactCurriculumTable extends StatelessWidget {
  const _CompactCurriculumTable({required this.records});

  final List<CurriculumRecord> records;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = EcjtuColors.borderFrom(
      context,
      dark ? const Color(0xFF293851) : EcjtuColors.border,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          const _CompactCurriculumRow(
            courseName: '课程名称',
            examType: '考查形式',
            semester: '修读学期',
            header: true,
          ),
          for (final record in records)
            _CompactCurriculumRow(
              courseName: record.courseName,
              examType: record.examType.isEmpty ? '未标注' : record.examType,
              semester: record.semesterLabel,
            ),
        ],
      ),
    );
  }
}

class _CompactCurriculumRow extends StatelessWidget {
  const _CompactCurriculumRow({
    required this.courseName,
    required this.examType,
    required this.semester,
    this.header = false,
  });

  final String courseName;
  final String examType;
  final String semester;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = EcjtuColors.borderFrom(
      context,
      dark ? const Color(0xFF293851) : EcjtuColors.border,
    );
    final muted = EcjtuColors.mutedFrom(
      context,
      dark ? const Color(0xFFAEBDD2) : const Color(0xFF667085),
    );
    final text = EcjtuColors.textFrom(
      context,
      dark ? const Color(0xFFF4F7FF) : EcjtuColors.textPrimary,
    );
    return Container(
      constraints: BoxConstraints(minHeight: header ? 34 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              courseName,
              style: TextStyle(
                color: header ? muted : text,
                fontSize: header ? 10 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              examType,
              style: TextStyle(
                color: header ? muted : text,
                fontSize: header ? 10 : 11,
                fontWeight: header ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              semester,
              style: TextStyle(
                color: header ? muted : text,
                fontSize: header ? 10 : 11,
                fontWeight: header ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurriculumEmpty extends StatelessWidget {
  const _CurriculumEmpty({
    required this.compact,
    required this.title,
    this.detail,
    this.emphasized = true,
  });

  final bool compact;
  final String title;
  final String? detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 76),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: emphasized
                    ? (EcjtuColors.textFor(context))
                    : (EcjtuColors.mutedFrom(
                        context,
                        dark
                            ? const Color(0xFFA9B8D0)
                            : const Color(0xFF98A2B3),
                      )),
                fontSize: compact ? 12 : 17,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
                height: 1,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EcjtuColors.mutedFrom(
                    context,
                    (EcjtuColors.mutedFrom(
                      context,
                      dark ? const Color(0xFFA9B8D0) : const Color(0xFF667085),
                    )),
                  ),
                  fontSize: compact ? 11 : 13,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurriculumRowLines extends CustomPainter {
  const _CurriculumRowLines(this.widths, this.color, this.last);
  final List<double> widths;
  final Color color;
  final bool last;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    for (var i = 0; i < widths.length - 1; i++) {
      x += widths[i];
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    if (!last)
      canvas.drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _CurriculumRowLines old) =>
      old.widths != widths || old.color != color || old.last != last;
}
