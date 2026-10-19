// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import '../../theme/ecjtu_theme.dart';

class AiChatTheme extends StatelessWidget {
  const AiChatTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: EcjtuColors.surfaceFor(context),
        ),
        tooltipTheme: theme.tooltipTheme.copyWith(
          constraints: const BoxConstraints(maxWidth: 300),
          waitDuration:
              theme.tooltipTheme.waitDuration ??
              const Duration(milliseconds: 500),
          textStyle: (theme.tooltipTheme.textStyle ?? const TextStyle())
              .copyWith(
                fontFamily: 'SourceHanSansCN',
                fontFamilyFallback: const ['NotoSansSC'],
              ),
        ),
        textTheme: theme.textTheme.apply(
          fontFamily: 'SourceHanSansCN',
          fontFamilyFallback: const ['NotoSansSC'],
        ),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: 'SourceHanSansCN',
          fontFamilyFallback: const ['NotoSansSC'],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFamily: 'SourceHanSansCN',
          fontFamilyFallback: ['NotoSansSC'],
        ),
        child: child,
      ),
    );
  }
}
