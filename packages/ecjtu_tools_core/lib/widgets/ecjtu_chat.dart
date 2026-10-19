// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';

import '../features/workbench/message_scroll_boundary.dart';
import '../theme/ecjtu_theme.dart';
import 'ecjtu_page.dart';
import 'ecjtu_text_context_menu.dart';

class EcjtuChatSurface extends StatelessWidget {
  const EcjtuChatSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final mobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return mobile ? child : EcjtuCard(padding: padding, child: child);
  }
}

class EcjtuChatHeader extends StatelessWidget {
  const EcjtuChatHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });
  final Widget title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = EcjtuMetrics.phoneLayout(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: mobile
            ? Color.alphaBlend(
                colors.primary.withValues(alpha: dark ? .16 : .06),
                dark ? const Color(0xFF252525) : Colors.white,
              )
            : Color.alphaBlend(
                colors.primary.withValues(alpha: dark ? .15 : .07),
                colors.surface,
              ),
        border: Border.all(color: colors.primary.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.primary),
              child: title,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class EcjtuChatTimeline extends StatelessWidget {
  const EcjtuChatTimeline({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.listKey,
    this.plain = false,
    this.reverse = true,
    this.padding = const EdgeInsets.all(10),
    this.findChildIndexCallback,
  });
  final ScrollController controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Key? listKey;
  final bool plain;
  final bool reverse;
  final EdgeInsetsGeometry padding;
  final ChildIndexGetter? findChildIndexCallback;

  @override
  Widget build(BuildContext context) {
    final timeline = MessageScrollBoundary(
      controller: controller,
      child: Builder(
        builder: (context) {
          final content = ListView.builder(
            key: listKey,
            controller: controller,
            reverse: reverse,
            primary: false,
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            findChildIndexCallback: findChildIndexCallback,
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
          return Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: content,
          );
        },
      ),
    );
    return plain
        ? timeline
        : DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF191919)
                  : const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: timeline,
          );
  }
}

class EcjtuChatBubble extends StatelessWidget {
  const EcjtuChatBubble({
    super.key,
    required this.child,
    this.mine = false,
    this.avatar,
    this.footer,
  });
  final Widget child;
  final bool mine;
  final Widget? avatar;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = EcjtuMetrics.phoneLayout(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (avatar != null) ...[avatar!, const SizedBox(width: 8)],
        Flexible(
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mobile
                      ? (mine
                            ? Color.alphaBlend(
                                colors.primary.withValues(
                                  alpha: dark ? .22 : .12,
                                ),
                                dark ? const Color(0xFF252525) : Colors.white,
                              )
                            : dark
                            ? const Color(0xFF2C2C2C)
                            : Colors.white)
                      : mine
                      ? Color.alphaBlend(
                          colors.primary.withValues(alpha: dark ? .24 : .12),
                          colors.surface,
                        )
                      : colors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: mobile
                        ? colors.onSurface.withValues(alpha: dark ? .16 : .12)
                        : colors.outlineVariant,
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  child: SelectionArea(
                    contextMenuBuilder: buildEcjtuPlatformSelectionContextMenu,
                    child: child,
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ],
    );
  }
}

class EcjtuChatComposer extends StatelessWidget {
  const EcjtuChatComposer({
    super.key,
    required this.controller,
    required this.sendAction,
    this.onSubmit,
    this.fieldKey,
    this.hintText = '输入消息',
    this.maxLines = 3,
    this.accessory,
    this.leadingActions = const [],
    this.inputDecoration,
    this.footer,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.contentInsertionConfiguration,
    this.contextMenuBuilder,
    this.followCaret = false,
  });
  final TextEditingController controller;
  final Widget sendAction;
  final VoidCallback? onSubmit;
  final Key? fieldKey;
  final String hintText;
  final int maxLines;
  final Widget? accessory;
  final List<Widget> leadingActions;
  final InputDecoration? inputDecoration;
  final Widget? footer;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ContentInsertionConfiguration? contentInsertionConfiguration;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final bool followCaret;

  @override
  Widget build(BuildContext context) => _ComposerCaretFollower(
    controller: controller,
    enabled: followCaret,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
              onSubmit?.call();
            },
          },
          child: TextField(
            key: fieldKey,
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            contentInsertionConfiguration: contentInsertionConfiguration,
            contextMenuBuilder:
                contextMenuBuilder ?? buildEcjtuPlatformTextContextMenu,
            style: const TextStyle(fontSize: 16, height: 1.5),
            minLines: 1,
            maxLines: maxLines,
            decoration: inputDecoration ?? InputDecoration(hintText: hintText),
          ),
        ),
        ?accessory,
        if (footer != null)
          footer!
        else ...[
          const SizedBox(height: 10),
          Row(children: [...leadingActions, const Spacer(), sendAction]),
        ],
      ],
    ),
  );
}

class _ComposerCaretFollower extends StatefulWidget {
  const _ComposerCaretFollower({
    required this.controller,
    required this.enabled,
    required this.child,
  });
  final TextEditingController controller;
  final bool enabled;
  final Widget child;
  @override
  State<_ComposerCaretFollower> createState() => _ComposerCaretFollowerState();
}

class _ComposerCaretFollowerState extends State<_ComposerCaretFollower> {
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(_ComposerCaretFollower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  void _changed() {
    if (!widget.enabled || _scheduled) return;
    final composing = widget.controller.value.composing;
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        composing.isValid &&
        !composing.isCollapsed)
      return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !widget.enabled || !widget.controller.selection.isValid)
        return;
      EditableTextState? editor;
      void visit(Element element) {
        if (element is StatefulElement &&
            element.state is EditableTextState &&
            identical(
              (element.widget as EditableText).controller,
              widget.controller,
            )) {
          editor = element.state as EditableTextState;
        } else if (editor == null) {
          element.visitChildren(visit);
        }
      }

      context.visitChildElements(visit);
      if (editor?.widget.focusNode.hasFocus == true) {
        editor!.bringIntoView(widget.controller.selection.extent);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
