// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:diff_match_patch/diff_match_patch.dart';

class AiFileChange {
  const AiFileChange({
    required this.path,
    required this.operation,
    this.previousPath,
    this.before,
    this.after,
    this.added,
    this.removed,
    this.source = 'file',
  });
  final String path, operation, source;
  final String? previousPath, before, after;
  final int? added, removed;
  Map<String, Object?> toJson() => {
    'path': path,
    'operation': operation,
    'previousPath': previousPath,
    'before': before,
    'after': after,
    'added': added,
    'removed': removed,
    'source': source,
  };
  factory AiFileChange.fromJson(Map value) => AiFileChange(
    path: value['path'] as String,
    operation: value['operation'] as String,
    previousPath: value['previousPath'] as String?,
    before: value['before'] as String?,
    after: value['after'] as String?,
    added: value['added'] as int?,
    removed: value['removed'] as int?,
    source: value['source'] as String? ?? 'file',
  );
  static Future<AiFileChange> compare({
    required String path,
    required String operation,
    String? previousPath,
    String? before,
    String? after,
    String source = 'file',
  }) async {
    final lines = before != null && after != null
        ? await aiFileDiffAsync(before, after)
        : null;
    return AiFileChange(
      path: path,
      operation: operation,
      previousPath: previousPath,
      before: before,
      after: after,
      source: source,
      added: lines?.where((line) => line.operation == DIFF_INSERT).length,
      removed: lines?.where((line) => line.operation == DIFF_DELETE).length,
    );
  }
}

class _AiFileDiffRequest {
  const _AiFileDiffRequest(this.before, this.after);
  final String before, after;
  List<AiFileDiffLine> call() => aiFileDiff(before, after);
}

Future<List<AiFileDiffLine>> aiFileDiffAsync(String before, String after) =>
    Isolate.run(_AiFileDiffRequest(before, after).call);

class AiFileDiffLine {
  const AiFileDiffLine(this.operation, this.text, this.oldLine, this.newLine);
  final int operation;
  final String text;
  final int? oldLine, newLine;
}

List<AiFileDiffLine> aiFileDiff(String before, String after) {
  final values = <String>[];
  final ids = <String, int>{};
  String encode(String text) {
    if (text.isEmpty) return '';
    return String.fromCharCodes(
      const LineSplitter().convert(text).map((line) {
        return ids.putIfAbsent(line, () {
          values.add(line);
          return values.length;
        });
      }),
    );
  }

  final old = encode(before), next = encode(after);
  final result = <AiFileDiffLine>[];
  var oldLine = 1, newLine = 1;
  for (final part in diff(old, next, checklines: false, timeout: .2)) {
    for (final id in part.text.codeUnits) {
      result.add(
        AiFileDiffLine(
          part.operation,
          values[id - 1],
          part.operation == DIFF_INSERT ? null : oldLine++,
          part.operation == DIFF_DELETE ? null : newLine++,
        ),
      );
    }
  }
  if (before != after && old == next) {
    // Line tokens omit the final newline; preserve newline-only edits in the diff.
    result.add(
      AiFileDiffLine(
        DIFF_DELETE,
        before.endsWith('\n') ? '↵' : '∅',
        null,
        null,
      ),
    );
    result.add(
      AiFileDiffLine(DIFF_INSERT, after.endsWith('\n') ? '↵' : '∅', null, null),
    );
  }
  return result;
}

Future<String?> aiFileText(File file) async {
  try {
    if (!await file.exists()) return '';
    if (await file.length() > 65536) return null;
    final bytes = await file.readAsBytes();
    if (bytes.contains(0)) return null;
    return utf8.decode(bytes);
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}
