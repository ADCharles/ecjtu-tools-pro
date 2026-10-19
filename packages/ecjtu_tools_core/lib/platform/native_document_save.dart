// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/foundation.dart';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

Future<String?> saveNativeDocument(
  Uint8List bytes,
  String fileName, {
  String? mimeType,
  List<XTypeGroup> acceptedTypeGroups = const [],
}) async {
  final name = fileName.split(RegExp(r'[/\\]')).last;
  final contentType =
      mimeType ??
      switch (name.split('.').last.toLowerCase()) {
        'pdf' => 'application/pdf',
        'csv' => 'text/csv',
        'zip' => 'application/zip',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'json' => 'application/json',
        'txt' || 'md' => 'text/plain',
        _ => 'application/octet-stream',
      };
  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
    return MethodChannel(
      platform == TargetPlatform.android
          ? 'ecjtu/android_files'
          : 'ecjtu/ios_files',
    ).invokeMethod<String>('saveDocument', {
      'bytes': bytes,
      'name': name,
      'mimeType': contentType,
    });
  }
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: acceptedTypeGroups,
  );
  if (location == null) return null;
  await XFile.fromData(
    bytes,
    name: name,
    mimeType: contentType,
  ).saveTo(location.path);
  return location.path;
}
