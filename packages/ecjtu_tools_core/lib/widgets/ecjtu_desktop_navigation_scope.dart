// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/widgets.dart';

class EcjtuDesktopNavigationScope extends InheritedWidget {
  const EcjtuDesktopNavigationScope({
    super.key,
    required this.secondaryVisible,
    required super.child,
  });
  final bool secondaryVisible;

  static bool secondaryOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EcjtuDesktopNavigationScope>()
          ?.secondaryVisible ??
      false;

  @override
  bool updateShouldNotify(EcjtuDesktopNavigationScope oldWidget) =>
      secondaryVisible != oldWidget.secondaryVisible;
}

class EcjtuDesktopViewportScope extends InheritedWidget {
  const EcjtuDesktopViewportScope({
    super.key,
    required this.secondaryVisible,
    this.workspaceWidth,
    required super.child,
  });

  final bool secondaryVisible;
  final double? workspaceWidth;

  static double widthOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EcjtuDesktopViewportScope>()
          ?.workspaceWidth ??
      MediaQuery.sizeOf(context).width;

  static bool secondaryOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<EcjtuDesktopViewportScope>()
          ?.secondaryVisible ??
      EcjtuDesktopNavigationScope.secondaryOf(context);

  @override
  bool updateShouldNotify(EcjtuDesktopViewportScope oldWidget) =>
      secondaryVisible != oldWidget.secondaryVisible ||
      workspaceWidth != oldWidget.workspaceWidth;
}

class EcjtuVisibleDirectoryScope extends InheritedWidget {
  const EcjtuVisibleDirectoryScope({
    super.key,
    required this.visible,
    required super.child,
  });
  final bool visible;
  static bool hidesReturn(BuildContext context, String label) =>
      (context
              .dependOnInheritedWidgetOfExactType<EcjtuVisibleDirectoryScope>()
              ?.visible ??
          false) &&
      const {
        '返回工作台',
        '返回智慧学工',
        '返回学工信息',
        '返回学工服务',
        '返回学工通知',
        '返回消息列表',
        '返回聊天',
        '返回教务',
        '返回教务工具',
        '返回增强插件',
        '返回物理实验',
        '返回通知与校历',
        '返回设置',
      }.contains(label);
  @override
  bool updateShouldNotify(EcjtuVisibleDirectoryScope oldWidget) =>
      visible != oldWidget.visible;
}
