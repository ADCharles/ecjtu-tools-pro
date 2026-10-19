// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'ai_models.dart';
import 'ai_network_quota.dart';

class AiNetworkLimitsStore {
  AiNetworkLimitsStore({Directory? applicationSupportDirectory, File? file})
    : _directory = applicationSupportDirectory,
      _providedFile = file;

  final Directory? _directory;
  final File? _providedFile;
  Future<File>? _fileFuture;
  static final _tails = <String, Future<void>>{};

  Future<File> get file => _fileFuture ??= () async {
    if (_providedFile != null) return _providedFile;
    final directory = _directory ?? await getApplicationSupportDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}ai-connection'
      '${Platform.pathSeparator}network-limits.json',
    );
  }();

  Future<T> _locked<T>(Future<T> Function(File target) body) async {
    final target = await file;
    final key = Platform.isWindows
        ? target.absolute.path.toLowerCase()
        : target.absolute.path;
    final previous = _tails[key] ?? Future<void>.value();
    final released = Completer<void>();
    _tails[key] = released.future;
    await previous;
    RandomAccessFile? lock;
    var locked = false;
    try {
      await target.parent.create(recursive: true);
      lock = await File('${target.path}.lock').open(mode: FileMode.append);
      await lock.lock(FileLock.exclusive);
      locked = true;
      return await body(target);
    } on AiToolException {
      rethrow;
    } catch (_) {
      throw const AiToolException('network_limits_unavailable', '网络操作限额暂不可用');
    } finally {
      try {
        if (lock != null) {
          if (locked) await lock.unlock();
          await lock.close();
        }
      } catch (_) {
      } finally {
        released.complete();
        if (identical(_tails[key], released.future)) _tails.remove(key);
      }
    }
  }

  Future<AiNetworkLimits> read() => _locked((target) async {
    if (!await target.exists()) return const AiNetworkLimits();
    if (await target.length() > 4096) {
      throw const AiToolException('network_limits_corrupt', '网络操作限额记录无法读取');
    }
    try {
      final raw = jsonDecode(await target.readAsString());
      if (raw is! Map || raw['version'] != 1) throw const FormatException();
      return AiNetworkLimits.fromJson(raw['limits']);
    } catch (_) {
      throw const AiToolException('network_limits_corrupt', '网络操作限额记录无法读取');
    }
  });

  Future<void> write(AiNetworkLimits value) {
    AiNetworkLimits.fromJson(value.toJson());
    return _locked((target) async {
      final temporary = File('${target.path}.pending');
      await temporary.writeAsString(
        jsonEncode({'version': 1, 'limits': value.toJson()}),
        flush: true,
      );
      await temporary.rename(target.path);
    });
  }
}
