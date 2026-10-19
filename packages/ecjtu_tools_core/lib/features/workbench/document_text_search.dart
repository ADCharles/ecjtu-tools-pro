// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

class DocumentTextSearch {
  static Map<String, Object?> search(
    List<Map<String, Object?>> pages, {
    required String query,
    int offset = 0,
    int limit = 8,
    int contextCharacters = 240,
  }) {
    final terms = query
        .split(RegExp(r'[|\n]'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (terms.isEmpty ||
        query.length > 256 ||
        terms.length > 8 ||
        offset < 0 ||
        limit < 1 ||
        limit > 20 ||
        contextCharacters < 40 ||
        contextCharacters > 800) {
      throw const FormatException('Invalid document search');
    }
    final hits = <Map<String, Object?>>[];
    var hasText = false;
    for (final page in pages) {
      final text = page['text'] as String? ?? '';
      hasText |= text.trim().isNotEmpty;
      final lower = text.toLowerCase();
      var cursor = 0;
      while (cursor < text.length) {
        var found = -1;
        var matched = '';
        for (final term in terms) {
          final index = lower.indexOf(term, cursor);
          if (index >= 0 && (found < 0 || index < found)) {
            found = index;
            matched = term;
          }
        }
        if (found < 0) break;
        final start = math.max(0, found - contextCharacters);
        final end = math.min(
          text.length,
          found + matched.length + contextCharacters,
        );
        hits.add({
          'pageNumber': page['pageNumber'],
          'characterOffset': found,
          'matched': matched,
          'text': text.substring(start, end),
          'hasEarlierText': start > 0,
          'hasLaterText': end < text.length,
        });
        cursor = end;
      }
    }
    final selected = hits.skip(offset).take(limit).toList();
    return {
      'available': true,
      'contentStatus': hasText ? 'text' : 'no_text',
      'query': query,
      'pageCount': pages.length,
      'total': hits.length,
      'offset': offset,
      'nextOffset': offset + selected.length < hits.length
          ? offset + selected.length
          : null,
      'matches': selected,
    };
  }
}
