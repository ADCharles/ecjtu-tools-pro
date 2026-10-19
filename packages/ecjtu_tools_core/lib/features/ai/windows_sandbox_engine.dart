// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'ai_models.dart';

class AiWindowsSandboxEngine {
  AiWindowsSandboxEngine({
    required this.directory,
    required this.stateDirectory,
  });

  final String directory;
  final String stateDirectory;
  static const version = 'rust-v0.162.1';
  static final bool namespaceIsolated = false;
  static const digests = {
    'codex.exe':
        'dd13bdb162a184fa04039488b234a8258ef9b76f84e926c505d5742b19249a6a',
    'codex-command-runner.exe':
        '4b1f3369cf4f9a1fd6ecebb8c7caef0d6a33a4a3af77650c277525d3b4e34c76',
    'codex-windows-sandbox-setup.exe':
        'b30ec190ac0b43c6e4a7c26fbc533f5321674b57fe85bb7306872641bc0bd40b',
    'codex-windows-sandbox-service.exe':
        '1feb1c264e9ad33ca78a0be4f3bba012f396c0c3de0564b856e05ef9c09567e7',
  };
  static final _verified = <String, ({int size, int modified})>{};
  static final _preparing = <String, Future<void>>{};

  factory AiWindowsSandboxEngine.bundled() => AiWindowsSandboxEngine(
    directory: p.join(p.dirname(Platform.resolvedExecutable), 'agent-engine'),
    stateDirectory: p.join(
      Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
      'DongCharles',
      'assistant-sandbox',
      version,
    ),
  );

  String get executable => p.join(directory, 'codex.exe');
  File get _marker => File(p.join(stateDirectory, 'provisioned.json'));

  Future<void> verify() async {
    for (final entry in digests.entries) {
      final file = File(p.join(directory, entry.key));
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const AiToolException(
          'sandbox_unavailable',
          '命令运行环境不完整，请修复应用安装。',
        );
      }
      final identity = (
        size: stat.size,
        modified: stat.modified.microsecondsSinceEpoch,
      );
      if (_verified[file.path] == identity) continue;
      if ((await sha256.bind(file.openRead()).first).toString() !=
          entry.value) {
        throw const AiToolException('sandbox_integrity', '命令运行环境校验失败，未执行命令。');
      }
      _verified[file.path] = identity;
    }
  }

  Future<bool> get provisioned async {
    try {
      final marker = jsonDecode(await _marker.readAsString());
      return marker is Map && marker['version'] == version;
    } on FileSystemException {
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<void> prepare({
    required String powershell,
    required Future<void> Function() confirm,
  }) async {
    if (!namespaceIsolated) {
      throw const AiToolException(
        'sandbox_setup_pending',
        '命令运行环境尚未完成初始化，未执行命令。',
      );
    }
    await verify();
    if (await provisioned) return;
    final existing = _preparing[stateDirectory];
    if (existing != null) return existing;
    final flight = _provision(powershell, confirm);
    _preparing[stateDirectory] = flight;
    try {
      await flight;
    } finally {
      _preparing.remove(stateDirectory);
    }
  }

  Future<void> _provision(
    String powershell,
    Future<void> Function() confirm,
  ) async {
    await confirm();
    await Directory(stateDirectory).create(recursive: true);
    final config = File(p.join(stateDirectory, 'config.toml'));
    if (!await config.exists()) {
      await config.writeAsString('[windows]\nsandbox = "elevated"\n');
    }
    String quote(String value) => "'${value.replaceAll("'", "''")}'";
    final domain = Platform.environment['USERDOMAIN'];
    final user = Platform.environment['USERNAME'];
    if (user == null || user.isEmpty) {
      throw const AiToolException(
        'sandbox_setup_failed',
        '无法确认当前系统账户，未初始化运行环境。',
      );
    }
    final identity = domain == null || domain.isEmpty ? user : '$domain\\$user';
    // ShellExecute's argument list is a command line; quote paths independently
    // of PowerShell literals so spaces never split the target user's state path.
    final arguments = [
      'sandbox',
      'setup',
      '--elevated',
      '--user',
      identity,
      '--codex-home',
      stateDirectory,
    ].map(windowsArgument).join(' ');
    final script =
        "\$ErrorActionPreference='Stop'; \$p=Start-Process -FilePath ${quote(executable)} -ArgumentList ${quote(arguments)} -Verb RunAs -WindowStyle Hidden -PassThru -Wait; exit \$p.ExitCode";
    final result = await Process.run(
      powershell,
      [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-OutputFormat',
        'Text',
        '-EncodedCommand',
        encodePowerShell(script),
      ],
      includeParentEnvironment: false,
      environment: environment(),
    );
    if (result.exitCode != 0) {
      await File(p.join(stateDirectory, 'setup-error.json')).writeAsString(
        jsonEncode({
          'exitCode': result.exitCode,
          'stderr': result.stderr.toString().substring(
            0,
            result.stderr.toString().length.clamp(0, 16000),
          ),
        }),
      );
      throw const AiToolException(
        'sandbox_setup_failed',
        '命令运行环境初始化未完成，未执行命令，可重新尝试。',
      );
    }
    await _marker.writeAsString(jsonEncode({'version': version}));
  }

  static String encodePowerShell(String command) => base64Encode([
    for (final unit in command.codeUnits) ...[unit & 255, unit >> 8],
  ]);

  static String windowsArgument(String value) =>
      '"${value.replaceAllMapped(RegExp(r'(\\*)"'), (m) => '${m[1]}${m[1]}\\"').replaceAllMapped(RegExp(r'(\\+)$'), (m) => '${m[1]}${m[1]}')}"';

  List<String> arguments({
    required String workspace,
    required String workingDirectory,
    required String powershell,
    required String encodedCommand,
  }) {
    final root = p.normalize(p.absolute(workspace));
    final cwd = p.normalize(p.absolute(workingDirectory));
    if (!p.equals(root, cwd) && !p.isWithin(root, cwd)) {
      throw const AiToolException('file_permission', '命令工作目录超出当前工作区，未执行。');
    }
    // CLI overrides outrank configuration files in the working directory.
    // The command is passed only after --, never parsed as launcher options.
    final profile =
        'permissions.app_agent={filesystem={":root"="read",${jsonEncode(root)}="write",${jsonEncode(p.join(p.normalize(p.absolute(stateDirectory)), '.sandbox-secrets'))}="none",${jsonEncode(p.join(p.normalize(p.absolute(stateDirectory)), '.sandbox'))}="none",${jsonEncode(p.normalize(p.absolute(directory)))}="read"},network={enabled=true}}';
    return [
      'sandbox',
      '-c',
      'windows.sandbox="elevated"',
      '-c',
      'features.prefer_mxc=false',
      '-c',
      profile,
      '-P',
      'app_agent',
      '-C',
      cwd,
      '--',
      powershell,
      '-NoLogo',
      '-NoProfile',
      '-NonInteractive',
      '-OutputFormat',
      'Text',
      '-EncodedCommand',
      encodedCommand,
    ];
  }

  Map<String, String> environment() => {
    for (final entry in Platform.environment.entries)
      if (!RegExp(
            r'key|token|secret|password',
            caseSensitive: false,
          ).hasMatch(entry.key) &&
          !entry.key.toUpperCase().startsWith('CODEX_'))
        entry.key: entry.value,
    'CODEX_HOME': stateDirectory,
  };

  Future<Map<String, String>> executionEnvironment(String workspace) async {
    final root = await Directory(workspace).resolveSymbolicLinks();
    var current = root;
    for (final name in ['.dc-agent-runtime', 'temp']) {
      current = p.join(current, name);
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw const AiToolException('file_permission', '命令临时目录不可用，未执行。');
      }
      final dir = await Directory(current).create();
      final actual = await dir.resolveSymbolicLinks();
      if (!p.equals(p.normalize(actual), p.normalize(current)) ||
          !p.isWithin(root, actual)) {
        throw const AiToolException('file_permission', '命令临时目录超出工作区，未执行。');
      }
    }
    // Child tools need writable scratch space without granting user TEMP writes.
    return {
      ...environment(),
      'TEMP': current,
      'TMP': current,
      'TMPDIR': current,
    };
  }
}
