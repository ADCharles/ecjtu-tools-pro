// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'arrangement_models.dart';
import 'score_models.dart';

ArrangementSnapshot mergeArrangementSnapshots(
  ArrangementSnapshot existing,
  ArrangementSnapshot incoming,
) {
  return ArrangementSnapshot(
    schedules: _replaceReportedTerms(
      existing.schedules,
      incoming.schedules,
      (record) => record.term,
      _scheduleKey,
    ),
    exams: _replaceReportedTerms(
      existing.exams,
      incoming.exams,
      (record) => record.term,
      _examKey,
    ),
    registrations: _replaceReportedTerms(
      existing.registrations,
      incoming.registrations,
      (record) => record.term,
      _registrationKey,
    ),
    currentTerm: incoming.currentTerm ?? existing.currentTerm,
    currentWeek: incoming.currentWeek ?? existing.currentWeek,
  );
}

ScoreSnapshot mergeScoreSnapshots(
  ScoreSnapshot existing,
  ScoreSnapshot incoming,
) {
  final records = <String, ScoreRecord>{};
  for (final record in existing.records) {
    records[_scoreKey(record)] = record;
  }
  for (final record in incoming.records) {
    final key = _scoreKey(record);
    final previous = records[key];
    records[key] = previous?.includeOverride == null
        ? record
        : record.copyWith(includeOverride: previous!.includeOverride);
  }
  return ScoreSnapshot(
    records: records.values.toList(growable: false),
    details: <String, List<ScoreDetailRecord>>{
      ...existing.details,
      ...incoming.details,
    },
    studentId: _preferIncoming(incoming.studentId, existing.studentId),
    studentName: _preferIncoming(incoming.studentName, existing.studentName),
    enrollmentStatus: _preferIncoming(
      incoming.enrollmentStatus,
      existing.enrollmentStatus,
    ),
    className: _preferIncoming(incoming.className, existing.className),
    creditRequirements: incoming.creditRequirements.isNotEmpty
        ? incoming.creditRequirements
        : existing.creditRequirements,
    pageGpa: _preferIncoming(incoming.pageGpa, existing.pageGpa),
  );
}

List<T> _replaceReportedTerms<T>(
  Iterable<T> existing,
  Iterable<T> incoming,
  String Function(T record) termOf,
  String Function(T record) keyOf,
) {
  final fresh = incoming.toList(growable: false);
  final reportedTerms = fresh
      .map(termOf)
      .map((term) => term.trim())
      .where((term) => term.isNotEmpty)
      .toSet();
  final merged = <String, T>{};
  for (final record in existing) {
    if (!reportedTerms.contains(termOf(record).trim())) {
      merged[keyOf(record)] = record;
    }
  }
  for (final record in fresh) {
    merged[keyOf(record)] = record;
  }
  return merged.values.toList(growable: false);
}

String _scheduleKey(ScheduleRecord record) => <Object>[
  record.term,
  record.courseCode.isEmpty ? record.courseName : record.courseCode,
  record.weekday,
  record.sectionStart,
  record.sectionEnd,
  record.weekRange,
  record.classroom,
].join('|');

String _examKey(ExamRecord record) => <Object>[
  record.term,
  record.courseName,
  record.type.name,
  record.date,
  record.startTime,
  record.classroom,
].join('|');

String _registrationKey(RegistrationRecord record) => <Object>[
  record.term,
  record.courseCode.isEmpty ? record.courseName : record.courseCode,
  record.teachingClass,
].join('|');

String _scoreKey(ScoreRecord record) => <Object>[
  record.term,
  record.courseCode.isEmpty ? record.courseName : record.courseCode,
].join('|');

String _preferIncoming(String incoming, String existing) =>
    incoming.trim().isNotEmpty ? incoming : existing;
