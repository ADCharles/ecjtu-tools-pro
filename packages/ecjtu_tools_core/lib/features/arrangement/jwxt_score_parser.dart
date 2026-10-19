// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'score_models.dart';

class ParsedScorePage {
  const ParsedScorePage({
    required this.records,
    required this.terms,
    required this.studentName,
    this.enrollmentStatus = '',
    this.className = '',
    this.creditRequirements = const [],
    required this.pageGpa,
  });

  final List<ScoreRecord> records;
  final List<String> terms;
  final String studentName;
  final String enrollmentStatus;
  final String className;
  final List<CreditRequirement> creditRequirements;
  final String pageGpa;
}

class JwxtScoreParser {
  const JwxtScoreParser._();

  static final _termPattern = RegExp(r'^20\d{2}\.[12]$');
  static final _termSearchPattern = RegExp(r'20\d{2}\.[12]');

  static ParsedScorePage parseScores(String source) {
    final document = html_parser.parse(source);
    final records = _scoreRecords(document);
    final terms = records.map((record) => record.term).toSet().toList()
      ..sort((left, right) => right.compareTo(left));
    final profile = _academicProfile(document);
    return ParsedScorePage(
      records: records,
      terms: terms,
      studentName: profile.studentName,
      enrollmentStatus: profile.enrollmentStatus,
      className: profile.className,
      creditRequirements: _creditRequirements(document),
      pageGpa: profile.pageGpa,
    );
  }

  static List<ScoreDetailRecord> parseScoreDetails(
    String source, {
    String fallbackTerm = '',
  }) {
    final document = html_parser.parse(source);
    final header = document.querySelectorAll('tr').where((row) {
      final text = _clean(row.text);
      return text.contains('平时成绩') && text.contains('总评成绩');
    }).firstOrNull;
    if (header == null) return const <ScoreDetailRecord>[];

    final labels = _cells(header);
    int indexOf(String label) {
      return labels.indexWhere(
        (value) => value == label || value.contains(label),
      );
    }

    final termIndex = indexOf('学期');
    final nameIndex = indexOf('课程名称');
    final courseIndex = indexOf('课程要求');
    final examIndex = indexOf('考核方式');
    if (nameIndex < 0) return const <ScoreDetailRecord>[];

    final result = <ScoreDetailRecord>[];
    for (final row in document.querySelectorAll('tr')) {
      final values = _cells(row);
      final term = _at(values, termIndex).isNotEmpty
          ? _at(values, termIndex)
          : fallbackTerm;
      final rawName = _at(values, nameIndex);
      if (!_termPattern.hasMatch(term) || rawName.isEmpty) continue;
      final nameMatch = RegExp(r'^【([^】]+)】\s*(.+)$').firstMatch(rawName);
      String at(String label) {
        final index = indexOf(label);
        return index < 0 ? '' : _at(values, index);
      }

      result.add(
        ScoreDetailRecord(
          term: term,
          courseCode: nameMatch?.group(1)?.trim() ?? '',
          courseName: nameMatch?.group(2)?.trim() ?? rawName,
          selectionType: at('选课类型'),
          courseType: courseIndex < 0 ? '' : _at(values, courseIndex),
          examType: examIndex < 0 ? '' : _at(values, examIndex),
          credit: at('学分'),
          usualScore: at('平时成绩'),
          usualWeight: at('平时成绩占比'),
          finalExamScore: at('期末成绩'),
          finalScore: at('总评成绩'),
          remark: at('备注'),
        ),
      );
    }

    final unique = <String, ScoreDetailRecord>{};
    for (final record in result) {
      final key = [record.term, record.courseCode, record.courseName].join('|');
      unique[key] = record;
    }
    return unique.values.toList();
  }

  static List<ScoreRecord> _scoreRecords(Document document) {
    final result = <ScoreRecord>[];
    for (final row in document.querySelectorAll('ul, ol, tr')) {
      final values = _cells(row);
      if (values.length < 6 || !_termPattern.hasMatch(_at(values, 0))) {
        continue;
      }
      final nameMatch = RegExp(
        r'^【([^】]+)】\s*(.+)$',
      ).firstMatch(_at(values, 1));
      final credit = _number(_at(values, 4));
      if (nameMatch == null || credit == null) continue;

      final best = ScoreCalculations.bestScore([
        ScoreValue(type: '考试', raw: _at(values, 5)),
        ScoreValue(type: '重考', raw: _at(values, 6)),
        ScoreValue(type: '重修', raw: _at(values, 7)),
      ]);
      final className = row.attributes['class'] ?? '';
      final style = row.attributes['style'] ?? '';
      result.add(
        ScoreRecord(
          term: _at(values, 0),
          courseCode: nameMatch.group(1)?.trim() ?? '',
          courseName: nameMatch.group(2)?.trim() ?? '',
          courseType: _at(values, 2),
          examType: _at(values, 3),
          credit: credit,
          examScore: _at(values, 5),
          retestScore: _at(values, 6),
          retakeScore: _at(values, 7),
          finalScore: best?.raw ?? '',
          finalScoreType: best?.type ?? '',
          autoIncluded: !RegExp(
            r'gray|grey|disabled|not[-_]?required|no[-_]?plan',
            caseSensitive: false,
          ).hasMatch('$className $style'),
        ),
      );
    }

    final unique = <String, ScoreRecord>{};
    for (final record in result) {
      unique['${record.term}|${record.courseCode}|${record.courseName}'] =
          record;
    }
    return unique.values.toList();
  }

  static List<CreditRequirement> _creditRequirements(Document document) {
    for (final table in document.querySelectorAll('table')) {
      final rows = table.querySelectorAll('tr');
      if (rows.isEmpty) continue;
      final headerIndex = rows.indexWhere(
        (row) => RegExp(r'毕业要求|学业预警情况').hasMatch(_clean(row.text)),
      );
      if (headerIndex < 0) continue;
      final top = rows[headerIndex].children.where(
        (cell) => cell.localName == 'th' || cell.localName == 'td',
      );
      var offset = 0;
      var graduation = false;
      int? warningOffset;
      for (final header in top) {
        if (_clean(header.text) == '学业预警情况') warningOffset = offset;
        if (_clean(header.text) == '毕业要求') {
          graduation = true;
          break;
        }
        offset += int.tryParse(header.attributes['colspan'] ?? '') ?? 1;
      }
      if (!graduation && warningOffset == null) continue;
      final categories = <(String, int)>[];
      for (final row in rows.skip(headerIndex + 1)) {
        for (final header in row.children.where(
          (cell) => cell.localName == 'th' || cell.localName == 'td',
        )) {
          final label = _clean(header.text);
          final span = int.tryParse(header.attributes['colspan'] ?? '') ?? 1;
          if (span >= 3 && label.contains('学分')) categories.add((label, span));
        }
      }
      final dataRows = rows
          .skip(headerIndex + 1)
          .where(
            (row) =>
                row.querySelector('td') != null &&
                _cells(
                  row,
                ).any((value) => RegExp(r'^\d+(?:\.\d+)?$').hasMatch(value)) &&
                !_cells(
                  row,
                ).any((value) => RegExp(r'应完成|已完成|欠学分|毕业要求').hasMatch(value)),
          );
      if (dataRows.isEmpty) continue;
      final values = _cells(dataRows.first);
      final result = <CreditRequirement>[];
      if (warningOffset != null && warningOffset + 1 < values.length) {
        result.add(
          CreditRequirement(
            name: '学业预警情况',
            required: _at(values, warningOffset),
            completed: _at(values, warningOffset + 1),
            missing: '',
          ),
        );
      }
      if (!graduation) return result;
      for (final (name, span) in categories) {
        if (offset + 2 >= values.length) break;
        result.add(
          CreditRequirement(
            name: name,
            required: _at(values, offset),
            completed: _at(values, offset + 1),
            missing: _at(values, offset + 2),
          ),
        );
        offset += span;
      }
      return result;
    }
    return const [];
  }

  static _AcademicProfile _academicProfile(Document document) {
    final bodyText = _clean(document.body?.text ?? '');
    var studentName = '';
    var className = '';
    var enrollmentStatus = '';
    var pageGpa =
        RegExp(
          r'GPA\s*[:：]\s*(\d+(?:\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(bodyText)?.group(1) ??
        '';

    for (final table in document.querySelectorAll('table')) {
      final rows = table.querySelectorAll('tr');
      final headerIndex = rows.indexWhere((row) {
        final text = _clean(row.text);
        return text.contains('姓名') && text.contains('学籍状态');
      });
      if (headerIndex < 0) continue;
      final headers = _cells(rows[headerIndex]);
      final nameIndex = headers.indexWhere(
        (value) => value == '姓名' || value.contains('姓名'),
      );
      final statusIndex = headers.indexWhere((value) => value.contains('学籍状态'));
      for (final row in rows.skip(headerIndex + 1)) {
        if (row.querySelector('td') == null) continue;
        final values = _cells(row);
        if (nameIndex < 0 ||
            statusIndex < 0 ||
            values.length <= nameIndex ||
            values.length <= statusIndex) {
          continue;
        }
        final value = _at(values, nameIndex);
        if (value.isEmpty || value.contains('姓名')) continue;
        studentName = value;
        final classIndex = headers.indexWhere(
          (value) => RegExp(r'(?:行政)?班级(?:名称)?[:：]?$').hasMatch(value),
        );
        if (classIndex >= 0) className = _at(values, classIndex);
        final status = _at(values, statusIndex);
        final adjacent = _at(values, statusIndex + 1);
        enrollmentStatus =
            RegExp(r'^(?:有学籍|无学籍)$').hasMatch(adjacent) &&
                !status.contains(adjacent)
            ? [status, adjacent].where((item) => item.isNotEmpty).join('|')
            : status;
        break;
      }
      if (studentName.isNotEmpty) break;
    }

    if (studentName.isEmpty) {
      final rows = document.querySelectorAll('tr');
      final gpaCells = rows.length > 3 ? _cells(rows[3]) : const <String>[];
      if (gpaCells.length >= 7) {
        studentName = _at(gpaCells, 1);
        enrollmentStatus = _at(gpaCells, 2);
        pageGpa = _at(gpaCells, 6).isNotEmpty ? _at(gpaCells, 6) : pageGpa;
      }
    }
    if (studentName.isEmpty) {
      studentName =
          RegExp(
            r'姓名\s*[:：]\s*([^\s|]{2,20})',
          ).firstMatch(bodyText)?.group(1) ??
          '';
    }
    if (enrollmentStatus.isEmpty) {
      enrollmentStatus =
          RegExp(
            r'(?:学籍状态|状态)\s*[:：]\s*([^\s]{2,30})',
          ).firstMatch(bodyText)?.group(1) ??
          '';
    }
    if (className.isEmpty) {
      for (final row in document.querySelectorAll('tr')) {
        final values = _cells(row);
        final index = values.indexWhere(
          (value) => RegExp(r'^(?:行政)?班级(?:名称)?[:：]?$').hasMatch(value),
        );
        if (index >= 0 &&
            index + 1 < values.length &&
            !RegExp(r'姓名|学籍状态|应完成|已完成').hasMatch(values[index + 1])) {
          className = values[index + 1];
          break;
        }
      }
    }
    return _AcademicProfile(
      studentName: studentName,
      enrollmentStatus: enrollmentStatus,
      className: className,
      pageGpa: pageGpa,
    );
  }

  static List<String> termsIn(String source) {
    final document = html_parser.parse(source);
    final result = <String>{};
    for (final element in document.querySelectorAll('a, option, select, tr')) {
      for (final match in _termSearchPattern.allMatches(_clean(element.text))) {
        result.add(match.group(0)!);
      }
    }
    return result.toList()..sort((left, right) => right.compareTo(left));
  }

  static List<String> _cells(Element row) {
    final isList = row.localName == 'ul' || row.localName == 'ol';
    return row.children
        .where(
          (element) => isList
              ? element.localName == 'li'
              : element.localName == 'td' || element.localName == 'th',
        )
        .map((element) => _clean(element.text))
        .toList();
  }

  static String _at(List<String> values, int index) {
    return index >= 0 && index < values.length ? values[index] : '';
  }

  static double? _number(String value) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  static String _clean(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _AcademicProfile {
  const _AcademicProfile({
    required this.studentName,
    required this.enrollmentStatus,
    required this.className,
    required this.pageGpa,
  });

  final String studentName;
  final String enrollmentStatus;
  final String className;
  final String pageGpa;
}
