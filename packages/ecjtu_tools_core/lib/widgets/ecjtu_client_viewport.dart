// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

class EcjtuClientViewport extends StatelessWidget {
  const EcjtuClientViewport({
    super.key,
    required this.size,
    required this.child,
  });

  final Size? size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewport = size ?? MediaQuery.sizeOf(context);
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: viewport.width,
          maxWidth: viewport.width,
          minHeight: viewport.height,
          maxHeight: viewport.height,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: viewport),
            child: child,
          ),
        ),
      ),
    );
  }
}
