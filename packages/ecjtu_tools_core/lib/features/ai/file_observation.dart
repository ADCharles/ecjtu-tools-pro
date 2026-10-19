// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'file_change.dart';

class AiFileObservation {
  AiFileObservation._(this.root, this.files, this.complete);
  final String root;
  final bool complete;
  final Map<String, ({int size, int modified, String? text})> files;
  static const _excluded = {
    '.git',
    '.dart_tool',
    'node_modules',
    'build',
    '.venv',
    '__pycache__',
  };
  static Future<AiFileObservation> capture(String directory) async {
    final root = p.normalize(await Directory(directory).resolveSymbolicLinks());
    final files = <String, ({int size, int modified, String? text})>{};
    if (p.dirname(root) == root) return AiFileObservation._(root, files, false);
    final pending = [root];
    final timer = Stopwatch()..start();
    var bytes = 0, visited = 0;
    var complete = true;
    try {
      while (pending.isNotEmpty &&
          visited < 2048 &&
          files.length < 512 &&
          timer.elapsedMilliseconds < 500) {
        final dir = pending.removeLast();
        if (await FileSystemEntity.type(dir, followLinks: false) !=
            FileSystemEntityType.directory) {
          complete = false;
          continue;
        }
        final resolved = await Directory(dir).resolveSymbolicLinks();
        if (!p.equals(root, resolved) && !p.isWithin(root, resolved)) {
          complete = false;
          continue;
        }
        await for (final entity in Directory(dir).list(followLinks: false)) {
          if (++visited > 2048 ||
              files.length >= 512 ||
              timer.elapsedMilliseconds >= 500) {
            complete = false;
            break;
          }
          if (entity is Directory &&
              !_excluded.contains(p.basename(entity.path)) &&
              !(p.equals(dir, root) &&
                  p.basename(entity.path) == '.dc-agent-runtime')) {
            pending.add(entity.path);
          } else if (entity is File) {
            final resolved = await entity.resolveSymbolicLinks();
            if (!p.isWithin(root, resolved)) {
              complete = false;
              continue;
            }
            final stat = await entity.stat();
            final text = bytes + stat.size <= 2 * 1024 * 1024
                ? await aiFileText(entity)
                : null;
            bytes += text == null ? 0 : stat.size;
            files[entity.path] = (
              size: stat.size,
              modified: stat.modified.microsecondsSinceEpoch,
              text: text,
            );
          }
        }
      }
    } on FileSystemException {
      complete = false;
    }
    return AiFileObservation._(root, files, complete && pending.isEmpty);
  }

  Future<List<AiFileChange>> finish() async {
    final after = await capture(root);
    final changes = <AiFileChange>[];
    for (final path in {...files.keys, ...after.files.keys}) {
      final before = files[path];
      var next = after.files[path];
      if (before == null && !complete) continue;
      if (before != null && next == null) {
        final type = await FileSystemEntity.type(path, followLinks: false);
        if (type == FileSystemEntityType.file) {
          if (!p.isWithin(root, await File(path).resolveSymbolicLinks()))
            continue;
          final file = File(path), stat = await File(path).stat();
          next = (
            size: stat.size,
            modified: stat.modified.microsecondsSinceEpoch,
            text: await aiFileText(file),
          );
        } else if (type != FileSystemEntityType.notFound) {
          continue;
        }
      }
      if (before != null &&
          next != null &&
          before.size == next.size &&
          before.modified == next.modified &&
          before.text == next.text)
        continue;
      if (before?.text != null &&
          next?.text != null &&
          before!.text == next!.text)
        continue;
      changes.add(
        await AiFileChange.compare(
          path: path,
          operation: before == null
              ? 'create'
              : next == null
              ? 'delete'
              : 'edit',
          before: before == null ? '' : before.text,
          after: next == null ? '' : next.text,
          source: 'powershell',
        ),
      );
    }
    return changes;
  }
}
