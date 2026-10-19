// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'calendar_models.dart';

class TeachingWeekSession {
  final _anchors = <String, CalendarAcademicAnchor>{};
  int? weekFor(String studentId, DateTime date) {
    final anchor = _anchors[studentId];
    if (anchor?.term != CalendarContextResolver.academicTermForDate(date)) {
      return null;
    }
    return anchor?.teachingWeekFor(date);
  }

  void restore(String studentId, CalendarAcademicState state, DateTime date) {
    final anchor = state.anchorForDate(date);
    if (anchor != null) _anchors[studentId] = anchor;
  }

  void observe(String studentId, CalendarReadResult result, DateTime date) {
    if (!result.isSuccess ||
        result.teachingWeek == null ||
        result.teachingWeek! < 1 ||
        result.teachingWeek! > 30)
      return;
    final term = CalendarContextResolver.academicTermForDate(date);
    final previous = _anchors[studentId];
    if (previous?.term == term &&
        previous?.teachingWeekFor(date) == result.teachingWeek)
      return;
    _anchors[studentId] = CalendarAcademicAnchor.fromDate(
      term: term,
      teachingWeek: result.teachingWeek!,
      date: date,
      source: result.source.name,
    );
  }

  void clear([String? studentId]) {
    if (studentId == null) {
      _anchors.clear();
    } else {
      _anchors.remove(studentId);
    }
  }
}
