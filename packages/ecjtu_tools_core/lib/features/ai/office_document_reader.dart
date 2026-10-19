// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'provider_models.dart';

String readOfficeDocument(Uint8List bytes, String extension) {
  try {
    final zip = ZipDirectory()..read(InputMemoryStream(bytes));
    if (zip.fileHeaders.isEmpty || zip.fileHeaders.length > 2048)
      throw const FormatException();
    var total = 0;
    final names = <String>{};
    for (final header in zip.fileHeaders) {
      total += header.uncompressedSize;
      if (!names.add(header.filename) ||
          total > 32 * 1024 * 1024 ||
          header.uncompressedSize > 8 * 1024 * 1024 ||
          header.filename.contains('..') ||
          header.filename.startsWith('/') ||
          header.filename.contains('\\') ||
          header.filename.toLowerCase().contains('vbaproject') ||
          header.generalPurposeBitFlag & 1 != 0 ||
          (header.externalFileAttributes >> 16) & 0xf000 == 0xa000)
        throw const FormatException();
    }
    XmlDocument? xml(String name) {
      final file = zip.fileHeaders
          .where((header) => header.filename == name)
          .firstOrNull;
      if (file == null) return null;
      final data = file.file?.getStream().toUint8List();
      if (data == null) throw const FormatException();
      final source = utf8.decode(data);
      if (RegExp(r'<!DOCTYPE|<!ENTITY', caseSensitive: false).hasMatch(source))
        throw const FormatException();
      return XmlDocument.parse(source);
    }

    Iterable<XmlElement> elements(XmlNode node, String name) => node.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == name);
    final result = StringBuffer();
    void line(String text) {
      result.writeln(text);
      if (result.length > 200000)
        throw const AiProviderException('attachment_size', '附件正文过长，请拆分文件后重试');
    }

    if (extension == 'xlsx') {
      final strings = <String>[];
      final shared = xml('xl/sharedStrings.xml');
      if (shared != null)
        strings.addAll(
          elements(shared, 'si').map(
            (item) => elements(item, 't').map((text) => text.innerText).join(),
          ),
        );
      final workbook = xml('xl/workbook.xml');
      final relationships = xml('xl/_rels/workbook.xml.rels');
      if (workbook == null || relationships == null)
        throw const FormatException();
      final targets = {
        for (final relation in elements(relationships, 'Relationship'))
          if (relation.getAttribute('TargetMode') != 'External')
            relation.getAttribute('Id'): relation.getAttribute('Target'),
      };
      for (final sheet in elements(workbook, 'sheet')) {
        final relation = sheet.attributes
            .where((attr) => attr.name.local == 'id')
            .firstOrNull
            ?.value;
        final target = targets[relation];
        if (target == null || target.contains('..') || target.contains('://'))
          throw const FormatException();
        final path = target.startsWith('/')
            ? target.substring(1)
            : 'xl/$target';
        final document = xml(path);
        if (document == null) throw const FormatException();
        line('工作表：${sheet.getAttribute('name') ?? ''}');
        for (final row in elements(document, 'row')) {
          final cells = <String>[];
          for (final cell in row.childElements.where(
            (element) => element.name.local == 'c',
          )) {
            final type = cell.getAttribute('t');
            final value = elements(cell, 'v').firstOrNull?.innerText ?? '';
            final index = type == 's' ? int.tryParse(value) : null;
            final text = type == 'inlineStr'
                ? elements(cell, 't').map((element) => element.innerText).join()
                : type == 's'
                ? (index != null && index >= 0 && index < strings.length
                      ? strings[index]
                      : throw const FormatException())
                : type == 'b'
                ? (value == '1' ? 'true' : 'false')
                : value;
            final formula = elements(cell, 'f').firstOrNull?.innerText;
            cells.add(
              '${cell.getAttribute('r') ?? ''}=$text${formula == null ? '' : ' [公式：$formula]'}',
            );
          }
          line(cells.join('\t'));
        }
      }
    } else if (extension == 'pptx') {
      final presentation = xml('ppt/presentation.xml');
      final relationships = xml('ppt/_rels/presentation.xml.rels');
      if (presentation == null || relationships == null)
        throw const FormatException();
      final targets = {
        for (final relation in elements(relationships, 'Relationship'))
          if (relation.getAttribute('TargetMode') != 'External')
            relation.getAttribute('Id'): relation.getAttribute('Target'),
      };
      var number = 0;
      for (final slide in elements(presentation, 'sldId')) {
        final id = slide.attributes
            .where(
              (attribute) =>
                  attribute.name.local == 'id' && attribute.name.prefix != null,
            )
            .firstOrNull
            ?.value;
        final target = targets[id];
        if (target == null || target.contains('..') || target.contains('://'))
          throw const FormatException();
        final page = xml(
          target.startsWith('/') ? target.substring(1) : 'ppt/$target',
        );
        if (page == null) throw const FormatException();
        line('第${++number}页');
        for (final paragraph in elements(page, 'p')) {
          line(elements(paragraph, 't').map((text) => text.innerText).join());
        }
      }
    } else {
      throw const FormatException();
    }
    return result.toString().trim();
  } on AiProviderException {
    rethrow;
  } catch (_) {
    throw const AiProviderException(
      'attachment_read',
      'Office 文件无法读取，请检查格式或加密状态',
    );
  }
}
