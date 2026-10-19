// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter_math_fork/flutter_math.dart';

class DiarySelectableFormula extends StatefulWidget {
  const DiarySelectableFormula({
    super.key,
    required this.expression,
    required this.style,
    required this.block,
  });
  final String expression;
  final TextStyle style;
  final bool block;

  @override
  State<DiarySelectableFormula> createState() => _DiarySelectableFormulaState();
}

class _FormulaSelectionDelegate extends StaticSelectionContainerDelegate {
  String source = '';
  @override
  SelectedContent? getSelectedContent() => super.getSelectedContent() == null
      ? null
      : SelectedContent(plainText: source);
}

class _DiarySelectableFormulaState extends State<DiarySelectableFormula> {
  final _selection = _FormulaSelectionDelegate();
  late Widget _formula;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(DiarySelectableFormula oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression ||
        oldWidget.style != widget.style ||
        oldWidget.block != widget.block) {
      _prepare();
    }
  }

  void _prepare() {
    final delimiter = widget.block ? r'$$' : r'$';
    _selection.source = '$delimiter${widget.expression}$delimiter';
    _formula = Math.tex(
      widget.expression,
      mathStyle: widget.block ? MathStyle.display : MathStyle.text,
      textStyle: widget.style,
      onErrorFallback: (_) => Text(widget.expression, style: widget.style),
    );
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MetaData(
    metaData: (diaryFormula: widget.expression),
    child: SelectionContainer(
      delegate: _selection,
      child: Stack(
        children: [
          SelectionContainer.disabled(child: _formula),
          // One selection unit covers the equation's actual bounds. The delegate
          // supplies TeX instead of fragmenting selection across rendered glyphs.
          Positioned.fill(
            child: ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  '\u25A0',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
