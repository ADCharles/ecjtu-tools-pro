// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'arrangement_models.dart';

String fullSmallClassLabel({
  required String full,
  required String small,
  required String number,
}) => [
  if (full.trim().isNotEmpty)
    full.trim()
  else if (small.trim().isNotEmpty)
    small.trim(),
  if (number.trim().isNotEmpty)
    '${number.trim().replaceFirst(RegExp(r'号$'), '')}号',
].join(' · ');

String compactSmallClassLabel({
  required String full,
  required String small,
  required String number,
}) {
  final text = '$small $full';
  final match = RegExp(
    r'小\s*([0-9一二三四五六七八九十百零〇A-Za-z-]+)\s*班',
  ).firstMatch(text);
  final group = match == null ? '' : '【小${match[1]}班】';
  final serial = number.trim().replaceFirst(RegExp(r'号$'), '');
  return '$group${serial.isEmpty ? '' : '$serial号'}';
}

class SmallClassEntry {
  const SmallClassEntry({
    required this.term,
    required this.course,
    required this.code,
    required this.full,
    required this.small,
    required this.number,
  });
  final String term, course, code, full, small, number;
  String get label =>
      compactSmallClassLabel(full: full, small: small, number: number);
}

List<SmallClassEntry> smallClassEntries(ArrangementSnapshot snapshot) {
  final entries = <String, SmallClassEntry>{};
  void add(SmallClassEntry item) {
    if (item.full.isEmpty && item.small.isEmpty && item.number.isEmpty) return;
    final key =
        '${item.term}|${item.code.isEmpty ? item.course : item.code}|${item.label.isEmpty ? item.full : item.label}';
    final previous = entries[key];
    if (previous == null || (previous.full.isEmpty && item.full.isNotEmpty)) {
      entries[key] = item;
    }
  }

  for (final record in snapshot.registrations) {
    add(
      SmallClassEntry(
        term: record.term,
        course: record.courseName,
        code: record.courseCode,
        full: record.smallClassFull,
        small: record.smallClass,
        number: record.smallClassNumber,
      ),
    );
  }
  for (final record in snapshot.schedules) {
    add(
      SmallClassEntry(
        term: record.term,
        course: record.courseName,
        code: record.courseCode,
        full: record.smallClassFull,
        small: record.smallClass,
        number: record.smallClassNumber,
      ),
    );
  }
  return entries.values.toList()..sort((a, b) {
    final term = b.term.compareTo(a.term);
    return term == 0 ? a.course.compareTo(b.course) : term;
  });
}
