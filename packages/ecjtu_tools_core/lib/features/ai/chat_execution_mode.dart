// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'ai_models.dart';
import 'file_change.dart';

enum AiChatMode { chat, agent }

class AiAgentScope {
  const AiAgentScope({
    required this.mode,
    required this.workspace,
    required this.global,
    this.onPhase,
    this.ownerId,
    this.isCancelled,
    this.approve,
    this.onFileChanges,
  });
  final AiChatMode mode;
  final String workspace;
  final bool global;
  final void Function(String)? onPhase;
  final String? ownerId;
  final bool Function()? isCancelled;
  final Future<bool> Function(AiSemanticAction, Map<String, Object?>)? approve;
  final void Function(List<AiFileChange>)? onFileChanges;
  static final _key = Object();
  static AiAgentScope? get current => Zone.current[_key] as AiAgentScope?;
  T run<T>(T Function() operation) =>
      runZoned(operation, zoneValues: {_key: this});
}
