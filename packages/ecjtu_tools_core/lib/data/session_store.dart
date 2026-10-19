// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'serialized_secure_storage.dart';

import 'app_models.dart';

class SessionSnapshot {
  const SessionSnapshot({
    this.cookies = const <String, String>{},
    this.values = const <String, String>{},
  });

  final Map<String, String> cookies;
  final Map<String, String> values;

  bool get isEmpty => cookies.isEmpty && values.isEmpty;

  Map<String, dynamic> toJson() => {'cookies': cookies, 'values': values};

  static SessionSnapshot fromJson(Object? value) {
    if (value is! Map) return const SessionSnapshot();
    Map<String, String> strings(Object? source) {
      if (source is! Map) return const <String, String>{};
      return Map<String, String>.fromEntries(
        source.entries
            .map(
              (entry) =>
                  MapEntry(entry.key.toString(), entry.value?.toString() ?? ''),
            )
            .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
      );
    }

    return SessionSnapshot(
      cookies: strings(value['cookies']),
      values: strings(value['values']),
    );
  }

  SessionSnapshot copyWith({
    Map<String, String>? cookies,
    Map<String, String>? values,
  }) {
    return SessionSnapshot(
      cookies: Map<String, String>.unmodifiable(cookies ?? this.cookies),
      values: Map<String, String>.unmodifiable(values ?? this.values),
    );
  }
}

abstract interface class SessionStore {
  SessionSnapshot read(String studentId, SessionPartition partition);

  void clearPartition(String studentId, SessionPartition partition);

  void write(
    String studentId,
    SessionPartition partition,
    SessionSnapshot snapshot,
  );

  void clearAccount(String studentId);

  void clearAll();
}

class MemorySessionStore implements SessionStore {
  final _sessions = <String, Map<SessionPartition, SessionSnapshot>>{};

  @override
  SessionSnapshot read(String studentId, SessionPartition partition) {
    return _sessions[studentId]?[partition] ?? const SessionSnapshot();
  }

  @override
  void clearPartition(String studentId, SessionPartition partition) {
    final account = _sessions[studentId];
    account?.remove(partition);
    if (account?.isEmpty ?? false) _sessions.remove(studentId);
  }

  @override
  void write(
    String studentId,
    SessionPartition partition,
    SessionSnapshot snapshot,
  ) {
    final account = _sessions.putIfAbsent(
      studentId,
      () => <SessionPartition, SessionSnapshot>{},
    );
    account[partition] = snapshot;
  }

  @override
  void clearAccount(String studentId) {
    _sessions.remove(studentId);
  }

  @override
  void clearAll() {
    _sessions.clear();
  }
}

class PersistentSessionStore extends MemorySessionStore {
  PersistentSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const SerializedSecureStorage();

  static const _keyPrefix = 'ecjtu.auth.sessions.';
  final FlutterSecureStorage _storage;
  final _persistQueues = <String, Future<void>>{};
  final _knownStudentIds = <String>{};

  Future<void> restore(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    _knownStudentIds.add(target);
    final encoded = await _storage.read(key: _key(target));
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        final partition = SessionPartitionDetails.fromStorage(entry.key);
        if (partition == null) continue;
        final snapshot = SessionSnapshot.fromJson(entry.value);
        if (!snapshot.isEmpty) super.write(target, partition, snapshot);
      }
    } catch (_) {
      await _storage.delete(key: _key(target));
    }
  }

  Future<void> restoreAll(Iterable<String> studentIds) async {
    for (final studentId in studentIds) {
      await restore(studentId);
    }
  }

  Future<void> flush() async {
    while (_persistQueues.isNotEmpty) {
      await Future.wait(List<Future<void>>.from(_persistQueues.values));
    }
  }

  @override
  void write(
    String studentId,
    SessionPartition partition,
    SessionSnapshot snapshot,
  ) {
    _knownStudentIds.add(studentId.trim());
    super.write(studentId, partition, snapshot);
    _schedulePersist(studentId);
  }

  @override
  void clearPartition(String studentId, SessionPartition partition) {
    _knownStudentIds.add(studentId.trim());
    super.clearPartition(studentId, partition);
    _schedulePersist(studentId);
  }

  @override
  void clearAccount(String studentId) {
    _knownStudentIds.add(studentId.trim());
    super.clearAccount(studentId);
    _schedulePersist(studentId);
  }

  @override
  void clearAll() {
    final ids = Set<String>.from(_knownStudentIds);
    super.clearAll();
    for (final studentId in ids) {
      _schedulePersist(studentId);
    }
  }

  void _schedulePersist(String studentId) {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final previous = _persistQueues[target] ?? Future<void>.value();
    final next = previous.catchError((_) {}).then((_) => _persistNow(target));
    _persistQueues[target] = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_persistQueues[target], next)) {
          _persistQueues.remove(target);
        }
      }),
    );
  }

  Future<void> _persistNow(String studentId) async {
    final payload = <String, dynamic>{};
    for (final partition in SessionPartition.values) {
      final snapshot = super.read(studentId, partition);
      if (!snapshot.isEmpty) {
        payload[partition.storageValue] = snapshot.toJson();
      }
    }
    if (payload.isEmpty) {
      await _storage.delete(key: _key(studentId));
      _knownStudentIds.remove(studentId);
    } else {
      await _storage.write(key: _key(studentId), value: jsonEncode(payload));
    }
  }

  String _key(String studentId) =>
      '$_keyPrefix${base64Url.encode(utf8.encode(studentId))}';
}
