// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import '../workbench/document_text_search.dart';
import '../workbench/pdf_content_reader.dart';
import 'ai_bridge.dart';
import 'attachment_models.dart';

class AiDocumentTools {
  AiDocumentTools({required this.lookup});
  final Future<AiChatAttachment?> Function(String) lookup;
  final _pdf = PdfContentReader();
  static const names = {'search_document', 'read_document'};

  List<Map<String, Object?>> get tools => [
    for (final search in [true, false])
      {
        'name': search ? 'search_document' : 'read_document',
        'description': search
            ? '搜索本会话附件正文，返回匹配页码/行号及附近片段。关键词为字面文本，同义词用 | 分隔。先搜索再按范围读取，不整本输出。'
            : '按范围读取本会话附件。PDF offset 为从0开始的页偏移，limit最多8页；文本 offset为从0开始的行偏移，limit最多100行。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'attachmentId': {'type': 'string'},
            if (search) 'query': {'type': 'string', 'maxLength': 256},
            'offset': {'type': 'integer', 'minimum': 0},
            'limit': {
              'type': 'integer',
              'minimum': 1,
              'maximum': search ? 20 : 100,
            },
          },
          'required': ['attachmentId', if (search) 'query'],
          'additionalProperties': false,
        },
      },
  ];

  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> args, {
    bool Function()? isCancelled,
  }) async {
    final search = name == 'search_document';
    final keys = {'attachmentId', 'offset', 'limit', if (search) 'query'};
    final id = args['attachmentId'];
    final offset = args['offset'] ?? 0,
        limit = args['limit'] ?? (search ? 8 : 8);
    if (!names.contains(name) ||
        args.keys.any((k) => !keys.contains(k)) ||
        id is! String ||
        id.isEmpty ||
        id.length > 256 ||
        offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > (search ? 20 : 100) ||
        (search && args['query'] is! String)) {
      return AiBridge.failure('invalid_arguments', '请提供附件 ID 和有效读取范围');
    }
    if (isCancelled?.call() == true)
      return AiBridge.failure('action_cancelled', '此操作已取消');
    final document = await lookup(id);
    if (document == null || document.summary.kind == AiAttachmentKind.image) {
      return AiBridge.failure('document_unavailable', '此附件正文当前无法读取');
    }
    Map<String, Object?> result;
    try {
      if (document.summary.kind == AiAttachmentKind.pdf) {
        final bytes = base64Decode(document.encodedData);
        result = search
            ? await _pdf.search(
                bytes,
                query: args['query'] as String,
                offset: offset,
                limit: limit,
                isCancelled: isCancelled,
              )
            : await _pdf.read(
                bytes,
                offset: offset,
                limit: limit.clamp(1, 8),
                isCancelled: isCancelled,
              );
      } else {
        final lines = document.extractedText.split('\n');
        if (search) {
          final hits = DocumentTextSearch.search(
            [
              for (var i = 0; i < lines.length; i++)
                {'pageNumber': i + 1, 'text': lines[i]},
            ],
            query: args['query'] as String,
            offset: offset,
            limit: limit,
          );
          result = {
            ...hits,
            'lineCount': lines.length,
            'matches': [
              for (final h in hits['matches'] as List)
                {'lineNumber': h['pageNumber'], 'text': h['text']},
            ],
          }..remove('pageCount');
        } else {
          final selected = lines.skip(offset).take(limit).toList();
          final text = selected.join('\n');
          result = {
            'available': true,
            'lineCount': lines.length,
            'offset': offset,
            'nextOffset': offset + selected.length < lines.length
                ? offset + selected.length
                : null,
            'text': text.length <= 16000 ? text : text.substring(0, 16000),
            'truncatedText': text.length > 16000,
          };
        }
      }
    } on FormatException {
      return AiBridge.failure('invalid_document', '附件格式或查询范围无法读取');
    }
    if (isCancelled?.call() == true)
      return AiBridge.failure('action_cancelled', '此操作已取消');
    final data = {'attachmentId': id, 'name': document.summary.name, ...result};
    return {
      'isError': false,
      'structuredContent': data,
      'content': [
        {'type': 'text', 'text': jsonEncode(data)},
      ],
    };
  }
}
