// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'ai_models.dart';
import 'windows_process_job.dart';
import 'file_observation.dart';
import 'file_change.dart';
import 'desktop_agent_runtime_paths.dart';
import 'desktop_runtime_cache.dart';
import 'desktop_readonly_shell.dart';
import 'windows_sandbox_engine.dart';

class AiDesktopProcess {
  AiDesktopProcess._({
    required this.id,
    required this.owner,
    required this.process,
    required this.job,
    required this.executable,
    required this.command,
    required this.directory,
    required this.workspace,
  });
  final String id, owner, executable, command, directory;
  final String? workspace;
  final Process process;
  final WindowsProcessJob job;
  final elapsed = Stopwatch()..start();
  final done = Completer<void>();
  String _out = '', _err = '';
  int _outLength = 0, _errLength = 0, _outCursor = 0, _errCursor = 0;
  int? exitCode;
  bool timedOut = false, stopped = false;
  Timer? _deadline, _cancellation;
  List<AiFileChange> _fileChanges = [];
  bool _changesDelivered = false;
  bool get running => !done.isCompleted;

  static Future<AiDesktopProcess> start({
    required String id,
    required String owner,
    required String executable,
    required String command,
    required String encodedCommand,
    required String directory,
    required Duration timeout,
    bool Function()? cancelled,
    String? sandboxWorkspace,
    String? sandboxExecutable,
    AiWindowsSandboxEngine? sandboxEngine,
  }) async {
    final helper =
        sandboxExecutable ??
        p.join(p.dirname(Platform.resolvedExecutable), 'assistant_sandbox.exe');
    if ((sandboxWorkspace == null || sandboxEngine == null) &&
        !await File(helper).exists()) {
      throw const AiToolException(
        'sandbox_unavailable',
        '命令隔离服务暂不可用，未执行命令；可继续使用工作区文件工具。',
      );
    }
    final commandRoot = sandboxWorkspace ?? directory;
    final observation = await AiFileObservation.capture(commandRoot);
    final Process process;
    if (sandboxWorkspace != null && sandboxEngine != null) {
      await sandboxEngine.verify();
      if (!await sandboxEngine.provisioned) {
        throw const AiToolException(
          'sandbox_setup_required',
          '请先初始化命令运行环境，未执行命令。',
        );
      }
      if (cancelled?.call() == true) {
        throw const AiToolException('cancelled', '命令已取消');
      }
      process = await Process.start(
        sandboxEngine.executable,
        sandboxEngine.arguments(
          workspace: sandboxWorkspace,
          workingDirectory: directory,
          powershell: executable,
          encodedCommand: AiWindowsSandboxEngine.encodePowerShell(
            "\$ErrorActionPreference='Stop';\n$command",
          ),
        ),
        workingDirectory: directory,
        includeParentEnvironment: false,
        environment: await sandboxEngine.executionEnvironment(sandboxWorkspace),
      );
    } else {
      final escapedRoot = commandRoot.replaceAll("'", "''");
      final relative = p.relative(directory, from: commandRoot);
      final mount = relative == '.' ? '' : relative.replaceAll("'", "''");
      final readOnly =
          sandboxWorkspace != null &&
          await aiReadOnlyPowerShell(executable, command);
      String quote(String value) => value.replaceAll("'", "''");
      final modules =
          ['Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Utility']
              .map(
                (name) =>
                    "'${quote(p.join(p.dirname(executable), 'Modules', name, '$name.psd1'))}'",
              )
              .join(',');
      final readPrelude = readOnly
          ? "\$PSModuleAutoLoadingPreference='None'; Import-Module $modules; function Get-Command { param([string[]]\$Name, [string]\$ErrorAction='Stop') Microsoft.PowerShell.Core\\Get-Command -Name \$Name -CommandType Application -ErrorAction \$ErrorAction };\n"
          : '';
      final runtimePaths = sandboxWorkspace == null || readOnly
          ? const <String>[]
          : await aiCommandRuntimePaths(command);
      final preparedPrograms = <String>[];
      final resources = sandboxWorkspace == null || readOnly
          ? const <String>[]
          : await aiCommandReadResources(command);
      var launchCommand = command;
      for (final original in runtimePaths) {
        if (cancelled?.call() == true)
          throw const AiToolException('cancelled', '命令已取消');
        final actual = await aiPrepareRuntime(original, helper);
        preparedPrograms.add(actual);
        if (actual != original) {
          launchCommand = launchCommand.replaceAllMapped(
            RegExp(
              "(['\"])${RegExp.escape(original)}\\1",
              caseSensitive: false,
            ),
            (match) => '${match[1]}$actual${match[1]}',
          );
        }
      }
      final prepared = base64Encode([
        for (final unit
            in ("\$ErrorActionPreference='Stop'; ${readPrelude}New-PSDrive -Name AgentWorkspace -PSProvider FileSystem -Root '$escapedRoot' | Out-Null; Set-Location -LiteralPath 'AgentWorkspace:\\$mount';\n$launchCommand")
                .codeUnits) ...[unit & 255, unit >> 8],
      ]);
      if (cancelled?.call() == true)
        throw const AiToolException('cancelled', '命令已取消');
      process = await Process.start(
        helper,
        [
          commandRoot,
          executable,
          directory,
          prepared,
          if (sandboxWorkspace == null || readOnly) '--global',
          for (final runtime in preparedPrograms) '--read-runtime=$runtime',
          for (final resource in resources) '--read-resource=$resource',
        ],
        workingDirectory: directory,
        includeParentEnvironment: false,
        environment: {
          for (final entry in Platform.environment.entries)
            if (!RegExp(
              r'key|token|secret|password',
              caseSensitive: false,
            ).hasMatch(entry.key))
              entry.key: entry.value,
          'PATH': [
            ...preparedPrograms.map(p.dirname),
            Platform.environment['PATH'] ?? Platform.environment['Path'] ?? '',
          ].join(';'),
          // Node's realpath walk touches ancestors outside the granted script
          // directory; literal module paths keep reads within those grants.
          if (sandboxWorkspace != null &&
              preparedPrograms.any(
                (path) => p.basename(path).toLowerCase() == 'node.exe',
              ))
            'NODE_OPTIONS': '--preserve-symlinks --preserve-symlinks-main',
        },
      );
    }
    late final WindowsProcessJob job;
    try {
      job = WindowsProcessJob.attach(process.pid);
    } catch (_) {
      process.kill();
      await process.exitCode;
      rethrow;
    }
    final session = AiDesktopProcess._(
      id: id,
      owner: owner,
      process: process,
      job: job,
      executable: executable,
      command: command,
      directory: directory,
      workspace: sandboxWorkspace,
    );
    session._deadline = Timer(timeout, () {
      if (session.exitCode != null) return;
      session.timedOut = true;
      session.stop();
    });
    session._cancellation = Timer.periodic(const Duration(milliseconds: 100), (
      _,
    ) {
      if (cancelled?.call() == true) session.stop();
    });
    final out = session._drain(process.stdout, false),
        err = session._drain(process.stderr, true);
    unawaited(() async {
      try {
        final actualExitCode = await process.exitCode;
        session.exitCode = session.timedOut
            ? 124
            : session.stopped
            ? 130
            : actualExitCode;
        job.close();
        await Future.wait([out, err]);
        session._fileChanges = await observation.finish();
      } catch (_) {
        session.exitCode ??= -1;
      } finally {
        job.close();
        session._deadline?.cancel();
        session._cancellation?.cancel();
        session.elapsed.stop();
        if (!session.done.isCompleted) session.done.complete();
      }
    }());
    return session;
  }

  Future<void> _drain(Stream<List<int>> stream, bool error) async {
    try {
      await for (final chunk in stream.transform(
        const Utf8Decoder(allowMalformed: true),
      )) {
        final text = (error ? _err : _out) + chunk;
        final bounded = text.substring(
          (text.length - 64000).clamp(0, text.length),
        );
        if (error) {
          _err = bounded;
          _errLength += chunk.length;
        } else {
          _out = bounded;
          _outLength += chunk.length;
        }
      }
    } on IOException {
      /* Process shutdown can close a pipe before its last read. */
    }
  }

  Future<Map<String, Object?>> poll(Duration wait) async {
    if (running && wait > Duration.zero)
      await Future.any([done.future, Future<void>.delayed(wait)]);
    final outStart = (_outCursor - (_outLength - _out.length)).clamp(
      0,
      _out.length,
    );
    final errStart = (_errCursor - (_errLength - _err.length)).clamp(
      0,
      _err.length,
    );
    final out = _out.substring(outStart), err = _err.substring(errStart);
    final truncated =
        _outLength - _outCursor > 16000 || _errLength - _errCursor > 16000;
    _outCursor = _outLength;
    _errCursor = _errLength;
    String bound(String text) =>
        text.substring((text.length - 16000).clamp(0, text.length));
    final changes = !running && !_changesDelivered
        ? _fileChanges
        : const <AiFileChange>[];
    if (!running) _changesDelivered = true;
    return {
      if (!running && exitCode == 125 && _err.contains('read_runtime_access'))
        'code': 'runtime_access_denied',
      if (changes.isNotEmpty)
        '_fileChanges': changes.map((e) => e.toJson()).toList(),
      'processId': id,
      'elapsedMilliseconds': elapsed.elapsedMilliseconds,
      'running': running,
      'exitCode': exitCode,
      'text': bound(out),
      'error': bound(err),
      'truncated': truncated,
      'stopped': stopped,
      'timedOut': timedOut,
      'message': running
          ? '命令仍在运行'
          : timedOut
          ? '命令执行超时'
          : stopped
          ? '命令已停止'
          : exitCode == 0
          ? '命令已完成'
          : '命令执行未成功',
      'execution': {
        'shell': 'PowerShell 7',
        'executable': executable,
        'command': command,
        'directory': directory,
        'elapsedMilliseconds': elapsed.elapsedMilliseconds,
        'text': bound(_out),
        'error': bound(_err),
        'exitCode': exitCode,
      },
    };
  }

  Future<void> write(String input, {bool close = false}) async {
    if (!running) throw StateError('Process has ended');
    if (input.isNotEmpty) {
      process.stdin.write(input);
      await process.stdin.flush();
    }
    if (close) await process.stdin.close();
  }

  void stop() {
    if (!running) return;
    stopped = true;
    job.close();
  }
}
