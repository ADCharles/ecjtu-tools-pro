// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';

const String kEcjtuEdition = String.fromEnvironment(
  'ECJTU_EDITION',
  defaultValue: 'dev',
);

class AppEdition {
  const AppEdition._();

  /// 是否为测试版构建。
  static const bool isTest = kEcjtuEdition == 'test';
  static const bool isDevelopment = kEcjtuEdition == 'dev';
  static const bool supportsUpdates = !isDevelopment;
  static const String channel = isDevelopment
      ? 'dev'
      : isTest
      ? 'test'
      : 'stable';
  static const bool supportsFullDeveloperMode = isDevelopment || isTest;
  static const int testRevision = int.fromEnvironment(
    'ECJTU_TEST_REVISION',
    defaultValue: 3,
  );

  /// 窗口标题与任务栏名称。
  static const String windowTitle = isTest
      ? 'ECJTU Tools Pro Test'
      : isDevelopment
      ? 'ECJTU Tools Pro Dev'
      : 'ECJTU Tools Pro';

  /// 系统界面中展示的应用名。
  ///
  /// Android 的最近任务卡走的是 [MaterialApp.title]，需要显示产品中文名；
  /// 其它平台继续沿用 [windowTitle]，Windows 任务栏标题保持不变。
  static String get systemTitle =>
      Platform.isAndroid ? displayName : windowTitle;

  /// 用户可见的产品名称。
  static const String displayName = isTest
      ? '华交小助手Pro·测试版'
      : isDevelopment
      ? '华交小助手Pro·开发版'
      : '华交小助手Pro';

  /// 标题栏品牌角标。
  static const String badge = isDevelopment
      ? 'Dev'
      : isTest
      ? 'TEST'
      : 'Pro';

  /// 「关于」弹窗中的版本行。
  static String versionLabel =
      '${const String.fromEnvironment('ECJTU_APP_VERSION', defaultValue: '4.1.0')}+${const String.fromEnvironment('ECJTU_BUILD_NUMBER', defaultValue: '7')}';
  static String get displayVersionLabel => isTest
      ? '${versionLabel.split('+').first} test v$testRevision'
      : versionLabel.split('+').first;
  static String get aboutVersionLine => '$displayName · $displayVersionLabel';
}
