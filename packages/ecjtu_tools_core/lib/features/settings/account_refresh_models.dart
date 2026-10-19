// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../data/app_models.dart';

enum AccountRefreshStatus {
  waiting,
  login,
  syncing,
  skipped,
  needsLogin,
  success,
  failed,
}

class AccountRefreshSummary {
  const AccountRefreshSummary({
    required this.studentId,
    required this.label,
    required this.authMode,
    required this.status,
    this.message = '',
  });

  final String studentId;
  final String label;
  final AuthMode authMode;
  final AccountRefreshStatus status;
  final String message;
}

class AccountRefreshState {
  const AccountRefreshState({
    this.running = false,
    this.activeStudentId = '',
    this.accounts = const <String, AccountRefreshSummary>{},
  });

  final bool running;
  final String activeStudentId;
  final Map<String, AccountRefreshSummary> accounts;

  List<AccountRefreshSummary> get summaries =>
      accounts.values.toList(growable: false);
}
