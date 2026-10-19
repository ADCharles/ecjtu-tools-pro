// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'chat_icons.dart';
import 'package:flutter/services.dart';

class _Command {
  const _Command(this.command, this.title, this.description, this.icon);
  final String command;
  final String title;
  final String description;
  final IconData icon;
}

const _commands = [
  _Command('/compact', '压缩上下文', '整理上下文，保留关键信息', Icons.compress),
  _Command('/new', '新建对话', '开始新的对话', Icons.edit_square),
  _Command('/model', '选择模型', '选择当前使用的模型', Icons.auto_awesome_outlined),
  _Command('/permissions', '操作确认', '更改操作确认方式', Icons.shield_outlined),
  _Command('/agent', '长期指令', '编辑长期指令', Icons.description_outlined),
  _Command('/help', '指令帮助', '查看可用指令', Icons.help_outline),
  _Command('/stop', '停止处理', '停止生成和工具处理', Icons.stop_circle_outlined),
];

class AiChatCommandOverlay extends StatefulWidget {
  const AiChatCommandOverlay({
    super.key,
    required this.input,
    required this.onExecute,
    required this.builder,
    this.canSend = true,
  });
  final TextEditingController input;
  final Future<void> Function() onExecute;
  final Widget Function(BuildContext, FocusNode) builder;
  final bool canSend;

  @override
  State<AiChatCommandOverlay> createState() => _AiChatCommandOverlayState();
}

class _AiChatCommandOverlayState extends State<AiChatCommandOverlay> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _anchor = GlobalKey();
  final _scroll = ScrollController();
  late final _focus = FocusNode(onKeyEvent: _key);
  List<_Command> _matches = [];
  List<GlobalKey> _rows = [];
  int _selected = 0;
  String? _dismissedText;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.input.addListener(_refresh);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(AiChatCommandOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      oldWidget.input.removeListener(_refresh);
      widget.input.addListener(_refresh);
      _refresh();
    }
  }

  void _focusChanged() {
    if (!_focus.hasFocus) {
      _portal.hide();
    } else {
      _refresh();
    }
  }

  void _refresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      final text = widget.input.text.trimLeft().toLowerCase();
      final composing = widget.input.value.composing;
      final matches =
          !(composing.isValid && !composing.isCollapsed) &&
              text.startsWith('/') &&
              !text.contains(RegExp(r'\s')) &&
              widget.input.text != _dismissedText
          ? _commands
                .where((command) => command.command.startsWith(text))
                .toList()
          : <_Command>[];
      if (_matches.isNotEmpty || matches.isNotEmpty) {
        setState(() {
          _matches = matches;
          _rows = List.generate(matches.length, (_) => GlobalKey());
          _selected = 0;
        });
      }
      if (matches.isNotEmpty && _focus.hasFocus) {
        _portal.show();
      } else {
        _portal.hide();
      }
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final composing = widget.input.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isShiftPressed) {
      final value = widget.input.value;
      final selection = value.selection;
      final start = selection.isValid ? selection.start : value.text.length;
      final end = selection.isValid ? selection.end : value.text.length;
      widget.input.value = TextEditingValue(
        text: value.text.replaceRange(start, end, '\n'),
        selection: TextSelection.collapsed(offset: start + 1),
      );
      return KeyEventResult.handled;
    }
    if (!_portal.isShowing || _matches.isEmpty) {
      final platform = Theme.of(context).platform;
      final desktop =
          platform != TargetPlatform.android && platform != TargetPlatform.iOS;
      if (desktop &&
          widget.canSend &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        widget.onExecute();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dismissedText = widget.input.text;
      _portal.hide();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_matches.isNotEmpty) {
        _choose(_matches[_selected]);
      }
      widget.onExecute();
      _portal.hide();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _choose(_matches[_selected]);
      return KeyEventResult.handled;
    }
    final direction = event.logicalKey == LogicalKeyboardKey.arrowDown
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowUp
        ? -1
        : 0;
    if (direction == 0) return KeyEventResult.ignored;
    setState(() => _selected = (_selected + direction) % _matches.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_portal.isShowing) return;
      final row = _rows[_selected].currentContext;
      if (row != null) {
        Scrollable.ensureVisible(
          row,
          alignment: .5,
          duration: const Duration(milliseconds: 80),
        );
      }
    });
    return KeyEventResult.handled;
  }

  void _choose(_Command command) {
    _dismissedText = command.command;
    _portal.hide();
    widget.input.value = TextEditingValue(
      text: command.command,
      selection: TextSelection.collapsed(offset: command.command.length),
    );
    _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.input.removeListener(_refresh);
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _menu(BuildContext context) {
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final media = MediaQuery.of(context);
    final above = box.localToGlobal(Offset.zero).dy - media.padding.top - 10;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: TextFieldTapRegion(
              child: TapRegion(
                groupId: this,
                onTapOutside: (_) {
                  _dismissedText = widget.input.text;
                  _portal.hide();
                },
                child: Material(
                  elevation: 0,
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    key: const ValueKey('ai-command-menu'),
                    width: math.min(box.size.width, 440),
                    constraints: BoxConstraints(
                      maxHeight: math.max(36, math.min(280, above)),
                    ),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Builder(
                      builder: (context) {
                        final content = SingleChildScrollView(
                          controller: _scroll,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < _matches.length;
                                index++
                              )
                                _row(context, index),
                            ],
                          ),
                        );
                        final platform = Theme.of(context).platform;
                        if (platform == TargetPlatform.android ||
                            platform == TargetPlatform.iOS) {
                          return ScrollConfiguration(
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: content,
                          );
                        }
                        return Scrollbar(controller: _scroll, child: content);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, int index) {
    final command = _matches[index];
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: index == _selected,
      button: true,
      label: '${command.title} ${command.command}，${command.description}',
      child: Material(
        key: _rows[index],
        color: index == _selected
            ? colors.primary.withValues(alpha: .09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          canRequestFocus: false,
          key: ValueKey('ai-command-${command.command.substring(1)}'),
          onTap: () => _choose(command),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                AiChatIcon(
                  command.icon,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  command.command,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'SourceHanSansCN',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    command.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SourceHanSansCN',
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: _menu,
    child: TapRegion(
      groupId: this,
      child: CompositedTransformTarget(
        key: _anchor,
        link: _link,
        child: widget.builder(context, _focus),
      ),
    ),
  );
}
