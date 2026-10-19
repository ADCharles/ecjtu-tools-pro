// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'arrangement_models.dart';
import 'curriculum_models.dart';
import 'score_models.dart';

class AcademicSnapshotBundle {
  const AcademicSnapshotBundle({
    this.arrangement = const ArrangementSnapshot(),
    this.scores = const ScoreSnapshot(),
    this.curriculum = const CurriculumSnapshot(),
    this.updatedAt,
  });

  final ArrangementSnapshot arrangement;
  final ScoreSnapshot scores;
  final CurriculumSnapshot curriculum;
  final DateTime? updatedAt;

  bool get hasData =>
      arrangement.schedules.isNotEmpty ||
      arrangement.exams.isNotEmpty ||
      arrangement.registrations.isNotEmpty ||
      scores.records.isNotEmpty ||
      scores.details.isNotEmpty ||
      curriculum.records.isNotEmpty;
}

class AcademicSnapshotStorage {
  static const _keyPrefix = 'ecjtu.academic.snapshot.';

  Future<AcademicSnapshotBundle> read(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return const AcademicSnapshotBundle();
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key(target));
      if (raw == null || raw.isEmpty) return const AcademicSnapshotBundle();
      return _decode(jsonDecode(raw));
    } catch (_) {
      return const AcademicSnapshotBundle();
    }
  }

  Future<void> write(
    String studentId, {
    required ArrangementSnapshot arrangement,
    required ScoreSnapshot scores,
    required CurriculumSnapshot curriculum,
  }) async {
    await writeBundle(
      studentId,
      AcademicSnapshotBundle(
        arrangement: arrangement,
        scores: scores,
        curriculum: curriculum,
      ),
    );
  }

  Future<void> writeBundle(
    String studentId,
    AcademicSnapshotBundle bundle,
  ) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(target),
      jsonEncode({
        'version': 1,
        'updatedAt': (bundle.updatedAt ?? DateTime.now()).toIso8601String(),
        'arrangement': _arrangementToJson(bundle.arrangement),
        'scores': _scoresToJson(bundle.scores),
        'curriculum': _curriculumToJson(bundle.curriculum),
      }),
    );
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primary = primaryStudentId.trim();
    final alias = aliasStudentId.trim();
    if (primary.isEmpty || alias.isEmpty || primary == alias) return;
    final primaryBundle = await read(primary);
    final aliasBundle = await read(alias);
    await writeBundle(primary, _mergeBundles(primaryBundle, aliasBundle));
    await clear(alias);
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

  Map<String, dynamic> encodeBundle(AcademicSnapshotBundle bundle) => {
    'version': 1,
    'updatedAt': bundle.updatedAt?.toIso8601String(),
    'arrangement': _arrangementToJson(bundle.arrangement),
    'scores': _scoresToJson(bundle.scores),
    'curriculum': _curriculumToJson(bundle.curriculum),
  };

  AcademicSnapshotBundle decodeBundle(Object? value) => _decode(value);

  AcademicSnapshotBundle _decode(Object? value) {
    final map = _map(value);
    return AcademicSnapshotBundle(
      arrangement: _arrangementFromJson(map['arrangement']),
      scores: _scoresFromJson(map['scores']),
      curriculum: _curriculumFromJson(map['curriculum']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  AcademicSnapshotBundle _mergeBundles(
    AcademicSnapshotBundle primary,
    AcademicSnapshotBundle alias,
  ) {
    final primaryArrangement = primary.arrangement;
    final aliasArrangement = alias.arrangement;
    final primaryScores = primary.scores;
    final aliasScores = alias.scores;
    final primaryCurriculum = primary.curriculum;
    final aliasCurriculum = alias.curriculum;
    final details = <String, List<ScoreDetailRecord>>{};
    final terms = <String>{
      ...aliasScores.details.keys,
      ...primaryScores.details.keys,
    };
    for (final term in terms) {
      details[term] = _mergeByKey<ScoreDetailRecord>(
        aliasScores.details[term] ?? const <ScoreDetailRecord>[],
        primaryScores.details[term] ?? const <ScoreDetailRecord>[],
        (record) => _scoreDetailKey(record),
      );
    }
    return AcademicSnapshotBundle(
      arrangement: ArrangementSnapshot(
        schedules: _mergeByKey<ScheduleRecord>(
          aliasArrangement.schedules,
          primaryArrangement.schedules,
          _scheduleKey,
        ),
        exams: _mergeByKey<ExamRecord>(
          aliasArrangement.exams,
          primaryArrangement.exams,
          _examKey,
        ),
        registrations: _mergeByKey<RegistrationRecord>(
          aliasArrangement.registrations,
          primaryArrangement.registrations,
          _registrationKey,
        ),
        currentTerm:
            primaryArrangement.currentTerm ?? aliasArrangement.currentTerm,
        currentWeek:
            primaryArrangement.currentWeek ?? aliasArrangement.currentWeek,
      ),
      scores: ScoreSnapshot(
        records: _mergeByKey<ScoreRecord>(
          aliasScores.records,
          primaryScores.records,
          _scoreKey,
        ),
        details: details,
        studentId: _prefer(primaryScores.studentId, aliasScores.studentId),
        studentName: _prefer(
          primaryScores.studentName,
          aliasScores.studentName,
        ),
        creditRequirements: primaryScores.creditRequirements.isNotEmpty
            ? primaryScores.creditRequirements
            : aliasScores.creditRequirements,
        className: _prefer(primaryScores.className, aliasScores.className),
        enrollmentStatus: _prefer(
          primaryScores.enrollmentStatus,
          aliasScores.enrollmentStatus,
        ),
        pageGpa: _prefer(primaryScores.pageGpa, aliasScores.pageGpa),
      ),
      curriculum: CurriculumSnapshot(
        records: _mergeByKey<CurriculumRecord>(
          aliasCurriculum.records,
          primaryCurriculum.records,
          _curriculumKey,
        ),
      ),
      updatedAt: _newer(primary.updatedAt, alias.updatedAt),
    );
  }

  List<T> _mergeByKey<T>(
    Iterable<T> alias,
    Iterable<T> primary,
    String Function(T value) keyOf,
  ) {
    final values = <String, T>{};
    for (final value in alias) {
      values[keyOf(value)] = value;
    }
    for (final value in primary) {
      values[keyOf(value)] = value;
    }
    return values.values.toList(growable: false);
  }

  String _scheduleKey(ScheduleRecord record) => [
    record.term,
    record.weekday,
    record.sectionStart,
    record.sectionEnd,
    record.courseCode.isEmpty ? record.courseName : record.courseCode,
    record.teacher,
    record.classroom,
  ].join('|');

  String _examKey(ExamRecord record) => [
    record.term,
    record.courseName,
    record.date,
    record.startTime,
    record.endTime,
    record.type.name,
  ].join('|');

  String _registrationKey(RegistrationRecord record) => [
    record.term,
    record.courseCode.isEmpty ? record.courseName : record.courseCode,
    record.teachingClass,
    record.smallClassNumber,
  ].join('|');

  String _scoreKey(ScoreRecord record) => [
    record.term,
    record.courseCode.isEmpty ? record.courseName : record.courseCode,
  ].join('|');

  String _scoreDetailKey(ScoreDetailRecord record) => [
    record.term,
    record.courseCode.isEmpty ? record.courseName : record.courseCode,
    record.selectionType,
  ].join('|');

  String _curriculumKey(CurriculumRecord record) => [
    record.courseCode.isEmpty ? record.courseName : record.courseCode,
    record.platform,
    record.module,
    record.semesterIndex,
  ].join('|');

  String _prefer(String primary, String alias) =>
      primary.trim().isNotEmpty ? primary : alias;

  DateTime? _newer(DateTime? primary, DateTime? alias) {
    if (primary == null) return alias;
    if (alias == null) return primary;
    return primary.isAfter(alias) ? primary : alias;
  }

  Map<String, dynamic> _arrangementToJson(ArrangementSnapshot snapshot) => {
    'schedules': snapshot.schedules.map(_scheduleToJson).toList(),
    'exams': snapshot.exams.map(_examToJson).toList(),
    'registrations': snapshot.registrations.map(_registrationToJson).toList(),
    'currentTerm': snapshot.currentTerm,
    'currentWeek': snapshot.currentWeek,
  };

  ArrangementSnapshot _arrangementFromJson(Object? value) {
    final map = _map(value);
    return ArrangementSnapshot(
      schedules: _list(map['schedules'])
          .map(_scheduleFromJson)
          .whereType<ScheduleRecord>()
          .toList(growable: false),
      exams: _list(
        map['exams'],
      ).map(_examFromJson).whereType<ExamRecord>().toList(growable: false),
      registrations: _list(map['registrations'])
          .map(_registrationFromJson)
          .whereType<RegistrationRecord>()
          .toList(growable: false),
      currentTerm: _textOrNull(map['currentTerm']),
      currentWeek: _intOrNull(map['currentWeek']),
    );
  }

  Map<String, dynamic> _scheduleToJson(ScheduleRecord record) => {
    'term': record.term,
    'weekday': record.weekday,
    'sectionStart': record.sectionStart,
    'sectionEnd': record.sectionEnd,
    'courseName': record.courseName,
    'courseCode': record.courseCode,
    'courseType': record.courseType,
    'examType': record.examType,
    'teacher': record.teacher,
    'classroom': record.classroom,
    'weekRange': record.weekRange,
    'singleDouble': record.singleDouble,
    'weeks': record.weeks,
    'hours': record.hours,
    'credit': record.credit,
    'smallClassFull': record.smallClassFull,
    'smallClass': record.smallClass,
    'smallClassNumber': record.smallClassNumber,
    'noScheduledTime': record.noScheduledTime,
  };

  ScheduleRecord? _scheduleFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    return ScheduleRecord(
      term: _text(map['term']),
      weekday: _int(map['weekday']),
      sectionStart: _int(map['sectionStart']),
      sectionEnd: _int(map['sectionEnd']),
      courseName: courseName,
      courseCode: _text(map['courseCode']),
      courseType: _text(map['courseType']),
      examType: _text(map['examType']),
      teacher: _text(map['teacher']),
      classroom: _text(map['classroom']),
      weekRange: _text(map['weekRange']),
      singleDouble: _text(map['singleDouble']),
      weeks: _list(map['weeks']).map(_int).where((value) => value > 0).toList(),
      hours: _doubleOrNull(map['hours']),
      credit: _doubleOrNull(map['credit']),
      smallClassFull: _text(map['smallClassFull']),
      smallClass: _text(map['smallClass']),
      smallClassNumber: _text(map['smallClassNumber']),
      noScheduledTime: map['noScheduledTime'] == true,
    );
  }

  Map<String, dynamic> _examToJson(ExamRecord record) => {
    'term': record.term,
    'courseName': record.courseName,
    'date': record.date,
    'weekday': record.weekday,
    'teachingClass': record.teachingClass,
    'startTime': record.startTime,
    'endTime': record.endTime,
    'classroom': record.classroom,
    'seatNumber': record.seatNumber,
    'courseType': record.courseType,
    'examWeek': record.examWeek,
    'batch': record.batch,
    'type': record.type.name,
  };

  ExamRecord? _examFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    return ExamRecord(
      term: _text(map['term']),
      courseName: courseName,
      date: _text(map['date']),
      weekday: _text(map['weekday']),
      teachingClass: _text(map['teachingClass']),
      startTime: _text(map['startTime']),
      endTime: _text(map['endTime']),
      classroom: _text(map['classroom']),
      seatNumber: _text(map['seatNumber']),
      courseType: _text(map['courseType']),
      examWeek: _text(map['examWeek']),
      batch: _text(map['batch']),
      type: map['type']?.toString() == ExamArrangementType.retake.name
          ? ExamArrangementType.retake
          : ExamArrangementType.regular,
    );
  }

  Map<String, dynamic> _registrationToJson(RegistrationRecord record) => {
    'term': record.term,
    'courseCode': record.courseCode,
    'courseName': record.courseName,
    'courseType': record.courseType,
    'examType': record.examType,
    'hours': record.hours,
    'credit': record.credit,
    'teachingClass': record.teachingClass,
    'teacher': record.teacher,
    'smallClassFull': record.smallClassFull,
    'smallClass': record.smallClass,
    'smallClassNumber': record.smallClassNumber,
    'scheduleText': record.scheduleText,
  };

  RegistrationRecord? _registrationFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    return RegistrationRecord(
      term: _text(map['term']),
      courseCode: _text(map['courseCode']),
      courseName: courseName,
      courseType: _text(map['courseType']),
      examType: _text(map['examType']),
      hours: _double(map['hours']),
      credit: _double(map['credit']),
      teachingClass: _text(map['teachingClass']),
      teacher: _text(map['teacher']),
      smallClassFull: _text(map['smallClassFull']),
      smallClass: _text(map['smallClass']),
      smallClassNumber: _text(map['smallClassNumber']),
      scheduleText: _text(map['scheduleText']),
    );
  }

  Map<String, dynamic> _scoresToJson(ScoreSnapshot snapshot) => {
    'records': snapshot.records.map(_scoreToJson).toList(),
    'details': snapshot.details.map(
      (term, records) =>
          MapEntry(term, records.map(_scoreDetailToJson).toList()),
    ),
    'studentId': snapshot.studentId,
    'studentName': snapshot.studentName,
    'enrollmentStatus': snapshot.enrollmentStatus,
    'className': snapshot.className,
    'creditRequirements': snapshot.creditRequirements
        .map((v) => v.toJson())
        .toList(),
    'pageGpa': snapshot.pageGpa,
  };

  ScoreSnapshot _scoresFromJson(Object? value) {
    final map = _map(value);
    final details = <String, List<ScoreDetailRecord>>{};
    final rawDetails = _map(map['details']);
    rawDetails.forEach((term, records) {
      final values = _list(records)
          .map(_scoreDetailFromJson)
          .whereType<ScoreDetailRecord>()
          .toList(growable: false);
      if (values.isNotEmpty) details[term] = values;
    });
    return ScoreSnapshot(
      records: _list(
        map['records'],
      ).map(_scoreFromJson).whereType<ScoreRecord>().toList(growable: false),
      details: details,
      studentId: _text(map['studentId']),
      studentName: _text(map['studentName']),
      enrollmentStatus: _text(map['enrollmentStatus']),
      className: _text(map['className']),
      creditRequirements: _list(
        map['creditRequirements'],
      ).whereType<Map>().map(CreditRequirement.fromJson).toList(),
      pageGpa: _text(map['pageGpa']),
    );
  }

  Map<String, dynamic> _scoreToJson(ScoreRecord record) => {
    'term': record.term,
    'courseCode': record.courseCode,
    'courseName': record.courseName,
    'courseType': record.courseType,
    'examType': record.examType,
    'credit': record.credit,
    'examScore': record.examScore,
    'retestScore': record.retestScore,
    'retakeScore': record.retakeScore,
    'finalScore': record.finalScore,
    'finalScoreType': record.finalScoreType,
    'autoIncluded': record.autoIncluded,
    'includeOverride': record.includeOverride,
  };

  ScoreRecord? _scoreFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    return ScoreRecord(
      term: _text(map['term']),
      courseCode: _text(map['courseCode']),
      courseName: courseName,
      courseType: _text(map['courseType']),
      examType: _text(map['examType']),
      credit: _double(map['credit']),
      examScore: _text(map['examScore']),
      retestScore: _text(map['retestScore']),
      retakeScore: _text(map['retakeScore']),
      finalScore: _text(map['finalScore']),
      finalScoreType: _text(map['finalScoreType']),
      autoIncluded: map['autoIncluded'] != false,
      includeOverride: map['includeOverride'] is bool
          ? map['includeOverride'] as bool
          : null,
    );
  }

  Map<String, dynamic> _scoreDetailToJson(ScoreDetailRecord record) => {
    'term': record.term,
    'courseCode': record.courseCode,
    'courseName': record.courseName,
    'selectionType': record.selectionType,
    'courseType': record.courseType,
    'examType': record.examType,
    'credit': record.credit,
    'usualScore': record.usualScore,
    'usualWeight': record.usualWeight,
    'finalExamScore': record.finalExamScore,
    'finalScore': record.finalScore,
    'remark': record.remark,
  };

  ScoreDetailRecord? _scoreDetailFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    return ScoreDetailRecord(
      term: _text(map['term']),
      courseCode: _text(map['courseCode']),
      courseName: courseName,
      selectionType: _text(map['selectionType']),
      courseType: _text(map['courseType']),
      examType: _text(map['examType']),
      credit: _text(map['credit']),
      usualScore: _text(map['usualScore']),
      usualWeight: _text(map['usualWeight']),
      finalExamScore: _text(map['finalExamScore']),
      finalScore: _text(map['finalScore']),
      remark: _text(map['remark']),
    );
  }

  Map<String, dynamic> _curriculumToJson(CurriculumSnapshot snapshot) => {
    'records': snapshot.records.map(_curriculumRecordToJson).toList(),
  };

  CurriculumSnapshot _curriculumFromJson(Object? value) {
    final map = _map(value);
    return CurriculumSnapshot(
      records: _list(map['records'])
          .map(_curriculumRecordFromJson)
          .whereType<CurriculumRecord>()
          .toList(growable: false),
    );
  }

  Map<String, dynamic> _curriculumRecordToJson(CurriculumRecord record) => {
    'courseCode': record.courseCode,
    'courseName': record.courseName,
    'englishName': record.englishName,
    'platform': record.platform,
    'module': record.module,
    'credit': record.credit,
    'semesterIndex': record.semesterIndex,
    'semesterIndexes': record.semesterIndexes,
    'examType': record.examType,
    'courseType': record.courseType,
    'totalHours': record.totalHours,
    'inClassHours': record.inClassHours,
    'experimentHours': record.experimentHours,
    'computerHours': record.computerHours,
    'otherHours': record.otherHours,
    'status': record.status,
  };

  CurriculumRecord? _curriculumRecordFromJson(Object? value) {
    final map = _map(value);
    final courseName = _text(map['courseName']);
    if (courseName.isEmpty) return null;
    final semesters = _list(
      map['semesterIndexes'],
    ).map(_int).where((value) => value > 0).toList(growable: false);
    final semesterIndex = _int(map['semesterIndex']);
    return CurriculumRecord(
      courseCode: _text(map['courseCode']),
      courseName: courseName,
      englishName: _text(map['englishName']),
      platform: _text(map['platform']),
      module: _text(map['module']),
      credit: _double(map['credit']),
      semesterIndex: semesterIndex,
      semesterIndexes: semesters.isEmpty ? <int>[semesterIndex] : semesters,
      examType: _text(map['examType']),
      courseType: _text(map['courseType']),
      totalHours: _double(map['totalHours']),
      inClassHours: _double(map['inClassHours']),
      experimentHours: _double(map['experimentHours']),
      computerHours: _double(map['computerHours']),
      otherHours: _double(map['otherHours']),
      status: _text(map['status']),
    );
  }

  String _key(String studentId) =>
      '$_keyPrefix${Uri.encodeComponent(studentId.trim())}';

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Object?> _list(Object? value) => value is List ? value : const [];

  String _text(Object? value) => value?.toString().trim() ?? '';

  String? _textOrNull(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(_text(value)) ?? 0;

  int? _intOrNull(Object? value) {
    if (value == null) return null;
    return int.tryParse(_text(value));
  }

  double _double(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(_text(value)) ?? 0;

  double? _doubleOrNull(Object? value) {
    if (value == null) return null;
    return double.tryParse(_text(value));
  }

  DateTime? _date(Object? value) => DateTime.tryParse(_text(value));
}
