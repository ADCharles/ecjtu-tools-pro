// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

class AiChatSettingsOverlay extends StatelessWidget {
  const AiChatSettingsOverlay({super.key, required this.chat, this.settings});
  final Widget chat;
  final Widget? settings;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: settings != null, child: chat),
        if (settings != null)
          Positioned.fill(
            child: Material(
              key: const ValueKey('ai-settings-panel'),
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: settings,
            ),
          ),
      ],
    ),
  );
}
