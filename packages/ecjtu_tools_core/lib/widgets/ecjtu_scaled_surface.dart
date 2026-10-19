// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

class EcjtuScaledSurface extends StatelessWidget {
  const EcjtuScaledSurface({
    super.key,
    required this.scale,
    required this.child,
  });

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentMediaQuery = MediaQuery.of(context);
        final configuredScale = scale.isFinite && scale > 0 ? scale : 1.0;
        final systemTextScale = parentMediaQuery.textScaler.scale(1.0);
        final mobile =
            Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS;
        final effectiveScale =
            configuredScale * (mobile ? 1.0 : systemTextScale);
        final physicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : parentMediaQuery.size.width;
        final physicalHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : parentMediaQuery.size.height;
        final logicalSize = Size(
          physicalWidth / effectiveScale,
          physicalHeight / effectiveScale,
        );
        final logicalMediaQuery = parentMediaQuery.copyWith(
          size: logicalSize,
          padding: _scaleInsets(parentMediaQuery.padding, effectiveScale),
          viewPadding: _scaleInsets(
            parentMediaQuery.viewPadding,
            effectiveScale,
          ),
          viewInsets: _scaleInsets(parentMediaQuery.viewInsets, effectiveScale),
          systemGestureInsets: _scaleInsets(
            parentMediaQuery.systemGestureInsets,
            effectiveScale,
          ),
          textScaler: mobile
              ? parentMediaQuery.textScaler
              : TextScaler.noScaling,
        );

        // Keep the same widget structure at 100% to preserve scroll state.
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: logicalSize.width,
            maxWidth: logicalSize.width,
            minHeight: logicalSize.height,
            maxHeight: logicalSize.height,
            child: Transform.scale(
              scale: effectiveScale,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: logicalMediaQuery,
                child: SizedBox(
                  width: logicalSize.width,
                  height: logicalSize.height,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _scaleInsets(EdgeInsets insets, double factor) {
    return EdgeInsets.fromLTRB(
      insets.left / factor,
      insets.top / factor,
      insets.right / factor,
      insets.bottom / factor,
    );
  }
}
