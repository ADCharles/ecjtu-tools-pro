// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<List<String>>? _roots;

Future<List<String>> aiDesktopToolchainRoots() => _roots ??= _discover();

Future<List<String>> _discover() async {
  final env = Platform.environment;
  final candidates = <String>{
    ...(env['PATH'] ?? '').split(';'),
    if (env['VSINSTALLDIR'] case final String root) root,
    if (env['VCINSTALLDIR'] case final String root) root,
    if (env['WindowsSdkDir'] case final String root) root,
    if (env['DOTNET_ROOT'] case final String root) root,
  };
  for (final key in ['ProgramFiles', 'ProgramFiles(x86)']) {
    if (env[key] case final String base) {
      candidates.add(p.join(base, 'Windows Kits', '10'));
      candidates.add(p.join(base, 'dotnet'));
    }
  }
  final base = env['ProgramFiles(x86)'];
  if (base != null) {
    final locator = p.join(
      base,
      'Microsoft Visual Studio',
      'Installer',
      'vswhere.exe',
    );
    try {
      if (await File(locator).exists()) {
        final result = await Process.run(locator, [
          '-all',
          '-products',
          '*',
          '-format',
          'json',
          '-utf8',
        ]).timeout(const Duration(seconds: 5));
        if (result.exitCode == 0) {
          for (final entry
              in (jsonDecode(result.stdout as String) as List)
                  .whereType<Map>()) {
            if (entry['installationPath'] case final String root) {
              candidates.add(p.join(root, 'Common7', 'Tools'));
              candidates.add(p.join(root, 'MSBuild', 'Current', 'Bin'));
              final versions = Directory(p.join(root, 'VC', 'Tools', 'MSVC'));
              if (await versions.exists()) {
                await for (final version in versions.list()) {
                  if (version is! Directory) continue;
                  for (final child in ['bin', 'include', 'lib']) {
                    candidates.add(p.join(version.path, child));
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // PATH and explicit toolchain environment remain usable without VS metadata.
    }
  }
  final roots = <String>{};
  for (final raw in candidates) {
    final candidate = raw.trim().replaceAll(RegExp(r'^"|"$'), '');
    if (!p.isAbsolute(candidate) || candidate.startsWith(r'\\')) continue;
    final path = p.normalize(candidate);
    if (p.equals(path, p.rootPrefix(path))) continue;
    try {
      if (await Directory(path).exists())
        roots.add(await Directory(path).resolveSymbolicLinks());
    } on FileSystemException {
      continue;
    }
  }
  final sorted = roots.toList()..sort();
  return sorted
      .where(
        (root) => !sorted.any(
          (parent) => !p.equals(root, parent) && p.isWithin(parent, root),
        ),
      )
      .take(128)
      .toList(growable: false);
}
