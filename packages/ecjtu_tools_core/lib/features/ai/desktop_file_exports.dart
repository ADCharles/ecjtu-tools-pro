// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'ai_models.dart';
import 'chat_execution_mode.dart';

class AiDesktopFileExports {
  AiDesktopFileExports({required this.workspace, bool? desktop})
    : desktop =
          desktop ??
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  final Future<Directory> Function() workspace;
  final bool desktop;
  static const textExtensions = {'.txt', '.md', '.csv', '.json', '.html'};

  Future<String> saveText(String destination, String text) => saveBytes(
    destination,
    Uint8List.fromList(utf8.encode(text)),
    extensions: textExtensions,
  );

  Future<String> saveBytes(
    String destination,
    Uint8List bytes, {
    Set<String> extensions = const {'.pdf'},
  }) async {
    if (!desktop)
      throw const AiToolException('action_unavailable', '此设备请使用文件保存入口');
    if (bytes.isEmpty ||
        bytes.length > 32 * 1024 * 1024 ||
        destination.length > 1024) {
      throw const AiToolException('invalid_arguments', '文件为空或过大');
    }
    final target = destination.trim();
    if (!extensions.contains(p.extension(target).toLowerCase()) ||
        target.contains(RegExp(r'[\x00-\x1f]')) ||
        target.split(RegExp(r'[/\\]')).contains('..') ||
        (Platform.isWindows &&
            (target.startsWith('\\\\') || target.contains(':', 2)))) {
      throw const AiToolException('invalid_arguments', '请选择有效的导出文件路径');
    }
    final root = await workspace();
    await root.create(recursive: true);
    final path = p.isAbsolute(target)
        ? p.normalize(target)
        : p.join(root.path, target);
    final parent = Directory(p.dirname(path));
    if (!await parent.exists())
      throw const AiToolException('directory_missing', '保存目录不存在，请选择已有目录');
    final canonical = p.join(
      await parent.resolveSymbolicLinks(),
      p.basename(path),
    );
    final scope = AiAgentScope.current;
    if (scope != null &&
        (scope.mode != AiChatMode.agent ||
            (!scope.global &&
                !p.isWithin(await root.resolveSymbolicLinks(), canonical)))) {
      throw const AiToolException('file_permission', '此路径不在当前工作区内');
    }
    if (await FileSystemEntity.type(canonical, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const AiToolException('file_exists', '同名文件已存在，请使用其他文件名');
    }
    final temporary = await Directory(
      p.dirname(canonical),
    ).createTemp('.assistant-export-');
    final staged = File(p.join(temporary.path, 'content'));
    var committed = false;
    try {
      await staged.writeAsBytes(bytes, flush: true);
      // Copy without replacing any file created while the export was prepared.
      final output = File(canonical);
      await output.create(exclusive: true);
      committed = true;
      await output.writeAsBytes(bytes, flush: true);
      return canonical;
    } catch (_) {
      if (committed) await File(canonical).delete();
      rethrow;
    } finally {
      if (await staged.exists()) await staged.delete();
      await temporary.delete();
    }
  }
}
