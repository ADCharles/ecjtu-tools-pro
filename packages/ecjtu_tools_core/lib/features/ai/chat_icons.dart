// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import '../../widgets/ecjtu_icon.dart';

class AiChatIcon extends StatelessWidget {
  const AiChatIcon(this.icon, {super.key, this.size = 18, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  String? get asset => switch (icon) {
    Icons.menu || Icons.format_list_bulleted => 'menu',
    Icons.settings_outlined => 'settings',
    Icons.tune_rounded => 'sliders_horizontal',
    Icons.chat_bubble_outline_rounded => 'message_square_text',
    Icons.smart_toy_outlined => 'bot',
    Icons.send_outlined || Icons.arrow_upward_rounded => 'arrow_up',
    Icons.stop_rounded || Icons.stop_circle_outlined => 'square',
    Icons.add => 'plus',
    Icons.edit_square => 'message_square_plus',
    Icons.edit_outlined => 'square_pen',
    Icons.content_copy_outlined => 'copy',
    Icons.refresh => 'rotate_ccw',
    Icons.open_in_new => 'external_link',
    Icons.download_outlined => 'download_simple',
    Icons.vertical_split_outlined => 'panel_right_open',
    Icons.close => 'x',
    Icons.arrow_back => 'arrow_left',
    Icons.expand_more => 'chevron_down',
    Icons.expand_less => 'chevron_up',
    Icons.chevron_left => 'chevron_left',
    Icons.chevron_right => 'chevron_right',
    Icons.check => 'check',
    Icons.psychology_outlined => 'brain',
    Icons.terminal_outlined => 'wrench',
    Icons.terminal => 'terminal',
    Icons.folder_open_rounded || Icons.folder_open_outlined => 'folder_open',
    Icons.shield_outlined => 'shield_check',
    Icons.dns_outlined => 'server',
    Icons.broken_image_outlined => null,
    Icons.circle_outlined => 'circle',
    _ => null,
  };

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: asset == null
        ? Icon(icon, size: size, color: color)
        : EcjtuIcon(
            'ai_phosphor_$asset.svg',
            size: size,
            color:
                color ??
                IconTheme.of(context).color ??
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
  );
}
