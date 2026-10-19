// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../widgets/ecjtu_text_context_menu.dart';

class AiChatMarkdownBody extends StatefulWidget {
  const AiChatMarkdownBody({
    super.key,
    required this.data,
    this.styleSheet,
    this.onTapLink,
    this.imageBuilder,
    this.selectable = true,
    this.renderInterval = const Duration(milliseconds: 32),
    this.streaming = true,
    this.onSelectionChanged,
  });

  final String data;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onTapLink;
  final MarkdownImageBuilder? imageBuilder;
  final bool selectable;
  final Duration renderInterval;
  final bool streaming;
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  @override
  State<AiChatMarkdownBody> createState() => _AiChatMarkdownBodyState();
}

class _AiChatMarkdownBodyState extends State<AiChatMarkdownBody> {
  late String _displayedData = widget.data;
  Timer? _renderTimer;

  void _armRenderBudget() {
    _renderTimer = Timer(widget.renderInterval, () {
      _renderTimer = null;
      if (!mounted || _displayedData == widget.data) return;
      setState(() => _displayedData = widget.data);
      _armRenderBudget();
    });
  }

  @override
  void didUpdateWidget(AiChatMarkdownBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data == _displayedData) return;
    if (!widget.streaming ||
        widget.data.length <= 4096 ||
        widget.renderInterval <= Duration.zero) {
      _renderTimer?.cancel();
      _renderTimer = null;
      _displayedData = widget.data;
    } else if (_renderTimer == null) {
      _displayedData = widget.data;
      _armRenderBudget();
    }
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = MarkdownBody(
      data: _displayedData,
      fitContent: false,
      selectable: false,
      styleSheet: widget.styleSheet,
      onTapLink: widget.onTapLink,
      imageBuilder: widget.imageBuilder,
    );
    // Large messages share one native selection region instead of creating an
    // EditableText, focus node and selection overlay for every Markdown cell.
    return widget.selectable
        ? SelectionArea(
            contextMenuBuilder: buildEcjtuSelectionContextMenu,
            onSelectionChanged: widget.onSelectionChanged,
            child: body,
          )
        : body;
  }
}
