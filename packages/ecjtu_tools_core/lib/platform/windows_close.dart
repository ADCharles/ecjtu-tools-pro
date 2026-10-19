// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/ecjtu_glass.dart';
import '../data/serialized_secure_storage.dart';
import '../widgets/ecjtu_dialog.dart';

class WindowsClose {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const channel = MethodChannel('ecjtu/windows_close');
  static final nativeBrowserAttached = ValueNotifier<bool>(false);
  static final navigationBackdrop = ValueNotifier<bool>(false);
  static final titleGradientExtent = ValueNotifier<double>(1);
  static final titleBarGradient = ValueNotifier<bool>(true);
  static final startupCoverVisible = ValueNotifier<bool>(true);
  static final startupCoverOpacity = ValueNotifier<double>(1);
  static bool _busy = false;
  static Future<void> Function()? beforeExit;
  static Future<bool> prepareExit() async {
    try {
      await beforeExit?.call().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      await SerializedSecureStorage.flush().timeout(const Duration(seconds: 1));
    } catch (_) {}
    return true;
  }

  static void initialize() {
    if (!Platform.isWindows) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'prepareExit') return prepareExit();
      if (call.method == 'requestClose') {
        await channel.invokeMethod<void>('cancelClose');
        await choose();
      }
      if (call.method == 'browserAttached') {
        nativeBrowserAttached.value = call.arguments == true;
      }
      if (call.method == 'navigationBackdrop') {
        navigationBackdrop.value = call.arguments == true;
      }
    });
  }

  /// The window controls the docked browser pane renders act on the window
  /// the user sees. They go through the same close/minimize path as the main
  /// scene's own buttons so both routes behave identically.
  static Future<void> requestMinimize() async {
    if (!Platform.isWindows) return;
    try {
      await channel.invokeMethod<void>('minimizeWindow');
    } catch (_) {}
  }

  static Future<void> requestToggleMaximize() async {
    if (!Platform.isWindows) return;
    try {
      await channel.invokeMethod<void>('toggleMaximizeWindow');
    } catch (_) {}
  }

  static Future<void> requestClose() async {
    if (!Platform.isWindows) return;
    try {
      await channel.invokeMethod<void>('requestCloseWindow');
    } catch (_) {}
  }

  static bool? _appliedWindowTheme;
  static int? _appliedBackdrop;

  static Future<void> setWindowTheme(bool dark) async {
    if (!Platform.isWindows) return;
    final colors = EcjtuGlass.forBrightness(
      dark ? Brightness.dark : Brightness.light,
      EcjtuGlass.platformStyle,
    );
    final backdrop = colors.backdrop.first.toARGB32();
    if (_appliedWindowTheme == dark && _appliedBackdrop == backdrop) return;
    _appliedWindowTheme = dark;
    _appliedBackdrop = backdrop;
    try {
      navigationBackdrop.value =
          await channel.invokeMethod<bool>('setTheme', {
            'dark': dark,
            ...colors.nativeChromeColors,
          }) ??
          false;
    } catch (_) {
      if (_appliedWindowTheme == dark) _appliedWindowTheme = null;
    }
  }

  static Future<void> choose({bool settings = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 1),
      );
      final saved = prefs.getString('ecjtu.windows.close_action');
      String? choice = settings ? null : saved;
      if (choice == null) {
        final context = navigatorKey.currentContext;
        if (context == null || !context.mounted) {
          return;
        }
        var remember = settings || saved != null;
        var configured = saved == 'exit' ? 'exit' : 'hide';
        choice = await showDialog<String>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => EcjtuDialog(
              title: Text(settings ? '关闭窗口设置' : '关闭窗口'),
              maxWidth: 460,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings) ...[
                    const Text('关闭窗口后', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: configured,
                      onChanged: (value) {
                        if (value != null) setState(() => configured = value);
                      },
                      child: const Column(
                        children: [
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: 'hide',
                            title: Text('最小化到托盘'),
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: 'exit',
                            title: Text('退出应用'),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    const Text('选择此次关闭窗口的操作', style: TextStyle(fontSize: 16)),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      '以后使用此操作',
                      style: TextStyle(fontSize: 16),
                    ),
                    value: remember,
                    onChanged: (value) =>
                        setState(() => remember = value ?? false),
                  ),
                ],
              ),
              actions: [
                EcjtuDialogAction(
                  onPressed: () => Navigator.pop(context),
                  label: '取消',
                ),
                if (settings)
                  EcjtuDialogAction(
                    onPressed: () => Navigator.pop(context, configured),
                    label: '保存',
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'hide'),
                    child: const Text('最小化到托盘'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'exit'),
                    child: const Text('退出应用'),
                  ),
                ],
              ],
            ),
          ),
        );
        if (choice == null) return;
        if (remember) {
          await prefs.setString('ecjtu.windows.close_action', choice);
        } else {
          await prefs.remove('ecjtu.windows.close_action');
        }
      }
      if (!settings && (choice == 'hide' || choice == 'exit')) {
        await channel.invokeMethod<void>(choice);
      }
    } catch (_) {
      // A failed dialog must leave the user's window open.
    } finally {
      _busy = false;
    }
  }
}
