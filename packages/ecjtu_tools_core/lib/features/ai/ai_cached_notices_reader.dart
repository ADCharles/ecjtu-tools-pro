// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../workbench/notices_calendar_models.dart';
import '../update/update_models.dart' show sha256Bytes;

typedef AiNoticeDetailPeek =
    FutureOr<NoticeDetail?> Function({
      required String key,
      required Duration lifetime,
      required bool persistent,
    });

/// Snapshot access that has no HTTP loader and preserves the content cache policy.
class AiCachedNoticesReader {
  /// The host can bind its existing cache's memory/persistent peek here.
  static AiNoticeDetailPeek? detailPeek;

  static Future<Map<String, Object?>> notices({
    required String studentId,
    required NoticeSource source,
    required Map<String, Object?> args,
    NoticePage? memory,
    bool serverSearch = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _decode(
      preferences.getString(
        'ecjtu.workbench.notices.${source.storageValue}.${Uri.encodeComponent(studentId)}',
      ),
    );
    final items = <String, NoticeItem>{};
    for (final raw
        in serverSearch ? const [] : cache?['items'] as List? ?? const []) {
      try {
        final item = NoticeItem.fromJson(raw);
        if (item.source == source) items[item.id] = item;
      } on FormatException {
        /* Ignore a damaged entry without hiding the rest. */
      }
    }
    final currentMemory = memory?.source == source ? memory : null;
    if (currentMemory != null) {
      for (final item in currentMemory.items) {
        items[item.id] = item;
      }
    }
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final limit = args['limit'] as int? ?? 20;
    final filtered =
        items.values
            .where(
              (n) =>
                  serverSearch ||
                  query.isEmpty ||
                  '${n.title} ${n.issuer}'.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
    final updatedAt =
        currentMemory?.updatedAt ?? _timestamp(cache?['updatedAt']);
    return {
      'title': '通知与校历',
      'sectionTitle': '通知列表',
      'available': cache != null || currentMemory != null,
      'noticeSource': source.storageValue,
      'serverSearch': serverSearch,
      'updatedAt': updatedAt?.toIso8601String(),
      'cachedCount': items.length,
      'total': filtered.length,
      'serverTotal': currentMemory?.totalCount ?? cache?['totalCount'],
      'hasMore': currentMemory?.hasMore ?? cache?['hasMore'],
      'unknownDateCount': filtered
          .where((n) => _timestamp(n.timestamp) == null)
          .length,
      'records': [
        for (final notice in filtered.take(limit))
          {
            'id': notice.id,
            'title': notice.title,
            'issuer': notice.issuer,
            'timestamp': notice.timestamp,
            'date': _timestamp(notice.timestamp)?.toIso8601String(),
            'unread': notice.unread,
            'isTop': notice.isTop,
            'fields': [
              {'label': '标题', 'value': notice.title},
              {'label': '发布单位', 'value': notice.issuer},
            ],
          },
      ],
    };
  }

  static Future<Map<String, Object?>> detail({
    required String studentId,
    required String authMode,
    required String id,
    required Duration lifetime,
    required bool persistent,
    AiNoticeDetailPeek? peek,
    Directory? supportDirectory,
  }) async {
    final key = 'detail|$studentId|$authMode|$id';
    final reader = peek ?? detailPeek;
    final detail = lifetime <= Duration.zero
        ? null
        : reader == null
        ? await _persistentDetail(
            key,
            lifetime: lifetime,
            persistent: persistent,
            supportDirectory: supportDirectory,
          )
        : await reader(key: key, lifetime: lifetime, persistent: persistent);
    return {
      'title': '通知详情',
      'available': detail != null,
      'id': id,
      if (detail != null) 'data': formatDetail(detail),
    };
  }

  static Future<NoticeDetail?> _persistentDetail(
    String key, {
    required Duration lifetime,
    required bool persistent,
    Directory? supportDirectory,
  }) async {
    if (!persistent) return null;
    try {
      final support =
          supportDirectory ?? await getApplicationSupportDirectory();
      final hash = sha256Bytes(utf8.encode(key));
      final meta = File('${support.path}/cache/notices-content/$hash.json');
      final file = File('${support.path}/cache/notices-content/$hash.bin');
      if (!await meta.exists() ||
          !await file.exists() ||
          await meta.length() >= 4096 ||
          await file.length() > 50 * 1024 * 1024) {
        return null;
      }
      final info = jsonDecode(await meta.readAsString()) as Map;
      final at = DateTime.parse(info['at'] as String);
      if (info['key'] != key || DateTime.now().difference(at) >= lifetime) {
        return null;
      }
      final bytes = await file.readAsBytes();
      if (sha256Bytes(bytes) != info['sha256']) return null;
      return NoticeDetail.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?> formatDetail(NoticeDetail detail) {
    final fragment = html_parser.parseFragment(detail.content);
    for (final element in fragment.querySelectorAll('script,style')) {
      element.remove();
    }
    for (final element in fragment.querySelectorAll('br')) {
      element.replaceWith(html_parser.parseFragment('\n'));
    }
    final text = (fragment.text ?? '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
    return {
      'id': detail.id,
      'title': detail.title,
      'issuer': detail.issuer,
      'time': detail.time,
      'content': text,
      'noticeSource': detail.source.storageValue,
      'attachments': [
        for (final attachment in detail.attachments) {'name': attachment.name},
      ],
    };
  }

  static Future<Map<String, Object?>> schoolCalendar(
    Map<String, Object?> args,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final cache = _decode(
      preferences.getString('ecjtu.workbench.schoolCalendar'),
    );
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final year = args['year'] as String?;
    final entries = <SchoolCalendarEntry>[];
    for (final raw in cache?['entries'] as List? ?? const []) {
      try {
        final entry = SchoolCalendarEntry.fromJson(raw);
        if ((year == null || year == entry.academicYear) &&
            (query.isEmpty ||
                entry.displayTitle.toLowerCase().contains(query))) {
          entries.add(entry);
        }
      } on FormatException {
        /* Keep valid catalog entries. */
      }
    }
    return {
      'title': '校历',
      'available': cache != null,
      'updatedAt': _timestamp(cache?['updatedAt'])?.toIso8601String(),
      'total': entries.length,
      'entries': [
        for (final entry in entries.take(args['limit'] as int? ?? 20))
          {
            'year': entry.academicYear,
            'title': entry.displayTitle,
            'format': entry.fileExtension,
            'sourceUrl': entry.detailUrl.toString(),
          },
      ],
    };
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _timestamp(Object? value) =>
      value is num && value.isFinite && value > 0
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
      : null;
}
