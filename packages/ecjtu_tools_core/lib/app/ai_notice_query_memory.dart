// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../features/workbench/notices_calendar_models.dart';

class AiNoticeQueryMemory {
  String? _account;
  final _pages =
      <
        ({NoticeSource source, String keyword, String category, int page}),
        NoticePage
      >{};

  void clear() {
    _account = null;
    _pages.clear();
  }

  void remember(
    String account,
    NoticePage page, {
    String keyword = '',
    String category = '',
  }) {
    _bind(account);
    final key = (
      source: page.source,
      keyword: keyword.trim().toLowerCase(),
      category: category,
      page: page.page,
    );
    _pages.remove(key);
    _pages[key] = page;
    while (_pages.length > 32) {
      _pages.remove(_pages.keys.first);
    }
  }

  NoticePage? read(
    String account,
    NoticeSource source, {
    NoticePage? preview,
    String keyword = '',
  }) {
    _bind(account);
    final query = keyword.trim().toLowerCase();
    final searched = [
      for (final entry in _pages.entries)
        if (entry.value.source == source &&
            query.isNotEmpty &&
            entry.key.keyword == query)
          entry.value,
    ];
    final pages = [
      if (searched.isNotEmpty)
        ...searched
      else ...[
        if (preview?.source == source) preview!,
        ..._pages.values.where((page) => page.source == source),
      ],
    ];
    if (pages.isEmpty) return null;
    final items = <String, NoticeItem>{};
    for (final page in pages) {
      for (final item in page.items) {
        items[item.id] = item;
      }
    }
    final latest = pages.last;
    return NoticePage(
      source: source,
      items: items.values.toList(),
      page: latest.page,
      pageSize: latest.pageSize,
      totalCount: latest.totalCount,
      hasMore: latest.hasMore,
      updatedAt: latest.updatedAt,
      cached: true,
      stale: latest.stale,
    );
  }

  bool containsSearch(String account, NoticeSource source, String keyword) {
    _bind(account);
    final query = keyword.trim().toLowerCase();
    return query.isNotEmpty &&
        _pages.keys.any((key) => key.source == source && key.keyword == query);
  }

  void _bind(String account) {
    if (_account == account) return;
    _account = account;
    _pages.clear();
  }
}
