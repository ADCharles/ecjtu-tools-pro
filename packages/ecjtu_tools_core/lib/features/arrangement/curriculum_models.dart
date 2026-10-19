// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class CurriculumRecord {
  const CurriculumRecord({
    required this.courseName,
    required this.credit,
    required this.semesterIndex,
    required this.semesterIndexes,
    this.courseCode = '',
    this.englishName = '',
    this.platform = '',
    this.module = '',
    this.examType = '',
    this.courseType = '',
    this.totalHours = 0,
    this.inClassHours = 0,
    this.experimentHours = 0,
    this.computerHours = 0,
    this.otherHours = 0,
    this.status = '',
  });

  final String courseCode;
  final String courseName;
  final String englishName;
  final String platform;
  final String module;
  final double credit;
  final int semesterIndex;
  final List<int> semesterIndexes;
  final String examType;
  final String courseType;
  final double totalHours;
  final double inClassHours;
  final double experimentHours;
  final double computerHours;
  final double otherHours;
  final String status;

  String get identity => courseCode.isNotEmpty ? courseCode : courseName;

  String get key => '$semesterIndex|$identity';

  bool get isPassed => status == '已过';

  String get platformLabel => platform.isEmpty ? '其他课程平台' : platform;

  String get semesterLabel => semesterIndexes.map(labelForSemester).join(' / ');

  static String labelForSemester(int value) {
    if (value < 1) return '学期未标注';
    final year = (value + 1) ~/ 2;
    final yearLabel = switch (year) {
      1 => '大一',
      2 => '大二',
      3 => '大三',
      4 => '大四',
      _ => '第 $year 学年',
    };
    return '$yearLabel${value.isOdd ? '上' : '下'}';
  }
}

class CurriculumSnapshot {
  const CurriculumSnapshot({this.records = const <CurriculumRecord>[]});

  final List<CurriculumRecord> records;

  List<String> get platforms {
    final values = records
        .map((record) => record.platformLabel)
        .toSet()
        .toList();
    values.sort((left, right) => left.compareTo(right));
    return values;
  }

  List<int> get semesters {
    final values = <int>{};
    for (final record in records) {
      values.addAll(record.semesterIndexes);
    }
    return values.toList()..sort();
  }
}
