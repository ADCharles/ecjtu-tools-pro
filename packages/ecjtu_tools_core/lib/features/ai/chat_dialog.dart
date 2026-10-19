// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class AiChatDialogViewport extends StatelessWidget {
  const AiChatDialogViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      final available =
          math.min(media.size.height, constraints.maxHeight) -
          media.viewInsets.vertical;
      // The shared dialog sizes its scroll body as a viewport fraction; reserve
      // room for its title and actions when the keyboard or landscape is short.
      final bodyHeight = math.max(
        12.0,
        math.min(available, 660) - 250 * media.textScaler.scale(1),
      );
      return MediaQuery(
        data: media.copyWith(size: Size(media.size.width, bodyHeight / .72)),
        child: child,
      );
    },
  );
}
