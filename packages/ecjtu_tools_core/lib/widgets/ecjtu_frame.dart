// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';

class EcjtuWindowFrame extends StatelessWidget {
  const EcjtuWindowFrame({
    super.key,
    required this.child,
    this.edgeToEdge = false,
  });

  final Widget child;
  final bool edgeToEdge;

  @override
  Widget build(BuildContext context) {
    if (edgeToEdge) return SizedBox.expand(child: child);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = EcjtuMetrics.isCompact(size);
        final outerPadding = EcjtuMetrics.outerPaddingFor(size);
        final frameWidth = compact
            ? size.width
            : math.min(
                size.width - outerPadding * 2,
                EcjtuMetrics.maxFrameWidthFor(size),
              );
        final frameHeight = compact
            ? size.height
            : math.max(size.height - outerPadding * 2, 0.0);
        final radius = compact ? 0.0 : 8.0;

        return ColoredBox(
          color: compact
              ? (EcjtuColors.pageFor(context))
              : EcjtuColors.pageFor(context),
          child: Padding(
            padding: EdgeInsets.all(outerPadding),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EcjtuColors.pageFor(context),
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: const [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
