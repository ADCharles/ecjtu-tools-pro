// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:typed_data';
import 'dart:convert';

enum NoticeSource { mobile, portal }

extension NoticeSourceDetails on NoticeSource {
  String get storageValue => switch (this) {
    NoticeSource.mobile => 'mobile',
    NoticeSource.portal => 'portal',
  };

  String get displayName => switch (this) {
    NoticeSource.mobile => '移动华交',
    NoticeSource.portal => '智慧交大',
  };
}

class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.title,
    required this.source,
    this.issuer = '',
    this.timestamp,
    this.unread = false,
    this.isTop = false,
    this.detailUrl,
  });

  final String id;
  final String title;
  final NoticeSource source;
  final String issuer;
  final int? timestamp;
  final bool unread;
  final bool isTop;
  final Uri? detailUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source.storageValue,
    'issuer': issuer,
    'timestamp': timestamp,
    'unread': unread,
    'isTop': isTop,
    'detailUrl': detailUrl?.toString() ?? '',
  };

  factory NoticeItem.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('通知项目格式无效');
    }
    final id = value['id']?.toString().trim() ?? '';
    final title = value['title']?.toString().trim() ?? '';
    if (id.isEmpty || title.isEmpty) {
      throw const FormatException('通知项目缺少必要字段');
    }
    final source = value['source']?.toString().trim() == 'portal'
        ? NoticeSource.portal
        : NoticeSource.mobile;
    final rawUrl = value['detailUrl']?.toString().trim() ?? '';
    return NoticeItem(
      id: id,
      title: title,
      source: source,
      issuer: value['issuer']?.toString().trim() ?? '',
      timestamp: _integer(value['timestamp']),
      unread: value['unread'] == true,
      isTop: value['isTop'] == true,
      detailUrl: rawUrl.isEmpty ? null : Uri.tryParse(rawUrl),
    );
  }

  NoticeItem copyWith({
    String? title,
    String? issuer,
    int? timestamp,
    bool? unread,
    bool? isTop,
    Uri? detailUrl,
  }) {
    return NoticeItem(
      id: id,
      title: title ?? this.title,
      source: source,
      issuer: issuer ?? this.issuer,
      timestamp: timestamp ?? this.timestamp,
      unread: unread ?? this.unread,
      isTop: isTop ?? this.isTop,
      detailUrl: detailUrl ?? this.detailUrl,
    );
  }
}

/// 通知分类（栏目）：移动华交 getPimTypeList / 智慧交大 getContentTypeList。
class NoticeCategory {
  const NoticeCategory({required this.id, required this.name});

  final String id;
  final String name;
}

class NoticePage {
  const NoticePage({
    required this.source,
    this.items = const <NoticeItem>[],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.hasMore = false,
    this.unreadCount = 0,
    this.updatedAt,
    this.cached = false,
    this.stale = false,
  });

  final NoticeSource source;
  final List<NoticeItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final int unreadCount;
  final DateTime? updatedAt;
  final bool cached;
  final bool stale;
}

class NoticeAttachment {
  const NoticeAttachment({required this.name, required this.url});

  final String name;
  final Uri url;
}

class NoticeDetail {
  const NoticeDetail({
    required this.id,
    required this.source,
    required this.title,
    this.issuer = '',
    this.time = '',
    this.content = '',
    this.contentBaseUrl,
    this.attachments = const <NoticeAttachment>[],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.name,
    'title': title,
    'issuer': issuer,
    'time': time,
    'content': content,
    'contentBaseUrl': contentBaseUrl?.toString(),
    'attachments': [
      for (final item in attachments)
        {'name': item.name, 'url': item.url.toString()},
    ],
  };
  factory NoticeDetail.fromJson(Map<String, dynamic> value) => NoticeDetail(
    id: value['id'] as String,
    source: NoticeSource.values.byName(value['source'] as String),
    title: value['title'] as String,
    issuer: value['issuer'] as String? ?? '',
    time: value['time'] as String? ?? '',
    content: value['content'] as String? ?? '',
    contentBaseUrl: value['contentBaseUrl'] == null
        ? null
        : Uri.parse(value['contentBaseUrl'] as String),
    attachments: [
      for (final item in value['attachments'] as List)
        NoticeAttachment(
          name: item['name'] as String,
          url: Uri.parse(item['url'] as String),
        ),
    ],
  );

  final String id;
  final NoticeSource source;
  final String title;
  final String issuer;
  final String time;
  final String content;
  final Uri? contentBaseUrl;
  final List<NoticeAttachment> attachments;
}

class SchoolCalendarEntry {
  const SchoolCalendarEntry({
    required this.academicYear,
    required this.title,
    required this.detailUrl,
    required this.fileUrl,
    this.format = '',
  });

  final String academicYear;
  final String title;
  final Uri detailUrl;
  final Uri? fileUrl;
  final String format;

  String get displayTitle =>
      title.replaceFirst(RegExp(r'\s*[-－—]\s*华东交通大学\s*$'), '').trim();

  String get fileExtension {
    if (format == 'xls' || format == 'xlsx' || format == 'pdf') return format;
    final source =
        '${title.toLowerCase()} ${fileUrl?.path.toLowerCase() ?? ''}';
    if (source.contains('.xlsx')) return 'xlsx';
    if (source.contains('.xls')) return 'xls';
    return 'pdf';
  }

  Map<String, dynamic> toJson() => {
    'academicYear': academicYear,
    'title': title,
    'detailUrl': detailUrl.toString(),
    'fileUrl': fileUrl?.toString() ?? '',
    'format': fileExtension,
  };

  factory SchoolCalendarEntry.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('校历项目格式无效');
    final academicYear = value['academicYear']?.toString().trim() ?? '';
    final title = value['title']?.toString().trim() ?? '';
    final detailUrl = Uri.tryParse(value['detailUrl']?.toString() ?? '');
    final rawFile =
        (value['fileUrl'] ?? value['pdfUrl'])?.toString().trim() ?? '';
    final fileUrl = rawFile.isEmpty ? null : Uri.tryParse(rawFile);
    if (academicYear.isEmpty || title.isEmpty || detailUrl == null) {
      throw const FormatException('校历项目缺少必要字段');
    }
    return SchoolCalendarEntry(
      academicYear: academicYear,
      title: title,
      detailUrl: detailUrl,
      fileUrl: fileUrl,
      format: value['format']?.toString() ?? '',
    );
  }
}

class SchoolCalendarCatalog {
  const SchoolCalendarCatalog({
    this.entries = const <SchoolCalendarEntry>[],
    this.selectedYear = '',
    this.updatedAt,
    this.cached = false,
  });

  final List<SchoolCalendarEntry> entries;
  final String selectedYear;
  final DateTime? updatedAt;
  final bool cached;

  SchoolCalendarEntry? get selected {
    for (final entry in entries) {
      if (entry.academicYear == selectedYear) return entry;
    }
    return entries.isEmpty ? null : entries.first;
  }
}

class SchoolCalendarFile {
  const SchoolCalendarFile({
    required this.academicYear,
    required this.fileName,
    required this.bytes,
    required this.extension,
  });

  final String academicYear;
  final String fileName;
  final Uint8List bytes;
  final String extension;

  Uint8List encodeCache() {
    final header = utf8.encode(
      jsonEncode({
        'academicYear': academicYear,
        'fileName': fileName,
        'extension': extension,
      }),
    );
    final result = Uint8List(header.length + 1 + bytes.length);
    result.setRange(0, header.length, header);
    result[header.length] = 10;
    result.setRange(header.length + 1, result.length, bytes);
    return result;
  }

  factory SchoolCalendarFile.decodeCache(Uint8List data) {
    final end = data.indexOf(10);
    if (end < 0 || end > 4096)
      throw const FormatException('Calendar cache header');
    final meta =
        jsonDecode(utf8.decode(data.sublist(0, end))) as Map<String, dynamic>;
    return SchoolCalendarFile(
      academicYear: meta['academicYear'] as String,
      fileName: meta['fileName'] as String,
      extension: meta['extension'] as String,
      bytes: Uint8List.sublistView(data, end + 1),
    );
  }

  bool get isPdf => extension == 'pdf';
}

class NoticesCalendarRequestException implements Exception {
  const NoticesCalendarRequestException(
    this.message, {
    this.code = 'REQUEST_FAILED',
    this.sessionExpired = false,
  });

  final String message;
  final String code;
  final bool sessionExpired;

  @override
  String toString() => message;
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
