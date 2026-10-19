// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import 'diary_math.dart';

TextSelection? diarySourceLocation(
  String source,
  String rendered, {
  int occurrence = 0,
  int? renderedOffset,
}) {
  String normalize(String value) => value
      .replaceAll(RegExp('[\uFFFC\u25A0]'), '')
      .replaceAll(RegExp(r'\s+'), '');
  final needle = normalize(rendered);
  if (needle.isEmpty) return null;
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    inlineSyntaxes: [DiaryMathInlineSyntax()],
    blockSyntaxes: const [DiaryMathBlockSyntax()],
  );
  String visible(md.Node node) {
    if (node is md.Element) {
      if (node.tag.startsWith('diary-math')) return '';
      return (node.children ?? const <md.Node>[]).map(visible).join();
    }
    return node.textContent;
  }

  final blocks = RegExp(r'\S[\s\S]*?(?=\r?\n\s*\r?\n|$)');
  TextSelection? fallback;
  for (final block in blocks.allMatches(source)) {
    final nodes = document.parseLines(block[0]!.split('\n'));
    final text = normalize(nodes.map(visible).join());
    if (!text.contains(needle)) continue;
    final selection = TextSelection(
      baseOffset: block.start,
      extentOffset: block.end,
    );
    fallback = selection;
    if (occurrence-- > 0) continue;
    if (renderedOffset == null) return selection;
    final raw = block[0]!;
    final offsets = <int>[];
    final visibleText = StringBuffer();
    var cursor = 0;
    void mapNode(md.Node node) {
      if (node is md.Element) {
        if (node.tag.startsWith('diary-math')) return;
        for (final child in node.children ?? const <md.Node>[]) {
          mapNode(child);
        }
        return;
      }
      final value = node.textContent;
      final start = raw.indexOf(value, cursor);
      if (start < 0) return;
      for (var i = 0; i < value.length; i++) {
        if (RegExp(r'\s').hasMatch(value[i])) continue;
        visibleText.write(value[i]);
        offsets.add(block.start + start + i);
      }
      cursor = start + value.length;
    }

    for (final node in nodes) {
      mapNode(node);
    }
    final visibleStart = visibleText.toString().indexOf(needle);
    if (visibleStart < 0 || offsets.isEmpty) return selection;
    final prefix = normalize(
      rendered.substring(0, renderedOffset.clamp(0, rendered.length)),
    );
    var start =
        offsets[(visibleStart + prefix.length).clamp(0, offsets.length - 1)];
    if (start > 0 &&
        source.codeUnitAt(start) >= 0xDC00 &&
        source.codeUnitAt(start) <= 0xDFFF)
      start--;
    final length =
        source.codeUnitAt(start) >= 0xD800 && source.codeUnitAt(start) <= 0xDBFF
        ? 2
        : 1;
    return TextSelection(baseOffset: start, extentOffset: start + length);
  }
  return fallback;
}
