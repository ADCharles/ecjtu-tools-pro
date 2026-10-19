// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'diary_models.dart';
import 'diary_storage.dart';

class DiaryPdf {
  static Future<Uint8List> export(
    DiaryStorage storage,
    String account,
    DiaryEntry entry,
  ) async {
    final font = await rootBundle.load(
      'packages/ecjtu_tools_core/assets/fonts/LXGWWenKai-Regular.ttf',
    );
    final assets = <String, Uint8List>{};
    for (final id in entry.assetIds) {
      assets[id] = await (await storage.assetFile(account, id)).readAsBytes();
    }
    final bytes = font.buffer.asUint8List(
      font.offsetInBytes,
      font.lengthInBytes,
    );
    return Isolate.run(() => build(entry, bytes, assets));
  }

  static Future<Uint8List> build(
    DiaryEntry entry,
    Uint8List fontBytes,
    Map<String, Uint8List> assets,
  ) async {
    final font = pw.Font.ttf(ByteData.sublistView(fontBytes));
    final renderer = _DiaryPdfRenderer(
      entry.renderScale,
      assets,
      entry.imageWidths,
    );
    final date = diaryDate(entry.date);
    final title = entry.displayTitle.isEmpty ? '无标题' : entry.displayTitle;
    final document = pw.Document(title: title, author: 'ADCharles Studio');
    final body = entry.markdown
        ? renderer.blocks(
            md.Document(
              extensionSet: md.ExtensionSet.gitHubFlavored,
            ).parseLines(entry.body.split('\n')),
          )
        : renderer.plain(entry.body);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 42, 46, 40),
        maxPages: 1000,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
          italic: font,
          boldItalic: font,
        ),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 18),
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFCCD8DF),
                  width: .6,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '今日笺',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _DiaryPdfRenderer.muted,
                  ),
                ),
                pw.Text(
                  '${date.year}年${date.month}月${date.day}日',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _DiaryPdfRenderer.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: _DiaryPdfRenderer.muted,
              ),
            ),
          ),
        ),
        build: (_) => [
          if (entry.title.trim().isNotEmpty &&
              (!entry.markdown ||
                  firstDiaryHeading(entry.body)?.title != entry.title.trim()))
            ...renderer.paragraph([md.Text(title)], renderer.style(23)),
          ...body,
        ],
      ),
    );
    return document.save();
  }
}

class _DiaryPdfRenderer {
  _DiaryPdfRenderer(this.scale, this.assets, this.imageWidths);
  final double scale;
  final Map<String, Uint8List> assets;
  final Map<String, double> imageWidths;
  static const ink = PdfColor.fromInt(0xFF243746);
  static const muted = PdfColor.fromInt(0xFF71828C);
  pw.TextStyle style(double size) =>
      pw.TextStyle(fontSize: size * scale, lineSpacing: 4 * scale, color: ink);
  final _images = <String, pw.MemoryImage>{};

  Iterable<pw.Widget> plain(String source) sync* {
    final pattern = RegExp(r'!\[([^\]]*)\]\((diary-asset:[a-f0-9]{64})\)');
    var offset = 0;
    for (final match in pattern.allMatches(source)) {
      if (match.start > offset) {
        yield* paragraph([
          md.Text(source.substring(offset, match.start)),
        ], style(12));
      }
      yield image(match[2]!, match[1] ?? '');
      offset = match.end;
    }
    if (offset < source.length)
      yield* paragraph([md.Text(source.substring(offset))], style(12));
  }

  Iterable<pw.Widget> blocks(List<md.Node> nodes, {int depth = 0}) sync* {
    for (final node in nodes) {
      if (node is md.Text) {
        yield* paragraph([node], style(12));
        continue;
      }
      final element = node as md.Element;
      final children = element.children ?? [];
      switch (element.tag) {
        case 'p':
          yield* paragraph(children, style(12));
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          final level = int.parse(element.tag.substring(1));
          yield pw.SizedBox(height: 8);
          yield* paragraph(
            children,
            style([23, 21, 19, 17, 15, 14][level - 1].toDouble()),
          );
        case 'ul':
        case 'ol':
          var number = int.tryParse(element.attributes['start'] ?? '') ?? 1;
          for (final item in children.whereType<md.Element>()) {
            if (item.tag != 'li') continue;
            final parts = item.children ?? [];
            final prefix = element.tag == 'ol' ? '${number++}. ' : '• ';
            final widgets = <pw.Widget>[];
            if (parts.isNotEmpty &&
                parts.first is md.Element &&
                (parts.first as md.Element).tag == 'p') {
              widgets.addAll(
                paragraph([
                  md.Text(prefix),
                  ...(parts.first as md.Element).children ?? [],
                ], style(12)),
              );
              widgets.addAll(blocks(parts.skip(1).toList(), depth: depth + 1));
            } else if (parts.any(
              (p) => p is md.Element && ['ul', 'ol'].contains(p.tag),
            )) {
              final split = parts.indexWhere(
                (p) => p is md.Element && ['ul', 'ol'].contains(p.tag),
              );
              widgets.addAll(
                paragraph([md.Text(prefix), ...parts.take(split)], style(12)),
              );
              widgets.addAll(
                blocks(parts.skip(split).toList(), depth: depth + 1),
              );
            } else {
              widgets.addAll(paragraph([md.Text(prefix), ...parts], style(12)));
            }
            for (final widget in widgets) {
              yield pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12),
                child: widget,
              );
            }
          }
        case 'blockquote':
          for (final widget in blocks(children, depth: depth + 1)) {
            yield pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: widget,
            );
          }
        case 'pre':
          for (final line in element.textContent.trimRight().split('\n')) {
            yield* paragraph([md.Text(line.isEmpty ? ' ' : line)], style(10));
          }
        case 'hr':
          yield pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Divider(
              color: const PdfColor.fromInt(0xFFCCD8DF),
              thickness: .6,
            ),
          );
        case 'table':
          yield table(element);
          yield pw.SizedBox(height: 14);
        default:
          yield* paragraph([element], style(12));
      }
    }
  }

  Iterable<pw.Widget> paragraph(List<md.Node> nodes, pw.TextStyle base) sync* {
    var spans = <pw.InlineSpan>[];
    final output = <pw.Widget>[];
    void flush() {
      if (spans.isEmpty) return;
      output.add(
        pw.RichText(
          text: pw.TextSpan(style: base, children: spans),
          overflow: pw.TextOverflow.span,
        ),
      );
      spans = [];
    }

    void visit(md.Node node, pw.TextStyle current) {
      if (node is md.Text) {
        spans.add(pw.TextSpan(text: node.text, style: current));
        return;
      }
      final element = node as md.Element;
      if (element.tag == 'img') {
        flush();
        output.add(
          image(
            element.attributes['src'] ?? '',
            element.attributes['alt'] ?? '',
          ),
        );
        return;
      }
      if (element.tag == 'br') {
        spans.add(const pw.TextSpan(text: '\n'));
        return;
      }
      if (element.tag == 'input') {
        spans.add(
          pw.TextSpan(
            text: element.attributes.containsKey('checked') ? '[x] ' : '[ ] ',
          ),
        );
        return;
      }
      if (element.tag == 'strong')
        current = current.copyWith(fontWeight: pw.FontWeight.bold);
      if (element.tag == 'em')
        current = current.copyWith(fontStyle: pw.FontStyle.italic);
      if (element.tag == 'del')
        current = current.copyWith(decoration: pw.TextDecoration.lineThrough);
      if (element.tag == 'a')
        current = current.copyWith(decoration: pw.TextDecoration.underline);
      for (final child in element.children ?? <md.Node>[]) {
        visit(child, current);
      }
    }

    for (final node in nodes) {
      visit(node, base);
    }
    flush();
    yield* output;
    if (output.isNotEmpty) yield pw.SizedBox(height: 10 * scale);
  }

  pw.Widget image(String source, String alt) {
    final id = RegExp(r'^diary-asset:([a-f0-9]{64})$').firstMatch(source)?[1];
    if (id == null) return pw.Text(alt, style: style(12));
    final bytes = assets[id];
    if (bytes == null) throw const FormatException('日记图片缺失');
    final provider = _images.putIfAbsent(id, () => pw.MemoryImage(bytes));
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.LayoutBuilder(
        builder: (context, constraints) => pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.SizedBox(
            width: constraints!.maxWidth * (imageWidths[id] ?? 1),
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxHeight: 370),
              child: pw.Image(provider, fit: pw.BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget table(md.Element element) {
    final rows = <md.Element>[];
    void collect(md.Element node) {
      if (node.tag == 'tr') {
        rows.add(node);
        return;
      }
      for (final child
          in node.children?.whereType<md.Element>() ?? <md.Element>[]) {
        collect(child);
      }
    }

    collect(element);
    return pw.Table(
      defaultColumnWidth: const pw.FlexColumnWidth(),
      border: pw.TableBorder.all(
        color: const PdfColor.fromInt(0xFFCCD8DF),
        width: .6,
      ),
      children: rows.map((row) {
        final cells = row.children?.whereType<md.Element>().toList() ?? [];
        final heading = cells.any((cell) => cell.tag == 'th');
        return pw.TableRow(
          repeat: heading,
          decoration: heading
              ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF4F6))
              : null,
          children: cells
              .map(
                (cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Text(
                    cell.textContent,
                    style: style(11),
                    textAlign: cell.attributes['align'] == 'right'
                        ? pw.TextAlign.right
                        : cell.attributes['align'] == 'center'
                        ? pw.TextAlign.center
                        : pw.TextAlign.left,
                  ),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }
}
