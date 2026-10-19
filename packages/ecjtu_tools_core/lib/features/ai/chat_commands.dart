// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

enum AiChatCommandTarget { model, permissions, agent }

class AiChatCommandResult {
  const AiChatCommandResult({
    this.openSettings,
    this.message,
    this.clearInput = true,
  });
  final AiChatCommandTarget? openSettings;
  final String? message;
  final bool clearInput;
}
