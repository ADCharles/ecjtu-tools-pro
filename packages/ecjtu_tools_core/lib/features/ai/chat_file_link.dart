// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

Future<bool> isAiLocalDocument(Uri uri) async {
  if (!Platform.isWindows ||
      uri.scheme != 'file' ||
      uri.host.isNotEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment)
    return false;
  try {
    final path = uri.toFilePath(windows: true);
    if (!RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path)) return false;
    if (!const {
      '.html',
      '.htm',
      '.pdf',
      '.txt',
      '.cpp',
      '.c',
      '.h',
      '.hpp',
      '.cc',
      '.cxx',
      '.rs',
      '.py',
      '.dart',
      '.js',
      '.jsx',
      '.ts',
      '.tsx',
      '.css',
      '.xml',
      '.yaml',
      '.yml',
      '.toml',
      '.ini',
      '.log',
      '.md',
      '.json',
      '.csv',
      '.tsv',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.rtf',
      '.png',
      '.jpg',
      '.jpeg',
      '.webp',
      '.gif',
      '.svg',
    }.contains(p.extension(path).toLowerCase()))
      return false;
    return await FileSystemEntity.type(path) == FileSystemEntityType.file;
  } catch (_) {
    return false;
  }
}

Future<bool> openAiLocalDocument(
  Uri uri, {
  Future<bool> Function(Uri)? launch,
  Future<bool> Function(String)? openText,
}) async {
  if (!await isAiLocalDocument(uri)) return false;
  try {
    if (await (launch ??
        (value) => launchUrl(value, mode: LaunchMode.externalApplication))(uri))
      return true;
  } catch (_) {
    // Source files often have no registered Windows file association.
  }
  final path = uri.toFilePath(windows: true);
  if (!const {
    '.cpp',
    '.c',
    '.cc',
    '.cxx',
    '.h',
    '.hpp',
    '.rs',
    '.py',
    '.dart',
    '.js',
    '.jsx',
    '.ts',
    '.tsx',
    '.css',
    '.xml',
    '.yaml',
    '.yml',
    '.toml',
    '.ini',
    '.log',
    '.txt',
    '.md',
    '.json',
    '.csv',
    '.tsv',
  }.contains(p.extension(path).toLowerCase()))
    return false;
  if (openText != null) return openText(path);
  try {
    await Process.start(
      p.join(
        Platform.environment['SystemRoot'] ?? r'C:\Windows',
        'System32',
        'notepad.exe',
      ),
      [path],
      mode: ProcessStartMode.detached,
    );
    return true;
  } on ProcessException {
    return false;
  }
}
