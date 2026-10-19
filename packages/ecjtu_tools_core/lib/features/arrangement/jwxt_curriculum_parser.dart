// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'curriculum_models.dart';

class JwxtCurriculumParser {
  const JwxtCurriculumParser._();

  static final _courseCodePattern = RegExp(
    r'^(?=[A-Za-z0-9._-]{6,})(?=[A-Za-z0-9._-]*\d)[A-Za-z0-9._-]+',
  );

  static List<CurriculumRecord> parse(String source) {
    final document = html_parser.parse(source);
    final result = <CurriculumRecord>[];
    final moduleByTable = <Element, String>{};

    for (final table in document.querySelectorAll('table')) {
      final rows = _rowsForTable(table);
      if (rows.isEmpty) continue;
      final fields = _headerMap(rows);
      final platform = _platformForTable(table);

      for (final row in rows) {
        final cells = _directCells(row);
        if (cells.length < 4) continue;

        var codeIndex = cells.indexWhere(
          (cell) => _courseCodePattern.hasMatch(_clean(cell.text)),
        );
        if (codeIndex < 0) continue;

        final identity = _clean(cells[codeIndex].text);
        final codeMatch = _courseCodePattern.firstMatch(identity);
        if (codeMatch == null) continue;
        final stateMatch = RegExp(
          r'[【\[]\s*([^，,、】\]]+)\s*[，,、]\s*(已过|未修|在修|已修|修读中)\s*[】\]]',
        ).firstMatch(identity);

        final moduleCandidate = cells
            .take(codeIndex)
            .map((cell) => _clean(cell.text))
            .firstWhere((value) => value.contains('模块'), orElse: () => '');
        if (moduleCandidate.isNotEmpty) {
          moduleByTable[table] = moduleCandidate;
        }
        final module = moduleCandidate.isNotEmpty
            ? moduleCandidate
            : moduleByTable[table] ?? '';

        int fieldIndex(String field) {
          final codeColumn = fields['courseCode'];
          final targetColumn = fields[field];
          if (codeColumn == null || targetColumn == null) return -1;
          final index = codeIndex + targetColumn - codeColumn;
          return index >= 0 && index < cells.length ? index : -1;
        }

        final nameIndex = fieldIndex('courseName') >= 0
            ? fieldIndex('courseName')
            : codeIndex + 1;
        final nameCell = nameIndex >= 0 && nameIndex < cells.length
            ? cells[nameIndex]
            : null;
        final nameLines = _lines(nameCell);
        final courseName = nameLines.isEmpty
            ? _clean(nameCell?.text ?? '')
            : nameLines.first;
        if (courseName.isEmpty) continue;
        final englishName = nameLines
            .skip(1)
            .firstWhere(
              (line) => RegExp(r'[A-Za-z]').hasMatch(line),
              orElse: () => '',
            );

        var examIndex = fieldIndex('examType');
        if (examIndex < 0) {
          examIndex = cells.indexWhere(
            (cell) =>
                cells.indexOf(cell) > codeIndex &&
                RegExp(r'^(考试|考查|考核)$').hasMatch(_clean(cell.text)),
          );
        }
        if (examIndex < 0) examIndex = nameIndex + 1;

        var creditIndex = fieldIndex('credit');
        if (creditIndex < 0) creditIndex = examIndex + 1;
        final credit = _number(_cellText(cells, creditIndex));
        if (credit == null) continue;

        var semesterIndex = fieldIndex('semesterIndex');
        if (semesterIndex < 0 && cells.length > codeIndex + 9) {
          semesterIndex = codeIndex + 9;
        }
        final semesterText = _cellText(cells, semesterIndex);
        final semesterIndexes =
            RegExp(r'\d+')
                .allMatches(semesterText)
                .map((match) => int.tryParse(match.group(0) ?? ''))
                .whereType<int>()
                .where((value) => value >= 1 && value <= 20)
                .toSet()
                .toList()
              ..sort();
        if (semesterIndexes.isEmpty) continue;

        final separateStatus = _fieldText(cells, fieldIndex('status'));
        final separateType = _fieldText(cells, fieldIndex('courseType'));
        final rawStatus = stateMatch?.group(2) ?? '';
        final status = _normalizeStatus(
          separateStatus.isNotEmpty ? separateStatus : rawStatus,
        );

        double numberAt(String field, int fallbackOffset) {
          var index = fieldIndex(field);
          if (index < 0) index = codeIndex + fallbackOffset;
          return _number(_cellText(cells, index)) ?? 0;
        }

        result.add(
          CurriculumRecord(
            courseCode: codeMatch.group(0) ?? '',
            courseName: courseName,
            englishName: englishName,
            platform: platform,
            module: module,
            examType: _fieldText(cells, examIndex),
            credit: credit,
            semesterIndex: semesterIndexes.first,
            semesterIndexes: semesterIndexes,
            courseType: separateType.isNotEmpty
                ? separateType
                : (stateMatch?.group(1) ?? ''),
            totalHours: numberAt('totalHours', 4),
            inClassHours: numberAt('inClassHours', 5),
            experimentHours: numberAt('experimentHours', 6),
            computerHours: numberAt('computerHours', 7),
            otherHours: numberAt('otherHours', 8),
            status: status,
          ),
        );
      }
    }

    final unique = <String, CurriculumRecord>{};
    for (final record in result) {
      unique[record.key] = record;
    }
    return unique.values.toList();
  }

  static List<Element> _rowsForTable(Element table) {
    return table.querySelectorAll('tr').where((row) {
      var parent = row.parent;
      while (parent != null && parent.localName != 'table') {
        parent = parent.parent;
      }
      return identical(parent, table);
    }).toList();
  }

  static List<Element> _directCells(Element row) => row.children
      .where((cell) => cell.localName == 'td' || cell.localName == 'th')
      .toList();

  static Map<String, int> _headerMap(List<Element> rows) {
    final fields = <String, int>{};
    final spans = <int, _HeaderSpan>{};
    final headerRows = rows.where(_isHeaderRow);

    for (final row in headerRows) {
      final logical = <Element?>[];
      spans.forEach((index, span) {
        _ensureLength(logical, index + 1);
        logical[index] = span.cell;
      });
      for (final entry in spans.entries.toList()) {
        final index = entry.key;
        final span = entry.value;
        span.remaining -= 1;
        if (span.remaining <= 0) spans.remove(index);
      }

      var column = 0;
      for (final cell in _directCells(row)) {
        while (column < logical.length && logical[column] != null) {
          column += 1;
        }
        final colSpan = _spanValue(cell, 'colspan');
        final rowSpan = _spanValue(cell, 'rowspan');
        for (var offset = 0; offset < colSpan; offset += 1) {
          final index = column + offset;
          _ensureLength(logical, index + 1);
          logical[index] = cell;
          if (rowSpan > 1) {
            spans[index] = _HeaderSpan(cell, rowSpan - 1);
          }
        }
        column += colSpan;
      }

      for (var index = 0; index < logical.length; index += 1) {
        final field = _headerField(logical[index]?.text ?? '');
        if (field.isNotEmpty) fields.putIfAbsent(field, () => index);
      }
    }
    return fields;
  }

  static bool _isHeaderRow(Element row) {
    if (row.children.any((cell) => cell.localName == 'th')) return true;
    final text = _clean(row.text);
    return RegExp(
      r'课程模块|课程编号|课程名称|考核类型|总学时|修读学期|实验学时|上机学时|其他学时|分学期周学时',
    ).hasMatch(text);
  }

  static String _headerField(String value) {
    final label = _clean(value).replaceAll(RegExp(r'[\s（）()]'), '');
    if (RegExp(r'课程(?:编号|编码|代码|号)').hasMatch(label)) {
      return 'courseCode';
    }
    if (RegExp(r'课程(?:名称|名)').hasMatch(label)) return 'courseName';
    if (RegExp(r'考核(?:类型|方式)|考试方式').hasMatch(label)) {
      return 'examType';
    }
    if (RegExp(r'^(?:课程)?学分$').hasMatch(label)) return 'credit';
    if (label == '总学时') return 'totalHours';
    if (label == '课内学时') return 'inClassHours';
    if (label == '实验学时') return 'experimentHours';
    if (label == '上机学时') return 'computerHours';
    if (label == '其他学时') return 'otherHours';
    if (RegExp(r'(?:建议)?(?:修读|开课)学期|^学期$').hasMatch(label)) {
      return 'semesterIndex';
    }
    if (RegExp(r'课程(?:性质|类别|要求|类型)').hasMatch(label)) {
      return 'courseType';
    }
    if (RegExp(r'(?:完成|修读)?状态').hasMatch(label)) return 'status';
    return '';
  }

  static String _platformForTable(Element table) {
    var current = table;
    for (var depth = 0; depth < 4; depth += 1) {
      final parent = current.parent;
      if (parent == null) break;
      final siblings = parent.children;
      final currentIndex = siblings.indexOf(current);
      if (currentIndex >= 0) {
        final firstIndex = (currentIndex - 8).clamp(0, currentIndex).toInt();
        for (var index = currentIndex - 1; index >= firstIndex; index -= 1) {
          final text = _clean(siblings[index].text);
          if (text.length > 120) continue;
          final match = RegExp(
            r'(?:^|\d+[、.．]\s*)([^，,。；;]{2,40}平台)',
          ).firstMatch(text);
          if (match != null) {
            return _clean(
              match.group(1) ?? '',
            ).replaceFirst(RegExp(r'^\d+[、.．]\s*'), '');
          }
        }
      }
      current = parent;
    }
    return '';
  }

  static List<String> _lines(Element? cell) {
    if (cell == null) return const <String>[];
    final text = cell.textContent(convertBRsToNewlines: true) ?? '';
    return text
        .split(RegExp(r'\r?\n+'))
        .map(_clean)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _fieldText(List<Element> cells, int index) =>
      _cellText(cells, index);

  static String _cellText(List<Element> cells, int index) {
    if (index < 0 || index >= cells.length) return '';
    return _clean(cells[index].text);
  }

  static double? _number(String value) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  static String _normalizeStatus(String value) {
    return switch (_clean(value)) {
      '已修' => '已过',
      '修读中' => '在修',
      '已过' => '已过',
      '未修' => '未修',
      _ => '',
    };
  }

  static String _clean(String value) =>
      value.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static int _spanValue(Element cell, String name) =>
      int.tryParse(cell.attributes[name] ?? '')?.clamp(1, 32).toInt() ?? 1;

  static void _ensureLength(List<Element?> values, int length) {
    while (values.length < length) {
      values.add(null);
    }
  }
}

class _HeaderSpan {
  _HeaderSpan(this.cell, this.remaining);

  final Element cell;
  int remaining;
}
