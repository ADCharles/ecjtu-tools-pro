// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

String? aiDirectReplacementShell(String command) {
  final invocation = RegExp(
    r'''(?:^|[;|&\n({])\s*(?:&\s*)?(?:['"]([^'"\r\n]+)['"]|([A-Za-z][A-Za-z0-9_.\\/: -]*?))(?=\s|$)''',
    caseSensitive: false,
  );
  for (final match in invocation.allMatches(command)) {
    final value = (match.group(1) ?? match.group(2) ?? '').trim();
    final name = value.replaceAll('\\', '/').split('/').last.toLowerCase();
    if (const {
      'cmd',
      'cmd.exe',
      'powershell',
      'powershell.exe',
    }.contains(name)) {
      return name;
    }
  }
  return null;
}
