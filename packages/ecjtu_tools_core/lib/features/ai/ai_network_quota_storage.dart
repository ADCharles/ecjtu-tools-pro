// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'ai_network_quota.dart';
import 'ai_network_limits_store.dart';

Future<AiNetworkQuota> createAiNetworkQuota({
  Directory? applicationSupportDirectory,
  AiNetworkLimits limits = const AiNetworkLimits(),
  AiNetworkLimitsStore? store,
  bool useCustomLimits = true,
}) async {
  final directory =
      applicationSupportDirectory ?? await getApplicationSupportDirectory();
  final effectiveStore =
      store ?? AiNetworkLimitsStore(applicationSupportDirectory: directory);
  return AiNetworkQuota(
    storageFile: File(
      '${directory.path}${Platform.pathSeparator}ai-connection'
      '${Platform.pathSeparator}network-quota.json',
    ),
    limits: limits,
    limitsProvider: useCustomLimits ? effectiveStore.read : null,
  );
}
