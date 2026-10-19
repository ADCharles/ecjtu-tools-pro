// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'calendar_models.dart';

class CalendarAcademicStorage {
  static const _keyPrefix = 'ecjtu.calendar.academic.';

  Future<CalendarAcademicState> read(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return const CalendarAcademicState();
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key(target));
      if (raw == null || raw.isEmpty) return const CalendarAcademicState();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const CalendarAcademicState();
      final rawAnchors = decoded['anchors'];
      final anchors = <String, CalendarAcademicAnchor>{};
      if (rawAnchors is Map) {
        for (final entry in rawAnchors.entries) {
          final anchor = CalendarAcademicAnchor.fromJson(entry.value);
          if (anchor != null) anchors[entry.key.toString()] = anchor;
        }
      }
      return CalendarAcademicState(
        currentTerm: decoded['currentTerm']?.toString().trim() ?? '',
        anchors: anchors,
      );
    } catch (_) {
      return const CalendarAcademicState();
    }
  }

  Future<CalendarAcademicState> saveAnchor(
    String studentId,
    CalendarAcademicAnchor anchor, {
    bool setCurrentTerm = false,
  }) async {
    final current = await read(studentId);
    final previous = current.anchorFor(anchor.term, source: anchor.source);
    final start = DateTime.tryParse(anchor.weekStart);
    if (start != null &&
        previous?.teachingWeekFor(start) == anchor.teachingWeek &&
        (!setCurrentTerm || current.currentTerm == anchor.term)) {
      return current;
    }
    final next = current.withAnchor(anchor, setCurrentTerm: setCurrentTerm);
    await _write(studentId, next);
    return next;
  }

  Future<CalendarAcademicState> saveCurrentTerm(
    String studentId,
    String term,
  ) async {
    final normalized = term.trim();
    if (!RegExp(r'^20\d{2}\.[12]$').hasMatch(normalized)) {
      return read(studentId);
    }
    final current = await read(studentId);
    if (current.currentTerm == normalized) return current;
    final next = current.withCurrentTerm(normalized);
    await _write(studentId, next);
    return next;
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primaryId = primaryStudentId.trim();
    final aliasId = aliasStudentId.trim();
    if (primaryId.isEmpty || aliasId.isEmpty || primaryId == aliasId) return;
    final primary = await read(primaryId);
    final alias = await read(aliasId);
    await _write(
      primaryId,
      CalendarAcademicState(
        currentTerm: primary.currentTerm.isNotEmpty
            ? primary.currentTerm
            : alias.currentTerm,
        anchors: {...alias.anchors, ...primary.anchors},
      ),
    );
    await clear(aliasId);
  }

  Future<void> clear(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(target));
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_keyPrefix),
    )) {
      await preferences.remove(key);
    }
  }

  Future<void> _write(String studentId, CalendarAcademicState state) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(target),
      jsonEncode({
        'version': 1,
        'currentTerm': state.currentTerm,
        'anchors': {
          for (final entry in state.anchors.entries)
            entry.key: entry.value.toJson(),
        },
      }),
    );
  }

  String _key(String studentId) =>
      '$_keyPrefix${Uri.encodeComponent(studentId.trim())}';
}
