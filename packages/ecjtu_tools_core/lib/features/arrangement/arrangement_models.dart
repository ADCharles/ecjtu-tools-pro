// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../calendar/teaching_sections.dart';

class ArrangementSnapshot {
  const ArrangementSnapshot({
    this.schedules = const <ScheduleRecord>[],
    this.exams = const <ExamRecord>[],
    this.registrations = const <RegistrationRecord>[],
    this.currentTerm,
    this.currentWeek,
  });

  final List<ScheduleRecord> schedules;
  final List<ExamRecord> exams;
  final List<RegistrationRecord> registrations;
  final String? currentTerm;
  final int? currentWeek;

  ArrangementSnapshot copyWith({
    List<ScheduleRecord>? schedules,
    List<ExamRecord>? exams,
    List<RegistrationRecord>? registrations,
    String? currentTerm,
    int? currentWeek,
  }) {
    return ArrangementSnapshot(
      schedules: schedules ?? this.schedules,
      exams: exams ?? this.exams,
      registrations: registrations ?? this.registrations,
      currentTerm: currentTerm ?? this.currentTerm,
      currentWeek: currentWeek ?? this.currentWeek,
    );
  }

  List<String> get scheduleTerms =>
      _uniqueSorted(schedules.map((record) => record.term));

  List<String> get examTerms =>
      _uniqueSorted(exams.map((record) => record.term));

  List<String> get registrationTerms =>
      _uniqueSorted(registrations.map((record) => record.term));

  List<int> weeksFor(String term) {
    final weeks = <int>{};
    for (final record in schedules.where((item) => item.term == term)) {
      weeks.addAll(record.weeks);
    }
    if (currentWeek != null) weeks.add(currentWeek!);
    return weeks.toList()..sort();
  }

  static List<String> _uniqueSorted(Iterable<String> values) {
    final result = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    result.sort((left, right) => right.compareTo(left));
    return result;
  }
}

enum ArrangementSection { courses, exams, retakes, experiments }

extension ArrangementSectionDetails on ArrangementSection {
  String get title {
    switch (this) {
      case ArrangementSection.courses:
        return '课程表';
      case ArrangementSection.exams:
        return '考试安排';
      case ArrangementSection.retakes:
        return '补考安排';
      case ArrangementSection.experiments:
        return '实验安排';
    }
  }
}

class ScheduleRecord {
  const ScheduleRecord({
    required this.term,
    required this.weekday,
    required this.sectionStart,
    required this.sectionEnd,
    required this.courseName,
    this.courseCode = '',
    this.courseType = '',
    this.examType = '',
    this.teacher = '',
    this.classroom = '',
    this.weekRange = '',
    this.singleDouble = '',
    this.weeks = const <int>[],
    this.hours,
    this.credit,
    this.smallClassFull = '',
    this.smallClass = '',
    this.smallClassNumber = '',
    this.noScheduledTime = false,
  });

  final String term;
  final int weekday;
  final int sectionStart;
  final int sectionEnd;
  final String courseName;
  final String courseCode;
  final String courseType;
  final String examType;
  final String teacher;
  final String classroom;
  final String weekRange;
  final String singleDouble;
  final List<int> weeks;
  final double? hours;
  final double? credit;
  final String smallClassFull;
  final String smallClass;
  final String smallClassNumber;
  final bool noScheduledTime;

  String get sectionLabel => TeachingSections.label(sectionStart, sectionEnd);
  bool get needsSectionLabel =>
      TeachingSections.needsLabel(sectionStart, sectionEnd);

  bool occursInWeek(int? week) {
    if (week == null || weeks.isEmpty) return true;
    return weeks.contains(week);
  }

  String get compactWeekRange {
    if (weekRange.trim().isNotEmpty) return weekRange.trim();
    if (weeks.isEmpty) return '';
    final sorted = weeks.toSet().toList()..sort();
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
}

class RegistrationRecord {
  const RegistrationRecord({
    required this.term,
    required this.courseCode,
    required this.courseName,
    required this.courseType,
    required this.examType,
    required this.hours,
    required this.credit,
    required this.teachingClass,
    required this.teacher,
    required this.smallClassFull,
    required this.smallClass,
    required this.smallClassNumber,
    required this.scheduleText,
  });

  final String term;
  final String courseCode;
  final String courseName;
  final String courseType;
  final String examType;
  final double hours;
  final double credit;
  final String teachingClass;
  final String teacher;
  final String smallClassFull;
  final String smallClass;
  final String smallClassNumber;
  final String scheduleText;
}

enum ExamArrangementType { regular, retake }

class ExamRecord {
  const ExamRecord({
    required this.term,
    required this.courseName,
    this.date = '',
    this.weekday = '',
    this.teachingClass = '',
    this.startTime = '',
    this.endTime = '',
    this.classroom = '',
    this.seatNumber = '',
    this.courseType = '',
    this.examWeek = '',
    this.batch = '',
    this.type = ExamArrangementType.regular,
  });

  final String term;
  final String courseName;
  final String date;
  final String weekday;
  final String teachingClass;
  final String startTime;
  final String endTime;
  final String classroom;
  final String seatNumber;
  final String courseType;
  final String examWeek;
  final String batch;
  final ExamArrangementType type;

  String get displayDate {
    final match = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})',
    ).firstMatch(date);
    if (match == null) return date;
    return '${match.group(2)}月${match.group(3)}日';
  }
}
