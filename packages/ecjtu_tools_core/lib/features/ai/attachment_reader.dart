// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html;

import '../workbench/pdf_content_reader.dart';
import 'attachment_models.dart';
import 'provider_models.dart';
import 'office_document_reader.dart';

typedef AiAttachmentPicker = Future<List<XFile>> Function(bool imagesOnly);
typedef AiAttachmentPdfRead =
    Future<Map<String, Object?>> Function(
      Uint8List bytes, {
      int offset,
      int limit,
      bool Function()? isCancelled,
    });

Future<List<XFile>> pickAiAttachmentFiles(bool imagesOnly) => openFiles(
  acceptedTypeGroups: [
    XTypeGroup(
      label: imagesOnly ? '图片' : '附件',
      extensions: imagesOnly
          ? ['png', 'jpg', 'jpeg', 'gif', 'webp']
          : [
              'png',
              'jpg',
              'jpeg',
              'gif',
              'webp',
              'pdf',
              'docx',
              'xlsx',
              'pptx',
              'txt',
              'md',
              'csv',
              'json',
            ],
      mimeTypes: imagesOnly
          ? ['image/png', 'image/jpeg', 'image/gif', 'image/webp']
          : [
              'image/*',
              'application/pdf',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
              'text/*',
              'application/json',
            ],
      uniformTypeIdentifiers: imagesOnly
          ? ['public.image']
          : [
              'public.image',
              'com.adobe.pdf',
              'org.openxmlformats.wordprocessingml.document',
              'public.text',
              'public.json',
            ],
    ),
  ],
);

class AiAttachmentReader {
  AiAttachmentReader({bool? desktop, AiAttachmentPdfRead? pdfRead})
    : desktop =
          desktop ??
          (!kIsWeb &&
              !{
                TargetPlatform.android,
                TargetPlatform.iOS,
              }.contains(defaultTargetPlatform)),
      _pdfRead = pdfRead ?? PdfContentReader().read;

  static const maxImageBytes = 8 * 1024 * 1024;
  static const maxFileBytes = 20 * 1024 * 1024;
  static const maxTotalBytes = 32 * 1024 * 1024;
  static const maxAttachments = 6;
  static const maxTextCharacters = 200000;
  static const maxPdfPages = 120;
  final bool desktop;
  final AiAttachmentPdfRead _pdfRead;

  Future<AiChatAttachment> read(
    AiAttachmentInput input,
    AiChatCancellation cancellation,
  ) async {
    cancellation.check();
    if (input.bytes.isEmpty || input.bytes.length > maxFileBytes) {
      throw const AiProviderException(
        'attachment_size',
        '附件为空或超过 20 MB，请选择较小的文件',
      );
    }
    final id =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    final prepared = await cancellation.race(
      compute(_prepareAttachment, (
        input: input,
        id: id,
        desktop: desktop,
      ), debugLabel: 'ai-attachment-import'),
      timeout: const Duration(seconds: 60),
    );
    cancellation.check();
    if (prepared.summary.kind != AiAttachmentKind.pdf || !desktop)
      return prepared;
    final text = StringBuffer();
    var offset = 0;
    var pageCount = 0;
    var partial = false;
    try {
      while (offset < maxPdfPages && text.length < maxTextCharacters) {
        final result = await cancellation.race(
          _pdfRead(
            input.bytes,
            offset: offset,
            limit: 24,
            isCancelled: () => cancellation.isCancelled,
          ),
          timeout: const Duration(seconds: 30),
        );
        cancellation.check();
        pageCount = result['pageCount'] as int? ?? pageCount;
        final pages = result['pages'] as List? ?? const [];
        for (final page in pages.whereType<Map>()) {
          final body = page['text'] as String? ?? '';
          if (body.isEmpty) continue;
          final numbered = '第${page['pageNumber']}页\n$body\n';
          final remaining = maxTextCharacters - text.length;
          text.write(
            numbered.length <= remaining
                ? numbered
                : numbered.substring(0, remaining),
          );
          partial |= numbered.length > remaining || page['truncated'] == true;
          if (partial) break;
        }
        partial |= result['truncatedText'] == true;
        final next = result['nextOffset'];
        if (next == null) break;
        if (next is! int || next <= offset) throw const FormatException();
        offset = next;
        if (partial) break;
        partial |= offset >= maxPdfPages || text.length >= maxTextCharacters;
      }
    } on AiProviderException {
      rethrow;
    } catch (_) {
      cancellation.check();
      throw const AiProviderException(
        'attachment_read',
        'PDF 正文暂时无法读取，请检查文件后重试',
      );
    }
    return AiChatAttachment(
      summary: AiAttachmentSummary.fromJson({
        ...prepared.summary.toJson(),
        'partialText': partial,
      }),
      encodedData: prepared.encodedData,
      extractedText: text.toString().trim(),
      pageCount: pageCount,
    );
  }
}

AiChatAttachment _prepareAttachment(
  ({AiAttachmentInput input, String id, bool desktop}) args,
) {
  final bytes = args.input.bytes;
  final name = args.input.name
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[\x00-\x1f]'), '')
      .trim();
  if (name.isEmpty || name.length > 240) {
    throw const AiProviderException('attachment_type', '附件名称无法使用，请重新选择');
  }
  final extension = name.split('.').last.toLowerCase();
  bool prefix(List<int> value) =>
      bytes.length >= value.length &&
      List.generate(value.length, (i) => bytes[i] == value[i]).every((v) => v);
  AiAttachmentKind kind;
  String mime;
  String body = '';
  if ({'png', 'jpg', 'jpeg', 'gif', 'webp'}.contains(extension)) {
    mime = switch (extension) {
      'png' when prefix([137, 80, 78, 71, 13, 10, 26, 10]) => 'image/png',
      'jpg' || 'jpeg' when prefix([255, 216, 255]) => 'image/jpeg',
      'gif'
          when prefix(ascii.encode('GIF87a')) ||
              prefix(ascii.encode('GIF89a')) =>
        'image/gif',
      'webp'
          when prefix(ascii.encode('RIFF')) &&
              bytes.length >= 12 &&
              ascii.decode(bytes.sublist(8, 12)) == 'WEBP' =>
        'image/webp',
      _ => throw const AiProviderException(
        'attachment_type',
        '图片内容与格式不符，请重新选择',
      ),
    };
    if (bytes.length > AiAttachmentReader.maxImageBytes) {
      throw const AiProviderException('attachment_size', '图片超过 8 MB，请缩小后重试');
    }
    kind = AiAttachmentKind.image;
  } else if (extension == 'pdf' && prefix(ascii.encode('%PDF-'))) {
    kind = AiAttachmentKind.pdf;
    mime = 'application/pdf';
  } else if (extension == 'docx' && prefix([80, 75, 3, 4])) {
    if (!args.desktop)
      throw const AiProviderException(
        'attachment_unsupported',
        '此设备暂不支持读取 DOCX，请选择 PDF 或文本',
      );
    kind = AiAttachmentKind.document;
    mime =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    body = _docxText(bytes);
  } else if ({'xlsx', 'pptx'}.contains(extension)) {
    if (!args.desktop)
      throw const AiProviderException('attachment_type', '请在电脑端读取此文件');
    kind = AiAttachmentKind.document;
    mime = extension == 'xlsx'
        ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        : 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    body = readOfficeDocument(bytes, extension);
  } else if ({'txt', 'md', 'csv', 'json'}.contains(extension)) {
    kind = AiAttachmentKind.text;
    mime = extension == 'json'
        ? 'application/json'
        : extension == 'csv'
        ? 'text/csv'
        : 'text/plain';
    try {
      body = utf8.decode(bytes).replaceFirst('\ufeff', '');
      if (body.contains('\u0000')) throw const FormatException();
    } catch (_) {
      throw const AiProviderException(
        'attachment_read',
        '文本编码无法读取，请使用 UTF-8 文件',
      );
    }
  } else {
    throw const AiProviderException('attachment_type', '请选择图片、PDF、DOCX 或文本文件');
  }
  if (body.length > AiAttachmentReader.maxTextCharacters) {
    throw const AiProviderException('attachment_size', '附件正文过长，请拆分文件后重试');
  }
  if ({AiAttachmentKind.text, AiAttachmentKind.document}.contains(kind) &&
      body.trim().isEmpty) {
    throw const AiProviderException('attachment_read', '附件中没有可读取的正文');
  }
  return AiChatAttachment(
    summary: AiAttachmentSummary(
      id: args.id,
      name: name,
      mimeType: mime,
      byteLength: bytes.length,
      kind: kind,
    ),
    encodedData: base64Encode(bytes),
    extractedText: body,
  );
}

String _docxText(Uint8List bytes) {
  try {
    final directory = ZipDirectory()..read(InputMemoryStream(bytes));
    if (directory.fileHeaders.isEmpty || directory.fileHeaders.length > 2048)
      throw const FormatException();
    var expanded = 0;
    for (final file in directory.fileHeaders) {
      expanded += file.uncompressedSize;
      if (expanded > 32 * 1024 * 1024 ||
          file.uncompressedSize > 8 * 1024 * 1024 ||
          file.filename.contains('..') ||
          file.filename.startsWith('/') ||
          file.filename.contains('\\') ||
          file.filename.toLowerCase().contains('vbaproject') ||
          file.generalPurposeBitFlag & 1 != 0 ||
          (file.externalFileAttributes >> 16) & 0xf000 == 0xa000)
        throw const FormatException();
    }
    final candidates = directory.fileHeaders
        .where((f) => f.filename == 'word/document.xml')
        .toList();
    if (candidates.length != 1) throw const FormatException();
    final source = candidates.single.file?.getStream().toUint8List();
    if (source == null || source.length > 8 * 1024 * 1024)
      throw const FormatException();
    final xml = utf8.decode(source);
    if (xml.contains(RegExp(r'<!DOCTYPE|<!ENTITY', caseSensitive: false)))
      throw const FormatException();
    final text = StringBuffer();
    final tokens = RegExp(
      r'<w:t\b[^>]*>([\s\S]*?)</w:t>|</w:p\s*>|<w:(?:tab|br)\b[^>]*/>',
    );
    for (final token in tokens.allMatches(xml)) {
      if (token.group(1) != null) {
        text.write(html.parseFragment(token.group(1)!).text);
      } else {
        text.write(token.group(0)!.contains('tab') ? '\t' : '\n');
      }
      if (text.length > AiAttachmentReader.maxTextCharacters)
        throw const AiProviderException('attachment_size', '附件正文过长，请拆分文件后重试');
    }
    return text.toString().trim();
  } on AiProviderException {
    rethrow;
  } catch (_) {
    throw const AiProviderException('attachment_read', 'DOCX 正文无法读取，请检查文件格式');
  }
}
