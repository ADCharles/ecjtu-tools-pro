// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class RunQueryCache {
  final _reads = <Object, Future<Object>>{};

  void clear() => _reads.clear();

  Future<T> read<T extends Object>(Object key, Future<T> Function() load) {
    final previous = _reads[key];
    if (previous != null) return previous.then((value) => value as T);
    late final Future<T> pending;
    pending = load().catchError((Object error, StackTrace stack) {
      if (identical(_reads[key], pending)) _reads.remove(key);
      Error.throwWithStackTrace(error, stack);
    });
    _reads[key] = pending;
    return pending;
  }
}
