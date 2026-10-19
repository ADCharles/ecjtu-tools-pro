// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

typedef AiChatThumbnailReader = Future<Uint8List?> Function(String id);

class AiChatAttachmentThumbnailCache {
  AiChatAttachmentThumbnailCache(
    this.read, {
    this.maxEntries = 24,
    this.maxBytes = 16 * 1024 * 1024,
  });
  final AiChatThumbnailReader read;
  final int maxEntries, maxBytes;
  final _ready = <String, ({ImageProvider image, int bytes})>{};
  final _pending = <String, Future<ImageProvider?>>{};
  final _queue =
      Queue<({String id, int generation, Completer<ImageProvider?> result})>();
  int _active = 0, _generation = 0, _bytes = 0;
  bool _disposed = false;

  Future<ImageProvider?> load(String id) {
    if (_disposed) return Future.value(null);
    final cached = _ready.remove(id);
    if (cached != null) {
      _ready[id] = cached;
      return Future.value(cached.image);
    }
    if (_pending[id] case final future?) return future;
    if (_pending.length >= maxEntries) return Future.value(null);
    final result = Completer<ImageProvider?>();
    _pending[id] = result.future;
    _queue.add((id: id, generation: _generation, result: result));
    _pump();
    return result.future;
  }

  void _pump() {
    while (!_disposed && _active < 2 && _queue.isNotEmpty) {
      final item = _queue.removeFirst();
      _active++;
      unawaited(_resolve(item));
    }
  }

  Future<void> _resolve(
    ({String id, int generation, Completer<ImageProvider?> result}) item,
  ) async {
    ImageProvider? image;
    try {
      final bytes = await read(item.id).timeout(const Duration(seconds: 8));
      if (!_disposed &&
          item.generation == _generation &&
          bytes != null &&
          bytes.isNotEmpty &&
          bytes.length <= maxBytes) {
        image = ResizeImage(
          MemoryImage(bytes),
          width: 96,
          height: 96,
          policy: ResizeImagePolicy.fit,
        );
        _ready[item.id] = (image: image, bytes: bytes.length);
        _bytes += bytes.length;
        while (_ready.length > maxEntries || _bytes > maxBytes) {
          final old = _ready.remove(_ready.keys.first)!;
          _bytes -= old.bytes;
          unawaited(old.image.evict());
        }
      }
    } catch (_) {
      image = null;
    } finally {
      if (item.generation == _generation) _pending.remove(item.id);
      if (!item.result.isCompleted) item.result.complete(image);
      _active--;
      _pump();
    }
  }

  void clear() {
    _generation++;
    for (final value in _ready.values) {
      unawaited(value.image.evict());
    }
    _ready.clear();
    _pending.clear();
    _bytes = 0;
    while (_queue.isNotEmpty) {
      _queue.removeFirst().result.complete(null);
    }
  }

  void dispose() {
    _disposed = true;
    clear();
  }
}
