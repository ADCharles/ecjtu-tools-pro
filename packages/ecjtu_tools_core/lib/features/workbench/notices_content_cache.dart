// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../update/update_models.dart';

class NoticesContentCache {
  NoticesContentCache._();
  static final instance = NoticesContentCache._();
  final _memory = <String, _ContentRecord>{};
  final _pending = <String, Future<Object>>{};
  Future<Directory>? _root;
  int _generation = 0;
  Future<Directory> _directory() => _root ??= () async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      '${support.path}/cache/notices-content',
    ).create(recursive: true);
  }();

  Future<T?> peek<T extends Object>(
    String key, {
    required Duration lifetime,
    required bool persistent,
    required T Function(Uint8List bytes) decode,
  }) async {
    if (lifetime <= Duration.zero) return null;
    final record = _memory[key];
    if (record != null && DateTime.now().difference(record.at) < lifetime) {
      return record.value as T;
    }
    if (!persistent) return null;
    try {
      final directory = await _directory();
      final hash = sha256Bytes(utf8.encode(key));
      final meta = File('${directory.path}/$hash.json');
      final data = File('${directory.path}/$hash.bin');
      if (!await meta.exists() ||
          !await data.exists() ||
          await meta.length() >= 4096 ||
          await data.length() > 50 * 1024 * 1024) {
        return null;
      }
      final info =
          jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      final at = DateTime.parse(info['at'] as String);
      if (info['key'] != key || DateTime.now().difference(at) >= lifetime) {
        return null;
      }
      final bytes = await data.readAsBytes();
      if (sha256Bytes(bytes) != info['sha256']) return null;
      return decode(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<T> get<T extends Object>(
    String key, {
    required Duration lifetime,
    required bool persistent,
    required Future<T> Function() load,
    required Uint8List Function(T value) encode,
    required T Function(Uint8List bytes) decode,
    bool force = false,
  }) async {
    if (!force && lifetime > Duration.zero) {
      final record = _memory[key];
      if (record != null && DateTime.now().difference(record.at) < lifetime) {
        return record.value as T;
      }
      if (persistent) {
        try {
          final directory = await _directory();
          final hash = sha256Bytes(utf8.encode(key));
          final meta = File('${directory.path}/$hash.json');
          final data = File('${directory.path}/$hash.bin');
          if (await meta.exists() &&
              await data.exists() &&
              await meta.length() < 4096) {
            final info =
                jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
            final at = DateTime.parse(info['at'] as String);
            if (info['key'] == key &&
                DateTime.now().difference(at) < lifetime &&
                await data.length() <= 50 * 1024 * 1024) {
              final bytes = await data.readAsBytes();
              if (sha256Bytes(bytes) == info['sha256']) {
                final value = decode(bytes);
                _remember(key, value, at, bytes.length);
                return value;
              }
            }
          }
        } catch (_) {}
      }
    }
    final pending = _pending[key];
    if (pending != null) return await pending as T;
    final generation = _generation;
    final task = () async {
      final value = await load();
      if (lifetime > Duration.zero && generation == _generation) {
        final bytes = encode(value);
        final at = DateTime.now();
        if (bytes.length <= 50 * 1024 * 1024) {
          _remember(key, value, at, bytes.length);
          if (persistent) {
            try {
              final directory = await _directory();
              final hash = sha256Bytes(utf8.encode(key));
              await File(
                '${directory.path}/$hash.bin',
              ).writeAsBytes(bytes, flush: true);
              await File('${directory.path}/$hash.json').writeAsString(
                jsonEncode({
                  'key': key,
                  'at': at.toIso8601String(),
                  'sha256': sha256Bytes(bytes),
                }),
                flush: true,
              );
              if (generation != _generation) {
                await File('${directory.path}/$hash.bin').delete();
                await File('${directory.path}/$hash.json').delete();
              } else {
                await _trim(directory);
              }
            } catch (_) {}
          }
        }
      }
      return value;
    }();
    _pending[key] = task;
    try {
      return await task;
    } finally {
      if (identical(_pending[key], task)) _pending.remove(key);
    }
  }

  void _remember(String key, Object value, DateTime at, int size) {
    _memory.remove(key);
    _memory[key] = _ContentRecord(value, at, size);
    while (_memory.length > 48 ||
        _memory.values.fold<int>(0, (n, r) => n + r.size) > 100 * 1024 * 1024) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<void> _trim(Directory directory) async {
    final files = await directory
        .list(followLinks: false)
        .where((e) => e is File && e.path.endsWith('.bin'))
        .cast<File>()
        .toList();
    final stats = <File, FileStat>{};
    for (final file in files) {
      stats[file] = await file.stat();
    }
    var total = stats.values.fold<int>(0, (n, s) => n + s.size);
    files.sort((a, b) => stats[a]!.modified.compareTo(stats[b]!.modified));
    for (final file in files) {
      if (total <= 200 * 1024 * 1024) break;
      total -= stats[file]!.size;
      await file.delete();
      final meta = File(file.path.replaceFirst(RegExp(r'\.bin$'), '.json'));
      if (await meta.exists()) await meta.delete();
    }
  }

  Future<void> clear({String? studentId, bool calendarOnly = false}) async {
    _generation++;
    bool matches(String key) => calendarOnly
        ? key.startsWith('calendar|')
        : studentId == null ||
              [
                'detail|$studentId|',
                'asset|$studentId|',
                'preview|$studentId|',
              ].any(key.startsWith);
    _memory.removeWhere((key, _) => matches(key));
    final directory = await _directory();
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !entity.path.endsWith('.json') ||
          await entity.length() >= 4096)
        continue;
      try {
        final info =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        if (!matches(info['key'] as String)) continue;
        final name = entity.uri.pathSegments.last;
        if (!RegExp(r'^[a-f0-9]{64}\.json$').hasMatch(name)) continue;
        final data = File(
          '${directory.path}/${name.replaceFirst('.json', '.bin')}',
        );
        if (await data.exists()) await data.delete();
        await entity.delete();
      } catch (_) {}
    }
  }
}

class _ContentRecord {
  const _ContentRecord(this.value, this.at, this.size);
  final Object value;
  final DateTime at;
  final int size;
}
