// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class AiChatConversationDrawer extends StatelessWidget {
  const AiChatConversationDrawer({
    super.key,
    required this.chat,
    required this.open,
    required this.onClose,
    required this.drawer,
  });
  final Widget chat, drawer;
  final bool open;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Stack(
      fit: StackFit.expand,
      children: [
        chat,
        if (open) ...[
          Positioned.fill(
            child: Semantics(
              button: true,
              label: '关闭对话记录',
              child: GestureDetector(
                key: const ValueKey('ai-conversation-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.scrim.withValues(alpha: .25),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: math.min(288, math.max(0, bounds.maxWidth - 36)),
            child: LayoutBuilder(
              builder: (context, bounds) => MediaQuery(
                data: MediaQuery.of(context).copyWith(size: bounds.biggest),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -12, end: 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) => Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  ),
                  child: Material(
                    key: const ValueKey('ai-conversation-drawer'),
                    color: Theme.of(context).colorScheme.surface,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: drawer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
