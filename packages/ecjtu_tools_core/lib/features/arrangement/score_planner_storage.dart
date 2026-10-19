// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'score_models.dart';

class ScorePlannerSnapshot {
  const ScorePlannerSnapshot({
    this.targetGpa = 4,
    this.term = '',
    this.courses = const <String, PlannedCourse>{},
  });

  final double targetGpa;
  final String term;
  final Map<String, PlannedCourse> courses;

  static ScorePlannerSnapshot fromJson(Object? value) {
    final map = _map(value);
    final courses = <String, PlannedCourse>{};
    final rawCourses = _map(map['courses']);
    rawCourses.forEach((key, value) {
      final item = _map(value);
      final identity = key.toString().trim();
      final term = _text(item['term']);
      final name = _text(item['courseName']);
      final credit = _double(item['credit']);
      if (identity.isEmpty || term.isEmpty || name.isEmpty || credit <= 0) {
        return;
      }
      final mode = item['gradeMode']?.toString() == 'level'
          ? PlannedGradeMode.level
          : PlannedGradeMode.numeric;
      final plannedScore = _text(item['plannedScore']);
      final manual = item['manual'] == true;
      courses[identity] = PlannedCourse(
        key: identity,
        term: term,
        courseName: name,
        credit: credit,
        gradeMode: mode,
        maxScore: _double(
          item['maxScore'],
          fallback: 100,
        ).clamp(30, 100).toDouble(),
        maxLevel: _level(item['maxLevel']),
        plannedScore: plannedScore,
        manual: manual,
      );
    });
    final target = _double(
      map['targetGpa'],
      fallback: 4,
    ).clamp(0, 5).toDouble();
    return ScorePlannerSnapshot(
      targetGpa: target,
      term: _text(map['term']),
      courses: courses,
    );
  }

  Map<String, dynamic> toJson() => {
    'targetGpa': targetGpa,
    'term': term,
    'courses': courses.map((key, course) {
      return MapEntry(key, {
        'term': course.term,
        'courseName': course.courseName,
        'credit': course.credit,
        'gradeMode': course.gradeMode == PlannedGradeMode.level
            ? 'level'
            : 'numeric',
        'maxScore': course.maxScore,
        'maxLevel': course.maxLevel,
        'plannedScore': course.plannedScore,
        'manual': course.manual,
      });
    }),
  };
}

class ScorePlannerStorage {
  static const _keyPrefix = 'ecjtu.arrangement.score_planner.';
  static final _loaded = <String, ScorePlannerSnapshot>{};

  static SharedPreferences? _preferences;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  ScorePlannerSnapshot? readLoaded(String studentId) {
    final target = studentId.trim();
    if (target.isEmpty) return const ScorePlannerSnapshot();
    final loaded = _loaded[target];
    if (loaded != null) return loaded;
    final preferences = _preferences;
    if (preferences == null) return null;
    return _loaded.putIfAbsent(target, () {
      try {
        final raw = preferences.getString(_key(target));
        return raw == null || raw.isEmpty
            ? const ScorePlannerSnapshot()
            : ScorePlannerSnapshot.fromJson(jsonDecode(raw));
      } catch (_) {
        return const ScorePlannerSnapshot();
      }
    });
  }

  Future<ScorePlannerSnapshot> read(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return const ScorePlannerSnapshot();
    final loaded = readLoaded(target);
    if (loaded != null) return loaded;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key(target));
      final snapshot = raw == null || raw.isEmpty
          ? const ScorePlannerSnapshot()
          : ScorePlannerSnapshot.fromJson(jsonDecode(raw));
      return _loaded.putIfAbsent(target, () => snapshot);
    } catch (_) {
      return const ScorePlannerSnapshot();
    }
  }

  Future<void> write(String studentId, ScorePlannerSnapshot snapshot) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    _loaded[target] = snapshot;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(target), jsonEncode(snapshot.toJson()));
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primaryId = primaryStudentId.trim();
    final aliasId = aliasStudentId.trim();
    if (primaryId.isEmpty || aliasId.isEmpty || primaryId == aliasId) return;
    final primary = await read(primaryId);
    final alias = await read(aliasId);
    final courses = <String, PlannedCourse>{
      ...alias.courses,
      ...primary.courses,
    };
    final selected = primary.courses.isNotEmpty ? primary : alias;
    await write(
      primaryId,
      ScorePlannerSnapshot(
        targetGpa: selected.targetGpa,
        term: selected.term,
        courses: courses,
      ),
    );
    await clear(aliasId);
  }

  Future<void> clear(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    _loaded.remove(target);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(target));
  }

  String _key(String studentId) =>
      '$_keyPrefix${Uri.encodeComponent(studentId.trim())}';
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(Object? value) => value?.toString().trim() ?? '';

double _double(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(_text(value)) ?? fallback;
}

String _level(Object? value) {
  const levels = {'及格', '中等', '良好', '优秀'};
  final text = _text(value);
  return levels.contains(text) ? text : '优秀';
}
