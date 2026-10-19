// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:math';
import 'package:markdown/markdown.dart' as md;

String diaryDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime diaryDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('日记日期无效');
  }
  final date = DateTime.parse(value);
  if (diaryDateKey(date) != value || date.year < 1 || date.year > 9999) {
    throw const FormatException('日记日期无效');
  }
  return date;
}

String newDiaryId() {
  final random = Random.secure();
  return base64Url
      .encode(List.generate(18, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

class DiaryHeading {
  const DiaryHeading(this.start, this.end, this.prefix, this.title);
  final int start, end;
  final String prefix, title;
}

DiaryHeading? firstDiaryHeading(String source) {
  final lines = source.split('\n');
  var offset = 0;
  String? fence;
  var fenceLength = 0;
  String? mathClose;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (fence == null) {
      if (mathClose != null) {
        if (line.trimRight().endsWith(mathClose)) mathClose = null;
        offset += line.length + 1;
        continue;
      }
      final math = RegExp(r'^ {0,3}(\$\$|\\\[)').firstMatch(line);
      if (math != null) {
        final close = math[1] == r'$$' ? r'$$' : r'\]';
        if (!line.substring(math.end).contains(close)) mathClose = close;
        offset += line.length + 1;
        continue;
      }
    }
    final marker = RegExp(r'^ {0,3}(`{3,}|~{3,})').firstMatch(line);
    if (marker != null) {
      final run = marker[1]!;
      if (fence == null) {
        fence = run[0];
        fenceLength = run.length;
      } else if (run[0] == fence &&
          run.length >= fenceLength &&
          line.substring(marker.end).trim().isEmpty) {
        fence = null;
      }
    } else if (fence == null) {
      final atx = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+|$)(.*)$').firstMatch(line);
      String? raw;
      var end = offset + line.length;
      var prefix = '';
      if (atx != null) {
        raw = atx[2]!.replaceFirst(RegExp(r'[ \t]+#+[ \t]*$'), '');
        prefix = '${atx[1]} ';
      } else if (line.trim().isNotEmpty &&
          !line.startsWith('    ') &&
          i + 1 < lines.length &&
          RegExp(r'^ {0,3}(=+|-+)\s*$').hasMatch(lines[i + 1])) {
        raw = line.trim();
        end += 1 + lines[i + 1].length;
        prefix = lines[i + 1].trim().startsWith('=') ? '# ' : '## ';
      }
      if (raw != null) {
        final nodes = md.Document(
          extensionSet: md.ExtensionSet.gitHubFlavored,
        ).parseInline(raw);
        final title = nodes.map((node) => node.textContent).join().trim();
        if (title.isNotEmpty) return DiaryHeading(offset, end, prefix, title);
      }
    }
    offset += line.length + 1;
  }
  return null;
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.body = '',
    this.markdown = true,
    this.utcOffsetMinutes = 0,
    this.renderScale = 1,
    this.imageWidths = const {},
  });
  final String id, date, title, body;
  final DateTime createdAt, updatedAt;
  final bool markdown;
  final int utcOffsetMinutes;
  final double renderScale;
  final Map<String, double> imageWidths;
  String get displayTitle => title.trim().isNotEmpty
      ? title.trim()
      : markdown
      ? firstDiaryHeading(body)?.title ?? ''
      : '';
  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;
  Set<String> get assetIds => RegExp(
    r'diary-asset:([a-f0-9]{64})',
  ).allMatches(body).map((match) => match[1]!).toSet();
  factory DiaryEntry.empty(DateTime date) {
    final now = DateTime.now();
    return DiaryEntry(
      id: newDiaryId(),
      date: diaryDateKey(date),
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      utcOffsetMinutes: now.timeZoneOffset.inMinutes,
    );
  }
  DiaryEntry edit({
    String? title,
    String? body,
    bool? markdown,
    double? renderScale,
    Map<String, double>? imageWidths,
  }) => DiaryEntry(
    id: id,
    date: date,
    createdAt: createdAt,
    updatedAt: DateTime.now().toUtc(),
    title: title ?? this.title,
    body: body ?? this.body,
    markdown: markdown ?? this.markdown,
    utcOffsetMinutes: utcOffsetMinutes,
    renderScale: renderScale ?? this.renderScale,
    imageWidths: imageWidths ?? this.imageWidths,
  );
  DiaryEntry withOuterTitle(String value) {
    final text = value.replaceAll(RegExp(r'[\r\n]'), ' ');
    final escaped = text.replaceAllMapped(
      RegExp(r'[\\`*_{}\[\]()#+.!>|~-]'),
      (match) => '\\${match[0]}',
    );
    final heading = markdown ? firstDiaryHeading(body) : null;
    return edit(
      title: text,
      body: heading == null
          ? body
          : body.replaceRange(
              heading.start,
              heading.end,
              '${heading.prefix}$escaped',
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'title': title,
    'body': body,
    'format': markdown ? 'markdown' : 'plain',
    'font': 'kai',
    'renderScale': renderScale,
    'imageWidths': imageWidths,
    'utcOffsetMinutes': utcOffsetMinutes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
  factory DiaryEntry.fromJson(Map<String, dynamic> value) {
    final id = value['id'] as String;
    final title = value['title'] as String;
    final body = value['body'] as String;
    final offset = value['utcOffsetMinutes'] as int;
    final scale = (value['renderScale'] as num? ?? 1).toDouble();
    final imageWidths = <String, double>{};
    for (final item in (value['imageWidths'] as Map? ?? {}).entries) {
      final width = (item.value as num).toDouble();
      if (item.key is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(item.key as String) ||
          !width.isFinite ||
          width < .01 ||
          width > 1)
        throw const FormatException('图片尺寸无效');
      imageWidths[item.key as String] = width;
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id) ||
        title.length > 1000 ||
        body.length > 2000000 ||
        offset.abs() > 1440 ||
        !scale.isFinite ||
        scale < .75 ||
        scale > 2 ||
        !['markdown', 'plain'].contains(value['format'])) {
      throw const FormatException('日记内容无效');
    }
    final date = value['date'] as String;
    diaryDate(date);
    return DiaryEntry(
      id: id,
      date: date,
      title: title,
      body: body,
      markdown: value['format'] == 'markdown',
      utcOffsetMinutes: offset,
      renderScale: scale,
      imageWidths: Map.unmodifiable(imageWidths),
      createdAt: DateTime.parse(value['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(value['updatedAt'] as String).toUtc(),
    );
  }
}
