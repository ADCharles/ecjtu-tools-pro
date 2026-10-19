// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

enum SettingsSyncState { idle, pending, success, partial, error }

class DataSyncText {
  const DataSyncText({required this.status, this.time});

  factory DataSyncText.fromFeedback(String feedback) {
    final lines = feedback.split('\n');
    return DataSyncText(
      status: lines.first,
      time: lines.length > 1 ? lines.skip(1).join('\n') : null,
    );
  }

  final String status;
  final String? time;

  String get details => [status, if (time != null) time!].join('\n');

  String actionTooltip({required bool refreshing}) =>
      '${refreshing ? '正在同步' : '同步数据'}\n$details';
}

class SettingsSyncItem {
  const SettingsSyncItem({
    required this.label,
    required this.state,
    this.syncedAt,
    this.onPressed,
  });

  final String label;
  final SettingsSyncState state;
  final DateTime? syncedAt;
  final VoidCallback? onPressed;
}
