// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'diary_selectable_formula.dart';
import 'package:markdown/markdown.dart' as md;

class DiaryMathInlineSyntax extends md.InlineSyntax {
  DiaryMathInlineSyntax()
    : super(
        r'\$\$([\s\S]+?)\$\$|\$(?!\s|\$)((?:\\.|[^$\n])+?)(?<!\s)\$(?!\d)|\\\((.+?)\\\)|\\\[([\s\S]+?)\\\]',
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final block = match[1] != null || match[4] != null;
    parser.addNode(
      md.Element.text(
        block ? 'diary-math-block' : 'diary-math',
        match[1] ?? match[2] ?? match[3] ?? match[4]!,
      ),
    );
    return true;
  }
}

class DiaryMathBlockSyntax extends md.BlockSyntax {
  const DiaryMathBlockSyntax();
  @override
  RegExp get pattern => RegExp(r'^ {0,3}(\$\$|\\\[)');

  @override
  bool canParse(md.BlockParser parser) {
    if (!super.canParse(parser)) return false;
    final opener = pattern.firstMatch(parser.current.content)!;
    final close = opener[1] == r'$$' ? r'$$' : r'\]';
    if (parser.current.content.substring(opener.end).contains(close))
      return true;
    for (var offset = 1; ; offset++) {
      final line = parser.peek(offset);
      if (line == null) return false;
      if (line.content.trimRight().endsWith(close)) return true;
    }
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final close = match[1] == r'$$' ? r'$$' : r'\]';
    var line = parser.current.content.substring(match.end);
    final lines = <String>[];
    while (true) {
      final end = line.indexOf(close);
      if (end >= 0) {
        lines.add(line.substring(0, end));
        parser.advance();
        break;
      }
      lines.add(line);
      parser.advance();
      if (parser.isDone) break;
      line = parser.current.content;
    }
    return md.Element.text('diary-math-block', lines.join('\n').trim());
  }
}

class DiaryMathBuilder extends MarkdownElementBuilder {
  DiaryMathBuilder(this.style, {this.block = false});
  final TextStyle style;
  final bool block;
  @override
  bool isBlockElement() => block;
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final formula = DiarySelectableFormula(
      expression: element.textContent,
      block: block,
      style: style,
    );
    return block
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: formula,
            ),
          )
        : Text.rich(
            TextSpan(
              style: parentStyle ?? style,
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: formula,
                ),
              ],
            ),
          );
  }
}
