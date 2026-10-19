// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';
import 'package:path/path.dart' as p;

Future<List<String>> aiCommandRuntimePaths(
  String command, {
  Map<String, String>? environment,
  Future<bool> Function(String)? exists,
}) async {
  final env = environment ?? Platform.environment;
  final isFile = exists ?? (path) => File(path).exists();
  final programs = <String>{};
  final literals = RegExp(
    r'''['"]([A-Za-z]:[\\/][^'"\r\n]+\.exe)['"]''',
    caseSensitive: false,
  );
  for (final match in literals.allMatches(command)) {
    final path = p.windows.normalize(match.group(1)!);
    if (await isFile(path)) programs.add(path);
  }
  final invocations = RegExp(
    r'(?:^|[;|&\n])\s*([A-Za-z][A-Za-z0-9_.+\-]*)(?=\s|$)',
  );
  final search = (env['PATH'] ?? env['Path'] ?? '')
      .split(';')
      .where((dir) => dir.isNotEmpty);
  for (final name in {
    ...invocations.allMatches(command).map((match) => match.group(1)!).toSet(),
  }) {
    final executable = name.toLowerCase().endsWith('.exe') ? name : '$name.exe';
    for (final directory in search) {
      final path = p.windows.normalize(p.windows.join(directory, executable));
      if (!p.windows.isAbsolute(path)) continue;
      if (await isFile(path)) {
        programs.add(path);
        break;
      }
    }
  }
  return programs.take(30).toList();
}

Future<List<String>> aiCommandReadResources(String command) async {
  final result = <String>{};
  final literals = RegExp(r'''['"]([A-Za-z]:[\\/][^'"\r\n]+)['"]''');
  for (final match in literals.allMatches(command)) {
    final path = p.windows.normalize(match.group(1)!);
    if (path == p.windows.rootPrefix(path)) continue;
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.file ||
        type == FileSystemEntityType.directory)
      result.add(path);
  }
  return result.take(16).toList();
}
