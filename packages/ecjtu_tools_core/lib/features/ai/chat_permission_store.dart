// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

enum ChatPermissionMode {
  automatic('自动执行'),
  askChanges('重要操作先确认'),
  askEveryAction('每次执行前确认');

  const ChatPermissionMode(this.label);
  final String label;

  static ChatPermissionMode fromName(Object? name) =>
      values.firstWhere((mode) => mode.name == name, orElse: () => askChanges);
}

class ChatPermissionStore {
  ChatPermissionStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const preferencesKey = 'ecjtu.ai.chat.permission-mode.v1';
  final Future<SharedPreferences> Function() _preferences;

  Future<ChatPermissionMode> readMode() async {
    final scoped = ChatPermissionScope.currentMode;
    if (scoped != null) return scoped;
    try {
      // Reload because the external MCP gate may outlive the settings page.
      final prefs = await _preferences();
      await prefs.reload();
      final raw = prefs.getString(preferencesKey);
      return ChatPermissionMode.fromName(raw);
    } catch (_) {
      return ChatPermissionMode.askChanges;
    }
  }

  Future<void> writeMode(ChatPermissionMode mode) async {
    final prefs = await _preferences();
    if (!await prefs.setString(preferencesKey, mode.name)) {
      throw StateError('Permission mode could not be saved');
    }
  }
}

class ChatPermissionScope {
  static final Object _modeKey = Object();
  static ChatPermissionMode? get currentMode =>
      Zone.current[_modeKey] as ChatPermissionMode?;

  static T run<T>(ChatPermissionMode mode, T Function() operation) =>
      runZoned(operation, zoneValues: {_modeKey: mode});
}
