// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_models.dart';
import 'calendar_cache_window.dart';

class CalendarResultCache {
  CalendarResultCache({
    this.days = 5,
    this.persistent = true,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final int days;
  final bool persistent;
  static final _sessionEntries = <String, Map<String, dynamic>>{};

  static void clearSession() => _sessionEntries.clear();
  final DateTime Function() now;

  static String _key(String scope) => 'ecjtu.calendar.days.$scope';
  static Map<String, dynamic> encode(CalendarReadResult r) => {
    'date': r.date,
    'source': r.source.name,
    'term': r.term,
    'teachingWeek': r.teachingWeek,
    'weekday': r.weekday,
    'weekStart': r.weekStart,
    'courses': [
      for (final c in r.courses)
        {
          'courseName': c.courseName,
          'weekday': c.weekday,
          'sectionStart': c.sectionStart,
          'sectionEnd': c.sectionEnd,
          'teacher': c.teacher,
          'classroom': c.classroom,
          'weekRange': c.weekRange,
          'courseType': c.courseType,
          'teachingClass': c.teachingClass,
          'pkType': c.pkType,
          'weeks': c.weeks,
          'eventStart': c.eventStart,
          'eventEnd': c.eventEnd,
          'allDay': c.allDay,
          'personal': c.personal,
        },
    ],
  };
  static CalendarReadResult decode(Map<String, dynamic> m) =>
      CalendarReadResult(
        date: m['date'] as String,
        source: CalendarResultSource.values.byName(m['source'] as String),
        term: m['term'] as String?,
        teachingWeek: m['teachingWeek'] as int?,
        weekday: m['weekday'] as int?,
        weekStart: m['weekStart'] as String?,
        courses: [
          for (final c in m['courses'] as List)
            CalendarCourse(
              courseName: c['courseName'],
              weekday: c['weekday'],
              sectionStart: c['sectionStart'],
              sectionEnd: c['sectionEnd'],
              teacher: c['teacher'],
              classroom: c['classroom'],
              weekRange: c['weekRange'],
              courseType: c['courseType'],
              teachingClass: c['teachingClass'],
              pkType: c['pkType'],
              weeks: List<int>.from(c['weeks']),
              eventStart: c['eventStart'] as String? ?? '',
              eventEnd: c['eventEnd'] as String? ?? '',
              allDay: c['allDay'] == true,
              personal: c['personal'] == true,
            ),
        ],
      );
  Future<Map<String, dynamic>> _entries(String scope) async {
    final p = await SharedPreferences.getInstance();
    try {
      final entries = persistent
          ? Map<String, dynamic>.from(
              jsonDecode(p.getString(_key(scope)) ?? '{}'),
            )
          : Map<String, dynamic>.from(_sessionEntries[scope] ?? {});
      if (!persistent) await p.remove(_key(scope));
      final before = entries.length;
      final cutoff = now().subtract(const Duration(days: 30));
      entries.removeWhere(
        (date, v) =>
            !CalendarCacheWindow.contains(
              DateTime.parse(date),
              days: days,
              today: now(),
            ) ||
            DateTime.parse(v['savedAt']).isBefore(cutoff),
      );
      if (before != entries.length) {
        await _save(scope, entries);
      }
      return entries;
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(String scope, Map<String, dynamic> entries) async {
    _sessionEntries[scope] = entries;
    final p = await SharedPreferences.getInstance();
    if (persistent) {
      await p.setString(_key(scope), jsonEncode(entries));
    } else {
      await p.remove(_key(scope));
    }
  }

  Future<CalendarReadResult?> read(String scope, String date) async {
    try {
      final entry = (await _entries(scope))[date];
      return entry == null
          ? null
          : decode(Map<String, dynamic>.from(entry['result']));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String scope, CalendarReadResult result) async {
    if (!result.isSuccess || result.code != null) return;
    final entries = await _entries(scope);
    if (!CalendarCacheWindow.contains(
      DateTime.parse(result.date),
      days: days,
      today: now(),
    ))
      return;
    entries.remove(result.date);
    entries[result.date] = {
      'savedAt': now().toIso8601String(),
      'result': encode(result),
    };
    while (entries.length > days.clamp(0, 365) * 2 + 1) {
      entries.remove(entries.keys.first);
    }
    await _save(scope, entries);
  }
}
