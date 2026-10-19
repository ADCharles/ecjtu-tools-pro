// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'teaching_sections.dart';
import '../arrangement/arrangement_models.dart';

class CalendarCourse {
  const CalendarCourse({
    required this.courseName,
    required this.weekday,
    required this.sectionStart,
    required this.sectionEnd,
    this.eventStart = '',
    this.eventEnd = '',
    this.allDay = false,
    this.personal = false,
    this.teacher = '',
    this.classroom = '',
    this.weekRange = '',
    this.courseType = '',
    this.teachingClass = '',
    this.pkType = '',
    this.weeks = const <int>[],
  });

  final String courseName;
  final int weekday;
  final int sectionStart;
  final int sectionEnd;
  final String eventStart;
  final String eventEnd;
  final bool allDay;
  final bool personal;
  final String teacher;
  final String classroom;
  final String weekRange;
  final String courseType;
  final String teachingClass;
  final String pkType;
  final List<int> weeks;

  factory CalendarCourse.fromExamRecord(ExamRecord exam) {
    final sections = TeachingSections.forExam(
      date: exam.date,
      startTime: exam.startTime,
      endTime: exam.endTime,
      classroom: exam.classroom,
    );
    return CalendarCourse(
      courseName: exam.courseName,
      weekday: DateTime.tryParse(exam.date)?.weekday ?? 0,
      sectionStart: sections.start,
      sectionEnd: sections.end,
      pkType: exam.type == ExamArrangementType.retake ? '补考' : '考试',
      classroom: exam.classroom,
      teacher: [
        if (exam.startTime.isNotEmpty) '${exam.startTime}–${exam.endTime}',
        if (exam.seatNumber.isNotEmpty) '座位 ${exam.seatNumber}',
      ].join(' · '),
    );
  }

  factory CalendarCourse.fromScheduleRecord(ScheduleRecord record) {
    return CalendarCourse(
      courseName: record.courseName,
      weekday: record.weekday,
      sectionStart: record.sectionStart,
      sectionEnd: record.sectionEnd,
      teacher: record.teacher,
      classroom: record.classroom,
      weekRange: record.weekRange,
      courseType: record.courseType,
      teachingClass: record.smallClassFull,
      weeks: record.weeks,
    );
  }

  ScheduleRecord toScheduleRecord(String term) {
    return ScheduleRecord(
      term: term,
      weekday: weekday,
      sectionStart: sectionStart,
      sectionEnd: sectionEnd,
      courseName: courseName,
      teacher: teacher,
      classroom: classroom,
      weekRange: weekRange,
      weeks: weeks,
      courseType: courseType,
      smallClassFull: teachingClass,
      smallClass: teachingClass,
    );
  }
}

class CalendarReadResult {
  const CalendarReadResult({
    required this.date,
    this.courses = const <CalendarCourse>[],
    this.source = CalendarResultSource.student,
    this.error,
    this.code,
    this.term,
    this.teachingWeek,
    this.weekday,
    this.weekStart,
  });

  final String date;
  final List<CalendarCourse> courses;
  final CalendarResultSource source;
  final String? error;
  final String? code;
  final String? term;
  final int? teachingWeek;
  final int? weekday;
  final String? weekStart;

  bool get isSuccess => error == null;
  bool get hasCourses => courses.isNotEmpty;
  bool get sessionExpired => code == 'SESSION_EXPIRED';
  bool get hasSession => code != 'NO_SESSION' && !sessionExpired;

  CalendarReadResult copyWith({
    String? date,
    List<CalendarCourse>? courses,
    CalendarResultSource? source,
    String? error,
    String? code,
    String? term,
    int? teachingWeek,
    int? weekday,
    String? weekStart,
  }) {
    return CalendarReadResult(
      date: date ?? this.date,
      courses: courses ?? this.courses,
      source: source ?? this.source,
      error: error ?? this.error,
      code: code ?? this.code,
      term: term ?? this.term,
      teachingWeek: teachingWeek ?? this.teachingWeek,
      weekday: weekday ?? this.weekday,
      weekStart: weekStart ?? this.weekStart,
    );
  }
}

enum CalendarResultSource { student, wechat }

class CalendarAcademicContext {
  const CalendarAcademicContext({this.term = '', this.teachingWeek});

  final String term;
  final int? teachingWeek;

  String get displayText {
    if (term.isEmpty) return '当前学期';
    final week = teachingWeek;
    return week == null ? term : '$term 第$week周';
  }
}

class CalendarAcademicAnchor {
  const CalendarAcademicAnchor({
    required this.term,
    required this.teachingWeek,
    required this.weekStart,
    this.weekday = 1,
    this.source = 'wechat',
    this.updatedAt,
  });

  factory CalendarAcademicAnchor.fromDate({
    required String term,
    required int teachingWeek,
    required DateTime date,
    String source = 'student',
  }) {
    final monday = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    final key =
        '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    return CalendarAcademicAnchor(
      term: term,
      teachingWeek: teachingWeek,
      weekStart: key,
      weekday: date.weekday,
      source: source,
      updatedAt: DateTime.now(),
    );
  }

  final String term;
  final int teachingWeek;
  final String weekStart;
  final int weekday;
  final String source;
  final DateTime? updatedAt;

  int? teachingWeekFor(DateTime date) {
    final start = _parseDate(weekStart);
    if (start == null || teachingWeek < 1) return null;
    final days = DateUtilsLike.dateOnly(
      date,
    ).difference(DateUtilsLike.dateOnly(start)).inDays;
    final value = teachingWeek + (days / 7).floor();
    return value >= 1 && value <= 30 ? value : null;
  }

  Map<String, dynamic> toJson() => {
    'term': term,
    'teachingWeek': teachingWeek,
    'weekStart': weekStart,
    'weekday': weekday,
    'source': source,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static CalendarAcademicAnchor? fromJson(Object? value) {
    if (value is! Map) return null;
    final term = value['term']?.toString().trim() ?? '';
    final weekStart = value['weekStart']?.toString().trim() ?? '';
    final teachingWeek = int.tryParse(value['teachingWeek']?.toString() ?? '');
    final weekday = int.tryParse(value['weekday']?.toString() ?? '') ?? 1;
    if (!RegExp(r'^20\d{2}\.[12]$').hasMatch(term) ||
        teachingWeek == null ||
        teachingWeek < 1 ||
        teachingWeek > 30 ||
        _parseDate(weekStart) == null) {
      return null;
    }
    return CalendarAcademicAnchor(
      term: term,
      teachingWeek: teachingWeek,
      weekStart: weekStart,
      weekday: weekday.clamp(1, 7).toInt(),
      source: value['source']?.toString().trim().isNotEmpty == true
          ? value['source'].toString().trim()
          : 'wechat',
      updatedAt: DateTime.tryParse(value['updatedAt']?.toString() ?? ''),
    );
  }

  static DateTime? _parseDate(String value) {
    final match = RegExp(
      r'^(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final result = DateTime(year, month, day);
    return result.year == year && result.month == month && result.day == day
        ? result
        : null;
  }
}

class CalendarAcademicState {
  const CalendarAcademicState({
    this.currentTerm = '',
    this.anchors = const <String, CalendarAcademicAnchor>{},
  });

  final String currentTerm;
  final Map<String, CalendarAcademicAnchor> anchors;

  CalendarAcademicAnchor? anchorFor(String term, {String? source}) {
    final anchor = source == null
        ? anchors[term.trim()]
        : anchors['${term.trim()}|$source'];
    if (anchor != null) return anchor;
    final legacy = anchors[term.trim()];
    return source == null || legacy?.source == source ? legacy : null;
  }

  CalendarAcademicAnchor? anchorForDate(DateTime date) {
    final term = CalendarContextResolver.academicTermForDate(date);
    return anchorFor(term) ??
        (DateUtilsLike.isSameDate(date, DateTime.now())
            ? anchorFor(currentTerm)
            : null);
  }

  CalendarAcademicState withAnchor(
    CalendarAcademicAnchor anchor, {
    bool setCurrentTerm = false,
  }) {
    return CalendarAcademicState(
      currentTerm: setCurrentTerm ? anchor.term : currentTerm,
      anchors: {
        ...anchors,
        anchor.term: anchor,
        '${anchor.term}|${anchor.source}': anchor,
      },
    );
  }

  CalendarAcademicState withCurrentTerm(String term) {
    return CalendarAcademicState(currentTerm: term.trim(), anchors: anchors);
  }
}

class CalendarContextResolver {
  const CalendarContextResolver._();

  static CalendarAcademicContext resolve({
    required CalendarReadResult result,
    required ArrangementSnapshot arrangement,
    required DateTime date,
    bool manualFallback = false,
    String manualSemester = '',
    int manualWeek = 1,
    int manualWeekDay = 1,
    CalendarAcademicAnchor? academicAnchor,
  }) {
    final dateTerm = academicTermForDate(date);
    final explicitTerm = _validTerm(result.term ?? '');
    final manualTerm = manualFallback ? _validTerm(manualSemester) : null;
    final courseTerm = _termFromCourses(result.courses, arrangement, dateTerm);
    // The student-calendar response can contain a current-term field that is
    // not scoped to the requested date. The selected date is therefore the
    // primary source for automatic term display.
    final inferredTerm = dateTerm.isNotEmpty
        ? dateTerm
        : (courseTerm ?? explicitTerm ?? '');
    final term = manualTerm ?? inferredTerm;
    final week = manualFallback
        ? _manualWeek(
            manualWeek: manualWeek,
            manualWeekDay: manualWeekDay,
            date: date,
          )
        : _validWeek(result.teachingWeek) ??
              academicAnchor?.teachingWeekFor(date);
    return CalendarAcademicContext(term: term, teachingWeek: week);
  }

  static int? inferTeachingWeekFromCourses({
    required Iterable<CalendarCourse> courses,
    required ArrangementSnapshot arrangement,
    required String term,
    required int weekday,
  }) {
    final normalizedTerm = _validTerm(term);
    if (normalizedTerm == null || weekday < 1 || weekday > 7) return null;
    final observed = courses
        .where((course) => course.weekday == weekday)
        .map((course) => _normalize(course.courseName))
        .where((name) => name.length >= 3)
        .toSet();
    if (observed.isEmpty) return null;
    final dayRecords = arrangement.schedules.where(
      (record) =>
          record.term == normalizedTerm &&
          record.weekday == weekday &&
          !record.noScheduledTime,
    );
    final candidates = <int>[];
    for (var week = 1; week <= 30; week++) {
      final expected = dayRecords
          .where((record) => record.occursInWeek(week))
          .map((record) => _normalize(record.courseName))
          .where((name) => name.isNotEmpty)
          .toSet();
      if (expected.length == observed.length &&
          observed.every(expected.contains)) {
        candidates.add(week);
      }
    }
    return candidates.length == 1 ? candidates.single : null;
  }

  static String academicTermForDate(DateTime date) {
    final month = date.month;
    if (month >= 9) return '${date.year}.1';
    if (month == 1) return '${date.year - 1}.1';
    return '${date.year - 1}.2';
  }

  static String? _termFromCourses(
    Iterable<CalendarCourse> courses,
    ArrangementSnapshot arrangement,
    String fallback,
  ) {
    final votes = <String, int>{};
    for (final course in courses) {
      final bestByTerm = <String, int>{};
      for (final record in arrangement.schedules) {
        if (_validTerm(record.term) == null ||
            !_courseMatches(course, record)) {
          continue;
        }
        final weight = _courseMatchWeight(course, record);
        final previous = bestByTerm[record.term] ?? 0;
        if (weight > previous) bestByTerm[record.term] = weight;
      }
      for (final entry in bestByTerm.entries) {
        votes[entry.key] = (votes[entry.key] ?? 0) + entry.value;
      }
    }
    if (votes.isEmpty) return null;
    final ranked = votes.entries.toList()
      ..sort((left, right) {
        final byWeight = right.value.compareTo(left.value);
        if (byWeight != 0) return byWeight;
        if (left.key == fallback) return -1;
        if (right.key == fallback) return 1;
        return right.key.compareTo(left.key);
      });
    return _validTerm(ranked.first.key) != null ? ranked.first.key : null;
  }

  static int? _validWeek(int? value) {
    return value != null && value >= 1 && value <= 30 ? value : null;
  }

  static bool _courseMatches(CalendarCourse course, ScheduleRecord record) {
    final left = _normalize(course.courseName);
    final right = _normalize(record.courseName);
    if (left.isEmpty || right.isEmpty) return false;
    return left == right || left.contains(right) || right.contains(left);
  }

  static int _courseMatchWeight(CalendarCourse course, ScheduleRecord record) {
    final left = _normalize(course.courseName);
    final right = _normalize(record.courseName);
    var weight = left == right ? 4 : 2;
    if (_sameText(course.teacher, record.teacher)) weight += 2;
    if (_sameText(course.classroom, record.classroom)) weight += 1;
    return weight;
  }

  static bool _sameText(String left, String right) {
    final a = _normalize(left);
    final b = _normalize(right);
    return a.isNotEmpty &&
        b.isNotEmpty &&
        (a == b || a.contains(b) || b.contains(a));
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s·•,，。；;:：()（）\[\]【】{}「」『』]'), '')
        .trim();
  }

  static String? _validTerm(String value) {
    return RegExp(r'^20\d{2}\.[12]$').hasMatch(value.trim())
        ? value.trim()
        : null;
  }

  static int _manualWeek({
    required int manualWeek,
    required int manualWeekDay,
    required DateTime date,
  }) {
    final today = DateUtilsLike.dateOnly(DateTime.now());
    final selected = DateUtilsLike.dateOnly(date);
    final delta = selected.difference(today).inDays;
    final offset = ((manualWeekDay.clamp(1, 7) - 1 + delta) / 7).floor();
    return (manualWeek.clamp(1, 30).toInt() + offset).clamp(1, 30).toInt();
  }
}

class DateUtilsLike {
  const DateUtilsLike._();

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDate(DateTime left, DateTime right) {
    final a = dateOnly(left);
    final b = dateOnly(right);
    return a == b;
  }
}
