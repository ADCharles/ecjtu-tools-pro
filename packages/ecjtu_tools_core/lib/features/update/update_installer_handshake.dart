// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';

Future<bool> waitForUpdateInstaller({
  required File ready,
  required File result,
  required String attemptId,
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final elapsed = Stopwatch()..start();
  while (elapsed.elapsed < timeout) {
    for (final file in [ready, result]) {
      try {
        if (!await file.exists()) continue;
        final value = jsonDecode(
          (await file.readAsString()).replaceFirst('\uFEFF', ''),
        );
        if (value is Map && value['attemptId'] == attemptId) {
          return file == ready;
        }
      } on FileSystemException {
        // The helper may replace the file between checking and reading it.
      } on FormatException {
        // A concurrent write is not an acknowledgement until it is complete.
      }
    }
    await Future<void>.delayed(pollInterval);
  }
  return false;
}
