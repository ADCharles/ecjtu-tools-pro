// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'provider_models.dart';

AiProviderException aiProviderFailure(
  String original, {
  int? statusCode,
  Duration? retryAfter,
}) {
  var reason = '';
  try {
    final value = jsonDecode(original);
    if (value is Map) {
      final error = value['error'] is Map ? value['error'] as Map : value;
      reason =
          '${error['code'] ?? ''} ${error['type'] ?? ''} ${error['message'] ?? ''}'
              .toLowerCase();
    }
  } catch (_) {}
  final quota = RegExp(
    r'insufficient_quota|billing_hard_limit|insufficient.*(?:balance|credit)|余额不足|额度耗尽|配额耗尽',
  ).hasMatch(reason);
  final code = switch (statusCode) {
    401 || 403 => 'authentication',
    429 => quota ? 'quota_exhausted' : 'rate_limit',
    408 => 'timeout',
    int() && >= 500 => 'server',
    null when quota => 'quota_exhausted',
    null when reason.contains('rate_limit') => 'rate_limit',
    null
        when reason.contains('overloaded') || reason.contains('server_error') =>
      'server',
    null
        when reason.contains('authentication') ||
            reason.contains('permission') =>
      'authentication',
    null => 'stream_error',
    _ => 'http',
  };
  return AiProviderException(
    code,
    statusCode == null
        ? original
        : 'HTTP $statusCode${original.isEmpty ? '' : '\n$original'}',
    retryAfter: retryAfter,
  );
}
