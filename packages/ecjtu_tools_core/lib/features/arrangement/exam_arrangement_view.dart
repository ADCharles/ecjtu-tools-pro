// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import 'arrangement_models.dart';

class ExamArrangementView extends StatelessWidget {
  const ExamArrangementView({
    super.key,
    required this.records,
    required this.term,
    required this.type,
    this.synced = false,
    this.loading = false,
    this.showLoadingIndicator = true,
  });

  final List<ExamRecord> records;
  final String? term;
  final ExamArrangementType type;
  final bool synced;
  final bool loading;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    final filtered =
        records
            .where(
              (record) =>
                  record.type == type &&
                  (term == null || term == 'all' || record.term == term),
            )
            .toList()
          ..sort((left, right) {
            final termResult = right.term.compareTo(left.term);
            if (termResult != 0) return termResult;
            return '${right.date} ${right.startTime}'.compareTo(
              '${left.date} ${left.startTime}',
            );
          });
    if (filtered.isEmpty) {
      if (loading && !synced) {
        if (!showLoadingIndicator) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            type == ExamArrangementType.retake ? '正在读取补考安排' : '正在读取考试安排',
          ),
        );
      }
      return Container(
        width: double.infinity,
        child: ArrangementEmptyState(
          title: type == ExamArrangementType.retake ? '补考安排' : '考试安排',
          synced: synced,
        ),
      );
    }
    final groups = <String, List<ExamRecord>>{};
    for (final record in filtered) {
      groups.putIfAbsent(record.term, () => []).add(record);
    }
    final entries = groups.entries.toList();
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const SizedBox(height: 22),
            _TermGroup(
              term: entries[index].key,
              records: entries[index].value,
              type: type,
            ),
          ],
        ],
      ),
    );
  }
}

class _TermGroup extends StatelessWidget {
  const _TermGroup({
    required this.term,
    required this.records,
    required this.type,
  });

  final String term;
  final List<ExamRecord> records;
  final ExamArrangementType type;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArrangementTermHeading(
          term: term,
          count: records.length,
          label: type == ExamArrangementType.retake ? '补考' : '考试',
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: EcjtuColors.borderFrom(
                  context,
                  dark ? const Color(0xFF2A3A46) : const Color(0xFFDCE7EF),
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final record in records)
                _ExamRow(record: record, type: type),
            ],
          ),
        ),
      ],
    );
  }
}

class ArrangementTermHeading extends StatelessWidget {
  const ArrangementTermHeading({
    super.key,
    required this.term,
    required this.count,
    required this.label,
    this.unit = '场',
  });

  final String term;
  final int count;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF36577D) : const Color(0xFFBCD5E5),
            ),
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              term,
              style: TextStyle(
                color: EcjtuColors.textFrom(
                  context,
                  dark ? const Color(0xFFDCEAFF) : const Color(0xFF123F5F),
                ),
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count $unit$label',
            style: TextStyle(
              color: EcjtuColors.mutedFrom(
                context,
                dark ? const Color(0xFF9EACC3) : const Color(0xFF748998),
              ),
              fontSize: compact ? 11 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({required this.record, required this.type});

  final ExamRecord record;
  final ExamArrangementType type;

  @override
  Widget build(BuildContext context) {
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    final time = [
      record.startTime,
      record.endTime,
    ].where((value) => value.isNotEmpty).join(' - ');
    final details = [
      '考试时间：${time.isEmpty ? '待定' : time}',
      '考试地点：${record.classroom.isEmpty ? '待定' : record.classroom}',
      if (type == ExamArrangementType.regular || record.seatNumber.isNotEmpty)
        '小班序号：${record.seatNumber.isEmpty ? '待定' : record.seatNumber}',
    ];
    final meta = [
      record.courseType,
      if (record.examWeek.isNotEmpty) '第 ${record.examWeek} 周',
      if (record.batch.isNotEmpty) '考试人数：${record.batch}',
    ].where((value) => value.isNotEmpty).join(' · ');
    final detailTextStyle = arrangementStrongText(context, compact ? 12 : 15);
    final detailsView = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < details.length; index++) ...[
                if (index > 0) const SizedBox(height: 4),
                Text(details[index], style: detailTextStyle),
              ],
            ],
          )
        : Wrap(
            spacing: 16,
            runSpacing: 7,
            children: [
              for (final detail in details)
                Text(detail, style: detailTextStyle),
            ],
          );
    return ArrangementRecordRow(
      timing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            record.displayDate,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF155F91),
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.weekday,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF7A8D9B),
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
      title: record.courseName,
      subtitle: record.teachingClass,
      details: detailsView,
      meta: meta,
    );
  }
}

class ArrangementRecordRow extends StatelessWidget {
  const ArrangementRecordRow({
    super.key,
    required this.timing,
    required this.title,
    this.subtitle = '',
    required this.details,
    this.meta = '',
    this.background,
  });
  final Widget timing, details;
  final String title, subtitle, meta;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 14 : 18),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF2B3B47) : const Color(0xFFE4EDF3),
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ArrangementTimingColumn(child: timing),
          SizedBox(width: compact ? 10 : 18),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: EcjtuColors.textFrom(
                      context,
                      dark ? const Color(0xFFF4F7FF) : const Color(0xFF172B3A),
                    ),
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(subtitle, style: _examText(context, compact ? 13 : 15)),
                ],
                details,
                if (meta.isNotEmpty) ...[
                  Text(meta, style: _examMetaText(context, compact ? 12 : 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ArrangementEmptyState extends StatelessWidget {
  const ArrangementEmptyState({required this.title, required this.synced});

  final String title;
  final bool synced;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 58),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '暂无$title',
            style: TextStyle(
              color: EcjtuColors.textFrom(
                context,
                dark ? const Color(0xFFE8F0FC) : const Color(0xFF17202F),
              ),
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            synced ? '当前学期没有相关安排' : '点击右上角“获取最新数据”',
            style: TextStyle(
              color: EcjtuColors.mutedFrom(
                context,
                dark ? const Color(0xFF9EACC3) : const Color(0xFF7B8492),
              ),
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _examText(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    color: EcjtuColors.mutedFrom(
      context,
      dark ? const Color(0xFFA9B8D0) : const Color(0xFF617484),
    ),
    fontSize: size,
    height: 1.5,
  );
}

TextStyle arrangementStrongText(BuildContext context, double size) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    color: EcjtuColors.textFrom(
      context,
      dark ? const Color(0xFFDCEAFF) : const Color(0xFF294B62),
    ),
    fontSize: size,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _examMetaText(BuildContext context, double size) {
  return TextStyle(color: const Color(0xFF8494A1), fontSize: size);
}

class ArrangementTimingColumn extends StatelessWidget {
  const ArrangementTimingColumn({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: EcjtuMetrics.isCompact(MediaQuery.sizeOf(context)) ? 72 : 92,
    child: child,
  );
}
