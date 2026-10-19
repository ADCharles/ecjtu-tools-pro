// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:shared_preferences/shared_preferences.dart';

class CreditCache {
  final _reads = <String, Future<Object>>{};
  final _fetchedAt = <String, DateTime>{};
  Duration lifetime = const Duration(minutes: 5);

  void invalidate() {
    _reads.clear();
    _fetchedAt.clear();
  }

  Future<T> read<T extends Object>({
    required String key,
    required T Function(String) parse,
    required Future<String> Function() fetch,
    bool offline = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    T? cached() {
      final text = preferences.getString(key);
      if (text == null) return null;
      try {
        return parse(text);
      } catch (_) {
        return null;
      }
    }

    if (offline) {
      final value = cached();
      if (value != null) return value;
      throw StateError('暂无学分缓存');
    }
    final existing = _reads[key];
    final fetchedAt = _fetchedAt[key];
    if (existing != null &&
        (fetchedAt == null ||
            DateTime.now().difference(fetchedAt) < lifetime)) {
      return await existing as T;
    }
    _reads.remove(key);
    _fetchedAt.remove(key);
    var succeeded = false;
    Future<T> load() async {
      try {
        final text = await fetch();
        final value = parse(text);
        await preferences.setString(key, text);
        succeeded = true;
        return value;
      } catch (_) {
        final value = cached();
        if (value != null) return value;
        rethrow;
      }
    }

    final task = load();
    _reads[key] = task;
    try {
      final value = await task;
      if (identical(_reads[key], task)) {
        if (succeeded) {
          _fetchedAt[key] = DateTime.now();
        } else {
          _reads.remove(key);
        }
      }
      return value;
    } catch (_) {
      if (identical(_reads[key], task)) _reads.remove(key);
      rethrow;
    }
  }
}
