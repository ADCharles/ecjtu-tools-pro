// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/digests/sha256.dart';
import 'package:path/path.dart' as p;
import 'ai_models.dart';

final _preparedRuntimes = <String, Future<String>>{};

Future<String> aiPrepareRuntime(String program, String helper) async {
  final stat = await File(program).stat();
  final key = '$program|${stat.size}|${stat.modified.microsecondsSinceEpoch}';
  return _preparedRuntimes.putIfAbsent(key, () async {
    try {
      final probe = await Process.run(helper, ['--can-grant-runtime', program]);
      if (probe.exitCode == 0) return program;
      final base = Platform.environment['LOCALAPPDATA'];
      if (base == null)
        throw const AiToolException('runtime_access_denied', '程序安装目录无法读取');
      final root = p.join(
        base,
        'DongCharles',
        'assistant-runtime',
        'programs',
        SHA256Digest()
            .process(Uint8List.fromList(utf8.encode(key)))
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(),
      );
      final target = p.join(root, p.basename(program));
      final marker = File(p.join(root, '.ready'));
      if (await marker.exists() &&
          await marker.readAsString() == key &&
          await File(target).exists())
        return target;
      final source = Directory(p.dirname(program));
      final files = <File>[];
      var bytes = 0;
      await for (final entry in source.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entry is Link)
          throw const AiToolException(
            'runtime_access_denied',
            '运行环境包含链接，无法准备独立副本',
          );
        if (entry is! File) continue;
        bytes += (await entry.stat()).size;
        if (files.length >= 20000 || bytes > 512 * 1024 * 1024) {
          throw const AiToolException(
            'runtime_access_denied',
            '运行环境过大，无法准备独立副本；程序已安装，不要改用其他shell',
          );
        }
        files.add(entry);
      }
      await Directory(root).create(recursive: true);
      for (final file in files) {
        final output = File(
          p.join(root, p.relative(file.path, from: source.path)),
        );
        await output.parent.create(recursive: true);
        await file.copy(output.path);
      }
      await marker.writeAsString(key, flush: true);
      return target;
    } catch (_) {
      _preparedRuntimes.remove(key);
      rethrow;
    }
  });
}
