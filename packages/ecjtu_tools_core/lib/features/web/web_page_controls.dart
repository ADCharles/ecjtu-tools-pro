// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

class WebPageControls {
  Object? _owner;
  Map<String, Object?> Function()? _read;
  Future<void> Function()? _back;

  void attach({
    required Object owner,
    required Map<String, Object?> Function() read,
    required Future<void> Function() back,
  }) {
    _owner = owner;
    _read = read;
    _back = back;
  }

  void detach(Object owner) {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _read = null;
    _back = null;
  }

  Map<String, Object?> get snapshot =>
      _read?.call() ??
      const {
        'ready': false,
        'loading': true,
        'canGoBack': false,
        'loadFailed': false,
        'loaded': false,
      };

  Future<void> goBack() async {
    if (_owner == null || snapshot['canGoBack'] != true) {
      throw StateError('网页当前不能后退');
    }
    await _back!();
  }

  Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final timer = Stopwatch()..start();
    while (timer.elapsed < timeout) {
      final state = snapshot;
      if (state['loadFailed'] == true) throw StateError('网页未能加载');
      if (state['ready'] == true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw TimeoutException('网页宿主暂未就绪');
  }

  Future<void> waitUntilLoaded({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final timer = Stopwatch()..start();
    while (timer.elapsed < timeout) {
      final state = snapshot;
      if (state['loadFailed'] == true) throw StateError('网页未能加载');
      if (state['ready'] == true && state['loaded'] == true) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw TimeoutException('网页仍在加载');
  }
}
