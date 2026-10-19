// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'network_diagnostics.dart';

class SessionRecoveryUnavailable implements Exception {
  const SessionRecoveryUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class SessionRecovery {
  final Object _initialAuthenticationKey = Object();
  final Object _manualRequestKey = Object();
  bool get manualRequest => Zone.current[_manualRequestKey] != null;
  Future<T> runManualRequest<T>(Future<T> Function() operation) => manualRequest
      ? operation()
      : runZoned(operation, zoneValues: {_manualRequestKey: <String>{}});
  bool get initialAuthentication =>
      Zone.current[_initialAuthenticationKey] == true;

  // Zone scope follows only this async chain, not concurrent page requests.
  Future<T> runInitialAuthentication<T>(Future<T> Function() operation) =>
      runZoned(operation, zoneValues: {_initialAuthenticationKey: true});

  bool enabled = true;
  bool offline = false;
  bool Function(String account)? isCurrentAccount;
  bool Function(Object error) isConfirmedFailure = (_) => false;
  void Function()? onChanged;
  final _running = <String, Future<Object?>>{};
  final _failures = <String, int>{};
  final _rejectedSessions = <String, int>{};
  final _paused = <String>{};
  final _labels = <String, String>{};
  String key(String account, String system) => '$account:$system';
  bool paused(String account, String system) =>
      _paused.contains(key(account, system));
  void reset(String account, String system) {
    final id = key(account, system);
    _paused.remove(id);
    _failures.remove(id);
    _rejectedSessions.remove(id);
  }

  void reportRecoveredSession(
    String account,
    String system, {
    required bool accepted,
  }) {
    final id = key(account, system);
    if (accepted) {
      _rejectedSessions.remove(id);
      return;
    }
    final count = (_rejectedSessions[id] ?? 0) + 1;
    _rejectedSessions[id] = count;
    if (count >= 3) _paused.add(id);
    onChanged?.call();
  }

  bool isBusy(String account, String system) =>
      _running.containsKey(key(account, system));
  bool get busy => _running.isNotEmpty;
  String get label => _labels.values.firstOrNull ?? '';
  String labelFor(String account, String system) =>
      _labels[key(account, system)] ?? '';
  bool needsAction(String account, String system) =>
      !enabled || _paused.contains(key(account, system));

  Future<T> run<T>(
    String account,
    String system,
    String label,
    Future<T> Function() operation, {
    bool manual = false,
  }) async {
    final id = key(account, system);
    final existing = _running[id];
    if (existing != null) return await existing as T;
    if (offline) throw const SessionRecoveryUnavailable('当前处于离线模式');
    final manualSystems = Zone.current[_manualRequestKey] as Set<String>?;
    if (manualSystems?.add(id) == true) reset(account, system);
    if (!manual &&
        ((!enabled && !initialAuthentication && manualSystems == null) ||
            _paused.contains(id))) {
      NetworkDiagnostics.record(
        'RECOVERY SKIP $system enabled=$enabled paused=${_paused.contains(id)}',
      );
      throw const SessionRecoveryUnavailable('请重新登录');
    }
    if (manual) {
      _failures.remove(id);
      _paused.remove(id);
      _rejectedSessions.remove(id);
    }
    final completer = Completer<T>();
    _running[id] = completer.future;
    _labels[id] = label;
    onChanged?.call();
    () async {
      try {
        while (true) {
          try {
            if (isCurrentAccount?.call(account) == false || offline) {
              throw const SessionRecoveryUnavailable('登录已取消');
            }
            final result = await operation();
            _failures.remove(id);
            _paused.remove(id);
            completer.complete(result);
            break;
          } catch (error, stack) {
            NetworkDiagnostics.record(
              'RECOVERY ERROR $system ${error.runtimeType} confirmed=${isConfirmedFailure(error)}',
            );
            final confirmed = isConfirmedFailure(error);
            if (confirmed) _failures[id] = (_failures[id] ?? 0) + 1;
            if (manual ||
                !confirmed ||
                (_failures[id] ?? 0) >= 3 ||
                (!enabled && !initialAuthentication && manualSystems == null) ||
                offline) {
              if (confirmed && (manual || (_failures[id] ?? 0) >= 3)) {
                _paused.add(id);
              }
              completer.completeError(error, stack);
              break;
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        }
      } finally {
        _running.remove(id);
        _labels.remove(id);
        onChanged?.call();
      }
    }();
    return completer.future;
  }
}
