// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';

/// 统一的物理实验模块次级操作按钮样式（对齐插件端
/// `.smart-work-module-status-action`：高 34、圆角 6、浅蓝面、
/// hover 时背景 #E4F1F8 / 边框 #6B9FBC）。
/// 所有 physics_*_widgets / *_chart / *_page 中的操作按钮一律使用此函数，
/// 不允许各模块再私有定义按钮样式。
/// 字体与 [EcjtuSubpageTitle] 的返回按钮保持同源：跟随主题字体动态解析。
ButtonStyle physicsSecondaryButtonStyle(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final size = MediaQuery.sizeOf(context);
  final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
  return ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => EcjtuColors.textFrom(
        context,
        (dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A)),
      ),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return EcjtuColors.surfaceFrom(
          context,
          (dark ? const Color(0xFF14263A) : const Color(0xFFE9F0F5)),
        );
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed)) {
        return EcjtuColors.hoverFrom(
          context,
          (dark ? const Color(0xFF1B334A) : const Color(0xFFE4F1F8)),
        );
      }
      return EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF14263A) : const Color(0xFFF2F8FC)),
      );
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(
          color: EcjtuColors.borderFrom(
            context,
            (dark ? const Color(0xFF34445F) : const Color(0xFFC3D4DF)),
          ),
        );
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed)) {
        return BorderSide(
          color: EcjtuColors.borderFrom(
            context,
            (dark ? const Color(0xFF315D7E) : const Color(0xFF6B9FBC)),
          ),
        );
      }
      return BorderSide(
        color: EcjtuColors.borderFrom(
          context,
          (dark ? const Color(0xFF426B83) : const Color(0xFFA9C9DC)),
        ),
      );
    }),
    minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    textStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: fontFamily,
        fontSize: EcjtuMetrics.fontSmallFor(size),
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    ),
  );
}

Widget physicsSaveButton(
  BuildContext context, {
  required bool saving,
  required bool enabled,
  required VoidCallback onPressed,
  String label = '保存数据',
  bool alignLeft = true,
}) {
  final button = OutlinedButton(
    onPressed: saving || !enabled ? null : onPressed,
    style: physicsSecondaryButtonStyle(context),
    child: Text(saving ? '正在保存' : label),
  );
  if (!alignLeft) return button;
  return Align(alignment: Alignment.centerLeft, child: button);
}
