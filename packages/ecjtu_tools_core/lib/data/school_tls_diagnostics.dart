// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';

abstract final class SchoolTlsDiagnostics {
  static File get file =>
      File('${Directory.systemTemp.path}/ecjtu-tls-diagnostics.jsonl');
  static Future<void> _queue = Future.value();

  static Map<String, Object?> describe(TlsException error, String host) {
    final text = '${error.message} ${error.osError?.message}'.toLowerCase();
    final normalized = text.replaceAll('_', ' ');
    final reason = [
      'self signed certificate in certificate chain',
      'self-signed certificate',
      'unable to get local issuer certificate',
      'unable to verify the first certificate',
      'certificate has expired',
      'certificate is not yet valid',
      'hostname mismatch',
      'ip address mismatch',
      'certificate revoked',
      'unsupported protocol',
      'wrong version number',
      'tlsv1 alert protocol version',
      'tlsv1 alert unknown ca',
      'sslv3 alert handshake failure',
    ].where(normalized.contains).firstOrNull;
    return {
      'timeUtc': DateTime.now().toUtc().toIso8601String(),
      'host': host,
      'errorType': error.runtimeType.toString(),
      'certificateVerifyFailed': text.contains('certificate_verify_failed'),
      'reason': reason ?? 'unclassified TLS failure',
      'osCode': error.osError?.errorCode,
    };
  }

  static Future<void> record(TlsException error, String host) {
    final event = describe(error, host);
    final target = file;
    _queue = _queue
        .then((_) async {
          if (await target.exists() && await target.length() > 64 * 1024) {
            await target.writeAsString('');
          }
          await target.writeAsString(
            '${jsonEncode(event)}\n',
            mode: FileMode.append,
            flush: true,
          );
        })
        .catchError((_) {});
    return _queue;
  }
}
