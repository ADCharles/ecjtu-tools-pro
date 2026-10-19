// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension _AiChatMultiAccount on AiChatController {
  bool _acceptTaskAccountSwitch(String? current) {
    final grant = _accountGrant;
    if (!busy ||
        current == null ||
        grant == null ||
        !grant.active ||
        !configuration.multiAccountInteraction ||
        bridge.switchingAccountId != current ||
        grant.targets[grant.switchRef] != current)
      return false;
    _accountId = current;
    _usedAccountGrant = true;
    _cancelTitle();
    return true;
  }

  void _closeAccountTaskContext() {
    _modelHistoryStart = _turns.length;
    _modelSummaryUsable = false;
    _modelAccountId = _accountId;
    _cancelTitle();
    final index = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (index >= 0) {
      _sessions[index] = _sessions[index].copyWith(titleSummaryAttempted: true);
    }
  }

  Iterable<List<AiProviderMessage>> get _modelTurns =>
      _turns.skip(_modelHistoryStart);

  String get _modelSummary => _modelSummaryUsable ? _summary : '';
}
