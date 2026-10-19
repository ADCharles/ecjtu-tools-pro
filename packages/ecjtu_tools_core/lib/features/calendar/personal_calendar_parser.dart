// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'calendar_models.dart';
import 'teaching_sections.dart';

class PersonalCalendarParser {
  static CalendarReadResult json(String body, DateTime date) {
    final payload = jsonDecode(body);
    final values = payload is List
        ? payload
        : payload is Map
        ? payload['events']
        : null;
    if (values is! List) throw const FormatException('课程/事项 JSON 需要 events 数组');
    final output = <CalendarCourse>[];
    for (final value in values) {
      if (value is! Map) throw const FormatException('事项必须为 JSON 对象');
      final title =
          '${value['title'] ?? value['courseName'] ?? value['course'] ?? ''}'
              .trim();
      final course =
          '${value['type'] ?? value['kind'] ?? ''}'.toLowerCase() == 'course' ||
          value.containsKey('courseName') ||
          value.containsKey('course') ||
          value.containsKey('sections') ||
          value.containsKey('classSpan') ||
          value.containsKey('sectionStart');
      if (course) {
        _addCourse(output, value, title, date);
        continue;
      }
      final start = _dateTime(value['start'], date);
      final end = _dateTime(value['end'], date);
      if (title.isEmpty ||
          start == null ||
          (value['end'] != null && end == null)) {
        throw const FormatException('事项需要 title、有效的 start 和可选 end');
      }
      final allDay =
          value['allDay'] == true || '${value['start']}'.length == 10;
      _add(
        output,
        title,
        start.toLocal(),
        end?.toLocal(),
        allDay,
        date,
        '${value['location'] ?? ''}',
        '${value['description'] ?? ''}',
      );
    }
    return _result(output, date);
  }

  static CalendarReadResult ics(String body, DateTime date) {
    if (!body.contains('BEGIN:VCALENDAR'))
      throw const FormatException('需要标准 ICS VCALENDAR 文件');
    final lines = body
        .replaceAll(RegExp(r'\r?\n[ \t]'), '')
        .split(RegExp(r'\r?\n'));
    final output = <CalendarCourse>[];
    Map<String, List<(String, String)>>? event;
    for (final line in lines) {
      if (line.trim() == 'BEGIN:VEVENT') {
        event = {};
        continue;
      }
      if (line.trim() == 'END:VEVENT') {
        if (event != null) _icsEvent(event, date, output);
        event = null;
        continue;
      }
      if (event == null) continue;
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final field = line.substring(0, colon);
      event.putIfAbsent(field.split(';').first.toUpperCase(), () => []).add((
        field,
        line.substring(colon + 1),
      ));
    }
    return _result(output, date);
  }

  static void _icsEvent(
    Map<String, List<(String, String)>> event,
    DateTime date,
    List<CalendarCourse> output,
  ) {
    if (event['STATUS']?.first.$2 == 'CANCELLED') return;
    final startField = event['DTSTART']?.first;
    final title = event['SUMMARY']?.first.$2 ?? '';
    if (startField == null || title.isEmpty)
      throw const FormatException('ICS 事项需要 SUMMARY 和 DTSTART');
    var start = _icsTime(startField.$1, startField.$2);
    var end = event['DTEND'] == null
        ? null
        : _icsTime(event['DTEND']!.first.$1, event['DTEND']!.first.$2);
    final allDay = startField.$2.length == 8;
    final rule = event['RRULE']?.first.$2;
    if (rule != null) {
      final fields = <String, String>{
        for (final field in rule.split(';'))
          if (field.contains('='))
            field.split('=').first: field.substring(field.indexOf('=') + 1),
      };
      final frequency = fields['FREQ'];
      if (!['DAILY', 'WEEKLY'].contains(frequency))
        throw const FormatException('ICS 重复规则支持 DAILY 和 WEEKLY');
      if (fields.keys.any(
        (key) => ![
          'FREQ',
          'INTERVAL',
          'BYDAY',
          'UNTIL',
          'COUNT',
          'WKST',
        ].contains(key),
      )) {
        throw const FormatException('ICS 重复规则包含未支持的字段');
      }
      final interval = int.tryParse(fields['INTERVAL'] ?? '1') ?? 1;
      if (interval < 1) throw const FormatException('ICS INTERVAL 必须大于零');
      final until = fields['UNTIL'] == null
          ? null
          : _icsTime('UNTIL', fields['UNTIL']!);
      final target = DateTime(date.year, date.month, date.day);
      final first = DateTime(start.year, start.month, start.day);
      final days = target.difference(first).inDays;
      if (days < 0 ||
          days > 36600 ||
          (until != null &&
              target.isAfter(DateTime(until.year, until.month, until.day))))
        return;
      const names = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final weekdays = (fields['BYDAY'] ?? names[start.weekday - 1]).split(',');
      if (weekdays.any((v) => !names.contains(v)))
        throw const FormatException('ICS BYDAY 必须为星期缩写');
      bool occurs(DateTime day) {
        final elapsed = day.difference(first).inDays;
        if (frequency == 'DAILY')
          return elapsed % interval == 0 &&
              (fields['BYDAY'] == null ||
                  weekdays.contains(names[day.weekday - 1]));
        final weekStart = first.subtract(Duration(days: first.weekday - 1));
        return (day.difference(weekStart).inDays ~/ 7) % interval == 0 &&
            weekdays.contains(names[day.weekday - 1]);
      }

      if (!occurs(target)) return;
      final count = int.tryParse(fields['COUNT'] ?? '');
      if (count != null) {
        var number = 0;
        for (var offset = 0; offset <= days; offset++) {
          if (occurs(first.add(Duration(days: offset)))) number++;
        }
        if (number > count) return;
      }
      final duration = end?.difference(start);
      start = DateTime(
        date.year,
        date.month,
        date.day,
        start.hour,
        start.minute,
        start.second,
      );
      end = duration == null ? null : start.add(duration);
    }
    for (final exclusion in event['EXDATE'] ?? <(String, String)>[]) {
      for (final value in exclusion.$2.split(',')) {
        if (_icsTime(exclusion.$1, value) == start) return;
      }
    }
    final type = event['X-ECJTU-TYPE']?.first.$2.toLowerCase();
    final categories =
        event['CATEGORIES']
            ?.expand((value) => value.$2.split(','))
            .map((value) => value.trim().toLowerCase()) ??
        const <String>[];
    final sectionText = event['X-ECJTU-SECTIONS']?.first.$2 ?? '';
    if (type == 'course' ||
        categories.contains('course') ||
        sectionText.isNotEmpty) {
      final sections = _sections(sectionText);
      final inferred =
          sections ??
          (end == null
              ? (start: 0, end: 0)
              : TeachingSections.forExam(
                  date: _date(start),
                  startTime: _time(start),
                  endTime: _time(end),
                  classroom: _unescape(event['LOCATION']?.first.$2 ?? ''),
                ));
      if (!_sameDay(start, date)) return;
      output.add(
        CalendarCourse(
          courseName: _unescape(title),
          weekday: date.weekday,
          sectionStart: inferred.start,
          sectionEnd: inferred.end,
          eventStart: _time(start),
          eventEnd: end == null ? '' : _time(end),
          classroom: _unescape(event['LOCATION']?.first.$2 ?? ''),
          teacher: _unescape(event['X-ECJTU-TEACHER']?.first.$2 ?? ''),
          courseType: _unescape(event['DESCRIPTION']?.first.$2 ?? ''),
        ),
      );
    } else {
      _add(
        output,
        _unescape(title),
        start,
        end,
        allDay,
        date,
        _unescape(event['LOCATION']?.first.$2 ?? ''),
        _unescape(event['DESCRIPTION']?.first.$2 ?? ''),
      );
    }
  }

  static void _addCourse(
    List<CalendarCourse> output,
    Map value,
    String title,
    DateTime date,
  ) {
    if (title.isEmpty) throw const FormatException('课程需要 title 或 courseName');
    final scheduledDate = _calendarDate(value['date'] ?? value['start'], date);
    if (!_sameDay(scheduledDate, date)) return;
    final start = _dateTime(
      value['start'] ?? value['startTime'],
      scheduledDate,
    );
    final end = _dateTime(value['end'] ?? value['endTime'], scheduledDate);
    final explicit = _sections(
      '${value['sections'] ?? value['classSpan'] ?? value['section'] ?? ''}',
      start: value['sectionStart'],
      end: value['sectionEnd'],
    );
    final classroom =
        '${value['classroom'] ?? value['classRoom'] ?? value['location'] ?? ''}'
            .trim();
    final inferred =
        explicit ??
        (start != null && end != null
            ? TeachingSections.forExam(
                date: _date(scheduledDate),
                startTime: _time(start),
                endTime: _time(end),
                classroom: classroom,
              )
            : (start: 0, end: 0));
    if (inferred.start == 0 && start == null) {
      throw const FormatException('课程需要 sections，或 startTime 与 endTime');
    }
    output.add(
      CalendarCourse(
        courseName: title,
        weekday: date.weekday,
        sectionStart: inferred.start,
        sectionEnd: inferred.end,
        eventStart: start == null ? '' : _time(start),
        eventEnd: end == null ? '' : _time(end),
        classroom: classroom,
        teacher: '${value['teacher'] ?? value['teacherName'] ?? ''}'.trim(),
        weekRange: '${value['weekRange'] ?? value['weekSpan'] ?? ''}'.trim(),
        courseType: '${value['courseType'] ?? value['description'] ?? ''}'
            .trim(),
        teachingClass: '${value['teachingClass'] ?? value['className'] ?? ''}'
            .trim(),
      ),
    );
  }

  static ({int start, int end})? _sections(
    String text, {
    Object? start,
    Object? end,
  }) {
    final numbers = RegExp(
      r'\d{1,2}',
    ).allMatches(text).map((match) => int.parse(match.group(0)!)).toList();
    final first =
        int.tryParse('${start ?? ''}') ??
        (numbers.isEmpty ? null : numbers.first);
    final last =
        int.tryParse('${end ?? ''}') ??
        (numbers.isEmpty ? first : numbers.last);
    if (first == null || last == null || first < 1 || last < first || last > 12)
      return null;
    return (start: first, end: last);
  }

  static DateTime _calendarDate(Object? raw, DateTime fallback) {
    final parsed = DateTime.tryParse('${raw ?? ''}');
    if (parsed == null)
      return DateTime(fallback.year, fallback.month, fallback.day);
    return parsed.toLocal();
  }

  static DateTime? _dateTime(Object? raw, DateTime date) {
    if (raw == null || '$raw'.trim().isEmpty) return null;
    final value = '$raw'.trim();
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '') ?? 0;
    if (hour > 23 || minute > 59 || second > 59) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static DateTime _icsTime(String field, String text) {
    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$',
    ).firstMatch(text.trim());
    if (match == null) throw const FormatException('ICS 日期格式无效');
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final hour = int.tryParse(match[4] ?? '') ?? 0;
    final minute = int.tryParse(match[5] ?? '') ?? 0;
    final second = int.tryParse(match[6] ?? '') ?? 0;
    final zone = RegExp(
      r'TZID=([^;:]+)',
    ).firstMatch(field)?.group(1)?.replaceAll('"', '');
    if (zone != null &&
        ![
          'Asia/Shanghai',
          'Asia/Taipei',
          'Asia/Hong_Kong',
          'UTC',
          'Etc/UTC',
        ].contains(zone)) {
      throw FormatException('暂不支持 ICS 时区 $zone，请使用 UTC 时间');
    }
    if (match[7] != null || zone == 'UTC' || zone == 'Etc/UTC')
      return DateTime.utc(year, month, day, hour, minute, second).toLocal();
    if (zone != null)
      return DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second,
      ).subtract(const Duration(hours: 8)).toLocal();
    return DateTime(year, month, day, hour, minute, second);
  }

  static String _unescape(String text) => text
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\N', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');
  static void _add(
    List<CalendarCourse> output,
    String title,
    DateTime start,
    DateTime? end,
    bool allDay,
    DateTime date,
    String location,
    String detail,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final effectiveEnd =
        end ??
        (allDay
            ? DateTime(start.year, start.month, start.day + 1)
            : start.add(const Duration(minutes: 1)));
    if (!effectiveEnd.isAfter(start))
      throw const FormatException('事项结束时间必须晚于开始时间');
    if (!start.isBefore(day.add(const Duration(days: 1))) ||
        !effectiveEnd.isAfter(day))
      return;
    String time(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    output.add(
      CalendarCourse(
        courseName: title,
        weekday: date.weekday,
        sectionStart: 0,
        sectionEnd: 0,
        personal: true,
        allDay: allDay,
        eventStart: time(start),
        eventEnd: allDay || end == null ? '' : time(end),
        classroom: location,
        teacher: detail,
      ),
    );
  }

  static CalendarReadResult _result(
    List<CalendarCourse> courses,
    DateTime date,
  ) => CalendarReadResult(
    date:
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    weekday: date.weekday,
    courses: courses,
  );
}
