// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class AiPromptOutputGuard {
  AiPromptOutputGuard(String system)
    : _passages = system
          .split(RegExp(r'[\n。]'))
          .map((s) => s.trim())
          .where((s) => s.length >= 48)
          .toList(growable: false);

  final List<String> _passages;

  String visible(String text) {
    var result = text;
    for (final passage in _passages) {
      result = result.replaceAll(passage, '');
      final start = result.lastIndexOf(passage.substring(0, 20));
      if (start >= 0 && passage.startsWith(result.substring(start))) {
        result = result.substring(0, start);
      }
    }
    return result.trimRight();
  }
}
