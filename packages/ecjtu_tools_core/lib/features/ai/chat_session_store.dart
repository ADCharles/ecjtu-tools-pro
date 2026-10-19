// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/serialized_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

import 'chat_models.dart';

abstract interface class AiChatSessionStore {
  Future<List<AiChatSession>> load(String namespace);
  Future<void> save(String namespace, List<AiChatSession> sessions);
}

class AiEncryptedChatSessionStore implements AiChatSessionStore {
  AiEncryptedChatSessionStore({
    FlutterSecureStorage? secureStorage,
    Future<Directory> Function()? directory,
  }) : _secure = secureStorage ?? const SerializedSecureStorage(),
       _directory = directory ?? getApplicationSupportDirectory;
  static const encryptionKey = 'ecjtu.ai.chat.memory.key.v1';
  static const recoveryKeys = 'ecjtu.ai.chat.memory.recovery.keys.v1';
  final FlutterSecureStorage _secure;
  final Future<Directory> Function() _directory;
  Future<Uint8List>? _key;

  Future<List<Uint8List>> _readRecoveryKeys() async {
    final raw = await _secure.read(key: recoveryKeys);
    if (raw == null || raw.isEmpty) return [];
    return [
      for (final encoded in jsonDecode(raw) as List)
        if (base64Decode(encoded as String).length == 32)
          Uint8List.fromList(base64Decode(encoded)),
    ];
  }

  final _pendingWrites = <String, _AiMemoryWrite>{};
  Completer<void>? _idle;
  int _revision = 0;
  final _recoveredNamespaces = <String>{};

  bool recoveredPrevious(String namespace) =>
      _recoveredNamespaces.contains(namespace);

  Future<void> flush() => _idle?.future ?? Future.value();

  Uint8List _random(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Future<Uint8List> _readKey({bool create = false}) {
    return _key ??= (() async {
      try {
        final raw = await _secure.read(key: encryptionKey);
        if (raw != null) {
          final value = base64Decode(raw);
          if (value.length != 32)
            throw const FormatException('Invalid memory key');
          return Uint8List.fromList(value);
        }
        final recovered = await _readRecoveryKeys();
        if (recovered.isNotEmpty) return recovered.first;
        final root = await _directory();
        final memory = Directory(
          '${root.path}${Platform.pathSeparator}ai-chat-memory',
        );
        if (!create ||
            (await memory.exists() &&
                await memory.list().any(
                  (entry) =>
                      entry is File &&
                      (entry.path.endsWith('.json') ||
                          entry.path.endsWith('.previous') ||
                          entry.path.endsWith('.pending')),
                ))) {
          throw const FormatException(
            'Conversation encryption key unavailable',
          );
        }
        final value = _random(32);
        await _secure.write(key: encryptionKey, value: base64Encode(value));
        return value;
      } catch (_) {
        _key = null;
        rethrow;
      }
    })();
  }

  Future<File> _file(String namespace) async {
    final root = await _directory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}ai-chat-memory',
    );
    await directory.create(recursive: true);
    final digest = base64Url
        .encode(
          SHA256Digest().process(Uint8List.fromList(utf8.encode(namespace))),
        )
        .replaceAll('=', '');
    return File('${directory.path}${Platform.pathSeparator}$digest.json');
  }

  @override
  Future<List<AiChatSession>> load(String namespace) async {
    await flush();
    final file = await _file(namespace);
    final candidates =
        <({String raw, int revision, DateTime modified, bool previous})>[];
    Object? failure;
    StackTrace? trace;
    var found = false;
    for (final suffix in ['', '.pending', '.previous']) {
      final candidate = File('${file.path}$suffix');
      if (!await candidate.exists()) continue;
      found = true;
      try {
        final raw = await candidate.readAsString();
        final envelope = jsonDecode(raw) as Map;
        candidates.add((
          raw: raw,
          revision: envelope['revision'] as int? ?? 0,
          modified: await candidate.lastModified(),
          previous: suffix == '.previous',
        ));
      } catch (error, stack) {
        failure = error;
        trace = stack;
      }
    }
    if (!found) return [];
    candidates.sort((a, b) {
      if (a.previous != b.previous) return a.previous ? 1 : -1;
      final revision = b.revision.compareTo(a.revision);
      return revision != 0 ? revision : b.modified.compareTo(a.modified);
    });
    final keys = [await _readKey(), ...await _readRecoveryKeys()];
    for (final candidate in candidates) {
      for (final key in keys) {
        try {
          final sessions = await compute(_openMemory, (
            namespace: namespace,
            key: key,
            raw: candidate.raw,
          ), debugLabel: 'chat-memory-read');
          _revision = max(_revision, candidate.revision);
          if (candidate.previous) {
            _recoveredNamespaces.add(namespace);
          } else {
            _recoveredNamespaces.remove(namespace);
          }
          return sessions;
        } catch (error, stack) {
          failure = error;
          trace = stack;
        }
      }
    }
    Error.throwWithStackTrace(
      failure ?? const FormatException('Unreadable conversation memory'),
      trace ?? StackTrace.current,
    );
  }

  @override
  Future<void> save(String namespace, List<AiChatSession> sessions) {
    // Capture before queuing so a later account switch cannot change the write.
    final completion = Completer<void>();
    final existing = _pendingWrites[namespace];
    _pendingWrites[namespace] = _AiMemoryWrite(
      List<AiChatSession>.of(sessions),
      [...?existing?.completions, completion],
    );
    if (_idle == null) {
      _idle = Completer<void>();
      scheduleMicrotask(_drainWrites);
    }
    return completion.future;
  }

  Future<void> _drainWrites() async {
    while (_pendingWrites.isNotEmpty) {
      final namespace = _pendingWrites.keys.first;
      final request = _pendingWrites.remove(namespace)!;
      try {
        final file = await _file(namespace);
        _revision = max(_revision + 1, DateTime.now().microsecondsSinceEpoch);
        final raw = await compute(_sealMemory, (
          namespace: namespace,
          key: await _readKey(create: true),
          nonce: _random(12),
          sessions: request.sessions,
          revision: _revision,
        ), debugLabel: 'chat-memory-write');
        final temporary = File('${file.path}.pending');
        await temporary.writeAsString(raw, flush: true);
        if (!_recoveredNamespaces.contains(namespace) && await file.exists()) {
          await file.copy('${file.path}.previous');
        }
        await temporary.rename(file.path);
        _recoveredNamespaces.remove(namespace);
        for (final completion in request.completions) {
          completion.complete();
        }
      } catch (error, stack) {
        for (final completion in request.completions) {
          completion.completeError(error, stack);
        }
      }
    }
    final idle = _idle;
    _idle = null;
    idle?.complete();
  }
}

class _AiMemoryWrite {
  const _AiMemoryWrite(this.sessions, this.completions);
  final List<AiChatSession> sessions;
  final List<Completer<void>> completions;
}

GCMBlockCipher _memoryCipher(
  bool encrypt,
  Uint8List key,
  Uint8List nonce,
  String namespace,
) => GCMBlockCipher(AESEngine())
  ..init(
    encrypt,
    AEADParameters(
      KeyParameter(key),
      128,
      nonce,
      Uint8List.fromList(utf8.encode(namespace)),
    ),
  );

String _sealMemory(
  ({
    String namespace,
    Uint8List key,
    Uint8List nonce,
    List<AiChatSession> sessions,
    int revision,
  })
  request,
) {
  final clear = Uint8List.fromList(
    gzip.encode(
      utf8.encode(
        jsonEncode([for (final session in request.sessions) session.toJson()]),
      ),
    ),
  );
  final encrypted = _memoryCipher(
    true,
    request.key,
    request.nonce,
    request.namespace,
  ).process(clear);
  return jsonEncode({
    'version': 2,
    'revision': request.revision,
    'nonce': base64Encode(request.nonce),
    'ciphertext': base64Encode(encrypted),
  });
}

List<AiChatSession> _openMemory(
  ({String namespace, Uint8List key, String raw}) request,
) {
  final envelope = jsonDecode(request.raw) as Map;
  if (envelope['version'] != 1 && envelope['version'] != 2) {
    throw const FormatException('Unsupported memory version');
  }
  final clear = _memoryCipher(
    false,
    request.key,
    Uint8List.fromList(base64Decode(envelope['nonce'] as String)),
    request.namespace,
  ).process(Uint8List.fromList(base64Decode(envelope['ciphertext'] as String)));
  final decoded = envelope['version'] == 2 ? gzip.decode(clear) : clear;
  final sessions = (jsonDecode(utf8.decode(decoded)) as List)
      .map((value) => AiChatSession.fromJson(value as Map))
      .toList();
  sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return sessions;
}

class AiMemoryChatSessionStore implements AiChatSessionStore {
  final _data = <String, String>{};
  @override
  Future<List<AiChatSession>> load(String namespace) async =>
      (jsonDecode(_data[namespace] ?? '[]') as List)
          .map((value) => AiChatSession.fromJson(value as Map))
          .toList();
  @override
  Future<void> save(String namespace, List<AiChatSession> sessions) async {
    _data[namespace] = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
  }
}
