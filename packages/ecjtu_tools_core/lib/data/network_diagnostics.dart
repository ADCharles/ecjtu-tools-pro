// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';

class NetworkDiagnostics {
  static final File _file = File(
    '${Directory.systemTemp.path}/ecjtu-network-diagnostics.log',
  );
  static Future<void> _queue = Future.value();
  static void record(String event) {
    if (!const bool.fromEnvironment('ECJTU_NETWORK_DIAGNOSTICS')) return;
    _queue = _queue
        .then((_) async {
          if (await _file.exists() && await _file.length() > 262144) {
            await _file.writeAsString('');
          }
          await _file.writeAsString(
            '${DateTime.now().toIso8601String()} $event\n',
            mode: FileMode.append,
          );
        })
        .catchError((_) {});
  }
}
