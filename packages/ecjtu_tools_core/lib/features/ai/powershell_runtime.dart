// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'ai_models.dart';

typedef AiRuntimeProbe = Future<ProcessResult> Function(List<String> arguments);

class AiPowerShellInstallation {
  const AiPowerShellInstallation(this.executable, {this.package = ''});
  final String executable, package;
}

class AiPowerShellRuntimeLocator {
  AiPowerShellRuntimeLocator({
    required this.helper,
    Map<String, String>? environment,
    AiRuntimeProbe? probe,
  }) : environment = environment ?? Platform.environment,
       _probeOverride = probe;

  final String helper;
  final Map<String, String> environment;
  final AiRuntimeProbe? _probeOverride;
  AiPowerShellInstallation? _installed;
  Future<AiPowerShellInstallation?>? _finding;
  Future<String>? _preparing;
  String? _prepared;

  bool protects(String path) => [
    if (_installed != null) p.dirname(_installed!.executable),
    if (_prepared != null) p.dirname(_prepared!),
  ].any((root) => p.equals(root, path) || p.isWithin(root, path));

  void invalidate() {
    _installed = null;
    _prepared = null;
    _finding = null;
    _preparing = null;
  }

  Future<ProcessResult> _probe(List<String> arguments) async {
    if (_probeOverride case final probe?) return probe(arguments);
    if (!await File(helper).exists()) {
      throw const AiToolException(
        'sandbox_unavailable',
        '命令运行服务暂不可用，未执行命令；这不表示 PowerShell 未安装',
      );
    }
    final process = await Process.start(helper, arguments);
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();
    try {
      final code = await process.exitCode.timeout(const Duration(seconds: 5));
      return ProcessResult(process.pid, code, await out, await err);
    } on TimeoutException {
      process.kill();
      await Future.wait([out, err]);
      throw const AiToolException(
        'powershell_probe_timeout',
        'PowerShell 探测超时，尚不能判断安装状态；请重试探测，不要直接请求安装',
      );
    } on ProcessException {
      throw const AiToolException(
        'powershell_probe_failed',
        'PowerShell 探测未完成，尚不能判断安装状态',
      );
    }
  }

  Future<AiPowerShellInstallation?> find() async {
    if (_installed case final installed?) {
      if (await File(installed.executable).exists()) return installed;
      invalidate();
    }
    if (_finding case final operation?) return operation;
    final operation = _find();
    _finding = operation;
    try {
      return _installed = await operation;
    } finally {
      if (identical(_finding, operation)) _finding = null;
    }
  }

  Future<AiPowerShellInstallation?> _find() async {
    // App execution aliases are reparse points, not the signed PE image.
    final metadata = await _probe(['--discover-runtimes']);
    if (metadata.exitCode != 0) {
      throw const AiToolException(
        'powershell_probe_failed',
        'PowerShell 安装目录探测未完成，不能据此认定未安装',
      );
    }
    final List installed;
    try {
      installed = jsonDecode(metadata.stdout.toString()) as List;
    } catch (_) {
      throw const AiToolException(
        'powershell_probe_failed',
        'PowerShell 安装信息暂时无法读取',
      );
    }
    final candidates = <AiPowerShellInstallation>[
      AiPowerShellInstallation(
        p.join(
          environment['LOCALAPPDATA'] ?? '',
          'DongCharles',
          'assistant-runtime',
          'powershell7',
          'pwsh.exe',
        ),
      ),
      AiPowerShellInstallation(
        p.join(
          environment['ProgramFiles'] ?? r'C:\Program Files',
          'PowerShell',
          '7',
          'pwsh.exe',
        ),
      ),
      AiPowerShellInstallation(
        p.join(
          environment['LOCALAPPDATA'] ?? '',
          'Microsoft',
          'PowerShell',
          '7',
          'pwsh.exe',
        ),
      ),
      for (final item in installed.whereType<Map>())
        if (item['path'] is String)
          AiPowerShellInstallation(
            item['path'] as String,
            package: item['package'] as String? ?? '',
          ),
      for (final directory in (environment['PATH'] ?? '').split(';'))
        if (directory.trim().isNotEmpty)
          AiPowerShellInstallation(
            p.join(
              environmentExpand(directory.trim().replaceAll('"', '')),
              'pwsh.exe',
            ),
          ),
    ];
    final seen = <String>{};
    var rejected = false;
    for (final candidate in candidates) {
      final file = File(candidate.executable);
      if (!seen.add(p.normalize(file.absolute.path).toLowerCase()) ||
          !await file.exists())
        continue;
      if ((await file.stat()).size == 0) continue;
      final actual = await file.resolveSymbolicLinks();
      final result = await _probe(['--verify-runtime', actual]);
      if (result.exitCode == 0)
        return AiPowerShellInstallation(actual, package: candidate.package);
      rejected = true;
    }
    if (rejected) {
      throw const AiToolException(
        'powershell_runtime_untrusted',
        '已发现 PowerShell 程序，但运行文件校验未通过；未执行命令，不应当作未安装或权限拒绝',
      );
    }
    return null;
  }

  String environmentExpand(String value) => value.replaceAllMapped(
    RegExp(r'%([^%]+)%'),
    (match) =>
        environment.entries
            .where(
              (entry) => entry.key.toLowerCase() == match[1]!.toLowerCase(),
            )
            .firstOrNull
            ?.value ??
        match[0]!,
  );

  Future<String?> executable({bool prepare = false}) async {
    final installed = await find();
    if (installed == null) return null;
    if (!prepare || installed.package.isEmpty) return installed.executable;
    if (_prepared case final file?) {
      if (await File(file).exists()) return file;
      _prepared = null;
    }
    if (_preparing case final operation?) return operation;
    final operation = _copyStoreRuntime(installed);
    _preparing = operation;
    try {
      return _prepared = await operation;
    } finally {
      if (identical(_preparing, operation)) _preparing = null;
    }
  }

  Future<String> _copyStoreRuntime(AiPowerShellInstallation installed) async {
    // Store package ACLs are owned by Windows. Mirror locally rather than
    // changing those ACLs or launching the alias outside the sandbox.
    final source = p.dirname(installed.executable);
    final identity = sha256
        .convert(utf8.encode('${installed.package}|$source'))
        .toString();
    final parent = Directory(
      p.join(
        environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
        'DongCharles',
        'assistant-runtime',
        'powershell-store',
      ),
    );
    await parent.create(recursive: true);
    final destination = Directory(p.join(parent.path, identity));
    final lock = await File(
      p.join(parent.path, '$identity.lock'),
    ).open(mode: FileMode.append);
    await lock.lock(FileLock.blockingExclusive);
    try {
      return await _copyStoreRuntimeLocked(
        installed,
        source,
        parent,
        destination,
      );
    } finally {
      await lock.unlock();
      await lock.close();
    }
  }

  Future<String> _copyStoreRuntimeLocked(
    AiPowerShellInstallation installed,
    String source,
    Directory parent,
    Directory destination,
  ) async {
    final exe = p.join(destination.path, 'pwsh.exe');
    final manifest = File(p.join(destination.path, '.runtime-source.json'));
    if (await manifest.exists() && await File(exe).exists()) {
      final saved = jsonDecode(await manifest.readAsString()) as Map;
      if (saved['source'] == source &&
          saved['package'] == installed.package &&
          (await _probe(['--verify-runtime', exe])).exitCode == 0)
        return exe;
      throw const AiToolException(
        'powershell_runtime_invalid',
        'PowerShell 运行文件需要重新校验，未执行命令',
      );
    }
    final stage = await parent.createTemp('store-stage-');
    try {
      await for (final entity in Directory(
        source,
      ).list(recursive: true, followLinks: false)) {
        final target = p.join(
          stage.path,
          p.relative(entity.path, from: source),
        );
        if (entity is Directory) {
          await Directory(target).create(recursive: true);
        } else if (entity is File) {
          await Directory(p.dirname(target)).create(recursive: true);
          await entity.copy(target);
        } else {
          throw const AiToolException(
            'powershell_runtime_invalid',
            'PowerShell 运行目录包含无法验证的链接，未执行命令',
          );
        }
      }
      if ((await _probe([
            '--verify-runtime',
            p.join(stage.path, 'pwsh.exe'),
          ])).exitCode !=
          0) {
        throw const AiToolException(
          'powershell_runtime_invalid',
          'PowerShell 运行文件校验未通过，未执行命令',
        );
      }
      await File(p.join(stage.path, '.runtime-source.json')).writeAsString(
        jsonEncode({'source': source, 'package': installed.package}),
        flush: true,
      );
      if (await destination.exists()) {
        throw const AiToolException(
          'powershell_runtime_busy',
          'PowerShell 运行环境正在准备，请稍后重试',
        );
      }
      await stage.rename(destination.path);
      return exe;
    } finally {
      if (await stage.exists()) {
        final root = await parent.resolveSymbolicLinks();
        final target = await stage.resolveSymbolicLinks();
        if (p.isWithin(root, target) &&
            p.basename(target).startsWith('store-stage-')) {
          await Directory(target).delete(recursive: true);
        }
      }
    }
  }
}
