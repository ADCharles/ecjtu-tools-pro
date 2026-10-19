// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:path/path.dart' as p;

import 'ai_models.dart';
import 'chat_execution_mode.dart';

import 'windows_known_folders.dart';
import 'windows_process_job.dart';
import 'desktop_agent_process.dart';
import 'attachment_models.dart';
import 'attachment_reader.dart';
import '../workbench/pdf_content_reader.dart';
import '../workbench/document_text_search.dart';
import 'provider_models.dart';
import 'powershell_runtime.dart';
import 'file_change.dart';
import 'tool_names.dart';
import 'desktop_toolchain.dart';
import 'desktop_shell_policy.dart';
import 'windows_sandbox_engine.dart';

typedef AiAgentDocumentReader =
    Future<({Uint8List bytes, String name})> Function(String kind, String id);

class AiDesktopAgentTools {
  AiDesktopAgentTools({
    this.approve,
    this.readDocumentFile,
    this.sandboxExecutable,
    this.sandboxEngine,
    AiPowerShellRuntimeLocator? runtimeLocator,
    Map<String, String> Function()? folders,
  }) : folders = folders ?? windowsKnownFolders,
       _runtimeLocator = runtimeLocator;
  final Future<bool> Function(AiSemanticAction, Map<String, Object?>)? approve;
  final Map<String, String> Function() folders;
  final AiAgentDocumentReader? readDocumentFile;
  final String? sandboxExecutable;
  final AiWindowsSandboxEngine? sandboxEngine;
  AiWindowsSandboxEngine? get _engine => sandboxEngine;
  static const names = {
    'read_text_file',
    'write_text_file',
    'get_file_environment',
    'list_directory',
    'read',
    'read_document_file',
    'write',
    'delete_file',
    'create_directory',
    'move_file',
    'save_document',
    'run_powershell',
    'install_powershell',
    'read_process',
    'write_process',
    'stop_process',
    'list_processes',
  };
  AiPowerShellRuntimeLocator? _runtimeLocator;
  AiPowerShellRuntimeLocator get _runtime =>
      _runtimeLocator ??= AiPowerShellRuntimeLocator(
        helper:
            sandboxExecutable ??
            p.join(
              p.dirname(Platform.resolvedExecutable),
              'assistant_sandbox.exe',
            ),
      );
  final _processes = <String, AiDesktopProcess>{};
  final _starting =
      <String, ({String owner, Future<AiDesktopProcess> future})>{};
  bool _closed = false;
  Future<void> close() async {
    _closed = true;
    for (final process in _processes.values) {
      process.stop();
    }
    await Future.wait(_processes.values.map((process) => process.done.future));
    _processes.clear();
  }

  List<Map<String, Object?>> get tools {
    if (!Platform.isWindows || AiAgentScope.current?.mode != AiChatMode.agent)
      return const [];
    Map<String, Object?> tool(
      String name,
      String description,
      Map<String, Object?> props, {
      List<String> required = const [],
      bool readOnly = true,
    }) => {
      'name': name,
      'description': description,
      'inputSchema': {
        'type': 'object',
        'properties': props,
        'required': required,
        'additionalProperties': false,
      },
      'annotations': {'readOnlyHint': readOnly, 'destructiveHint': !readOnly},
    };
    const path = {'type': 'string', 'maxLength': 1024};
    const processId = {'type': 'string', 'maxLength': 160};
    return [
      tool(
        'get_file_environment',
        '查询真实工作区、桌面、下载和文档目录及文件访问范围。使用桌面等位置前先查询，不猜用户名、OneDrive或目录路径。',
        {},
      ),
      tool(
        'list_directory',
        '列出真实目录文件，不递归。相对路径基于当前工作区；读取权限失败时按返回信息调整。',
        {
          'path': path,
          'offset': {'type': 'integer', 'minimum': 0},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 100},
        },
        required: ['path'],
      ),
      tool(
        'read',
        '分段读取真实文本文件，offset和limit是字符数，可用query搜索并返回命中附近内容。PDF和Word使用文档技能。',
        {
          'path': path,
          'offset': {'type': 'integer', 'minimum': 0},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 16000},
          'query': {'type': 'string', 'maxLength': 256},
        },
        required: ['path'],
      ),
      tool(
        'write',
        '在允许的目录创建或编辑文本文件。编辑前先读取实际内容，覆盖已有文件必须明确overwrite=true。',
        {
          'path': path,
          'content': {'type': 'string', 'maxLength': 1000000},
          'overwrite': {'type': 'boolean'},
        },
        required: ['path', 'content'],
        readOnly: false,
      ),
      tool(
        'read_document_file',
        '分段读取工作区内PDF、DOCX、XLSX、PPTX、CSV或文本；query可检索关键词。同义词用 | 分隔。PDF offset是页偏移，其他格式是行偏移；优先检索再读取，不全篇塞入上下文。',
        {
          'path': path,
          'query': {'type': 'string', 'maxLength': 256},
          'offset': {'type': 'integer', 'minimum': 0},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
        },
        required: ['path'],
      ),
      tool(
        'save_document',
        '将所选校历或学生手册保存到指定路径。先从目录获得documentId；kind为workbook或school_calendar。工作区范围内直接保存，越界时返回限制，不擅自换位置。',
        {
          'path': path,
          'kind': {
            'type': 'string',
            'enum': ['workbook', 'school_calendar'],
          },
          'documentId': {'type': 'string', 'maxLength': 160},
          'overwrite': {'type': 'boolean'},
        },
        required: ['path', 'kind', 'documentId'],
        readOnly: false,
      ),
      tool(
        'delete_file',
        '删除指定的单个文件。先读取或列目录核对目标；不删除目录，不递归。',
        {'path': path},
        required: ['path'],
        readOnly: false,
      ),
      tool(
        'create_directory',
        '在允许范围创建一个目录，父目录必须已存在。',
        {'path': path},
        required: ['path'],
        readOnly: false,
      ),
      tool(
        'move_file',
        '将单个文件移动或重命名到指定路径；不覆盖已有目标，不移动目录。',
        {'path': path, 'destination': path},
        required: ['path', 'destination'],
        readOnly: false,
      ),
      tool(
        'install_powershell',
        '当PowerShell 7缺失时请求用户确认安装；此工具只执行固定安装流程。',
        {},
        readOnly: false,
      ),
      tool(
        'run_powershell',
        '使用PowerShell 7执行命令、管道、脚本和已安装的程序，包括编译器及构建工具。默认当前工作区，可指定workingDirectory。用Get-Command发现程序实际位置，不猜可用性；需要完整工具链环境时加载其初始化脚本。running=true时用read_process继续读取，不重复启动。PowerShell 7缺失时调用install_powershell。',
        {
          'command': {'type': 'string', 'maxLength': 16000},
          'workingDirectory': path,
          'yieldMilliseconds': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 30000,
          },
          'timeoutSeconds': {'type': 'integer', 'minimum': 1, 'maximum': 600},
        },
        required: ['command'],
        readOnly: false,
      ),
      tool('list_processes', '查看本会话的命令进程和完成状态，不显示其他会话的进程。', {}),
      tool(
        'read_process',
        '按run_powershell返回的processId继续等待命令并读取新增输出，running=false才是命令结束。不要反复重新启动同一命令。',
        {
          'processId': processId,
          'waitMilliseconds': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 300000,
          },
        },
        required: ['processId'],
      ),
      tool(
        'write_process',
        '向本会话正在运行的命令写入标准输入，例如对正在等待输入的脚本传入一行文本（包含换行）。不是重新启动命令。closeInput=true关闭输入流。',
        {
          'processId': processId,
          'input': {'type': 'string', 'maxLength': 16000},
          'closeInput': {'type': 'boolean'},
        },
        required: ['processId', 'input'],
        readOnly: false,
      ),
      tool(
        'stop_process',
        '停止本会话指定命令及其子进程。',
        {'processId': processId},
        required: ['processId'],
        readOnly: false,
      ),
    ];
  }

  Future<String> _resolve(
    AiAgentScope scope,
    String path, {
    bool create = false,
    bool write = false,
  }) async {
    if (path.isEmpty ||
        path.length > 1024 ||
        path.contains(RegExp(r'[\x00-\x1f]')) ||
        path.startsWith('\\\\')) {
      throw const AiToolException('invalid_path', '请选择有效的本机文件路径');
    }
    final root = await Directory(scope.workspace).resolveSymbolicLinks();
    final target = p.normalize(p.isAbsolute(path) ? path : p.join(root, path));
    if (write &&
        !scope.global &&
        !p.equals(root, target) &&
        !p.isWithin(root, target)) {
      throw const AiToolException('file_permission', '此路径超出本会话工作区，未执行');
    }
    final type = await FileSystemEntity.type(target, followLinks: false);
    if (type == FileSystemEntityType.notFound && !create) {
      throw const AiToolException('file_not_found', '指定文件或目录不存在，请核对路径；这不是权限拒绝');
    }
    final canonical = type == FileSystemEntityType.notFound && create
        ? p.join(
            await Directory(p.dirname(target)).resolveSymbolicLinks(),
            p.basename(target),
          )
        : type == FileSystemEntityType.directory
        ? await Directory(target).resolveSymbolicLinks()
        : await File(target).resolveSymbolicLinks();
    final install = p.dirname(Platform.resolvedExecutable);
    final work = p.join(install, 'workspace');
    final runtime = p.join(
      Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
      'DongCharles',
      'assistant-runtime',
    );
    if (write && _runtimeLocator?.protects(canonical) == true) {
      throw const AiToolException('protected_path', '此位置属于命令运行环境，未执行修改');
    }
    if (write &&
        (p.equals(runtime, canonical) || p.isWithin(runtime, canonical))) {
      throw const AiToolException('protected_path', '此位置属于命令运行环境，未执行修改');
    }
    if (write &&
        (p.equals(install, canonical) || p.isWithin(install, canonical)) &&
        !p.equals(work, canonical) &&
        !p.isWithin(work, canonical)) {
      throw const AiToolException('protected_path', '此位置属于应用运行文件，未执行修改');
    }
    if (write &&
        !scope.global &&
        !p.equals(root, canonical) &&
        !p.isWithin(root, canonical)) {
      throw const AiToolException(
        'file_permission',
        '此路径超出本会话工作区，未执行。请保持用户指定的位置，不要改存到其他目录，也不要重试相同的越界访问。',
      );
    }
    return canonical;
  }

  Future<void> _confirm(
    String name,
    Map<String, Object?> args, {
    bool readOnly = false,
    bool always = false,
  }) async {
    final mode =
        ChatPermissionScope.currentMode ?? ChatPermissionMode.askChanges;
    if (!always &&
        (mode == ChatPermissionMode.automatic ||
            readOnly && mode == ChatPermissionMode.askChanges))
      return;
    final action = AiSemanticAction(
      id: 'agent.$name',
      title: switch (name) {
        'install_powershell' => '安装 PowerShell 7',
        'install_agent_environment' => '初始化命令运行环境',
        'run_powershell' => '运行 PowerShell 7 命令',
        'write_process' => '向运行中的命令发送输入',
        'write' || 'save_document' => '保存文件',
        'file_access' => '访问指定文件位置',
        _ => '读取本机文件',
      },
      description: '',
      kind: AiActionKind.button,
      invoke: (_) {},
      arguments: [
        for (final key in args.keys)
          AiActionArgument(
            name: key,
            title: switch (key) {
              'path' => '路径',
              'command' => '命令',
              'input' => '输入',
              _ => '内容',
            },
            maxLength: 1000000,
          ),
      ],
    );
    final callback = approve;
    AiAgentScope.current?.onPhase?.call('等待授权');
    final bool allowed;
    try {
      allowed =
          callback != null &&
          await ChatPermissionScope.run(
            always ? ChatPermissionMode.askEveryAction : mode,
            () => callback(action, args),
          );
    } finally {
      AiAgentScope.current?.onPhase?.call('正在处理');
    }
    if (!allowed)
      throw const AiToolException(
        'permission_declined',
        '用户未允许此次操作，请继续处理其他可完成的部分',
      );
  }

  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> args, {
    bool Function()? isCancelled,
  }) async {
    try {
      return await _call(
        aiCanonicalToolName(name),
        args,
        isCancelled: isCancelled,
      );
    } on FileSystemException catch (error) {
      throw switch (error.osError?.errorCode) {
        2 || 3 => const AiToolException(
          'file_not_found',
          '指定文件或目录不存在，请核对路径；这不是权限拒绝',
        ),
        5 => const AiToolException('file_access_denied', '系统拒绝访问此文件位置，未执行操作'),
        _ => const AiToolException('file_io_failed', '文件操作未完成，请核对文件是否仍存在或被占用'),
      };
    } on ProcessException {
      throw const AiToolException(
        'shell_launch_failed',
        '命令运行环境未能启动，不能据此认定 PowerShell 未安装',
      );
    }
  }

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> args, {
    bool Function()? isCancelled,
  }) async {
    final scope = AiAgentScope.current;
    if (!Platform.isWindows ||
        scope == null ||
        scope.mode != AiChatMode.agent) {
      throw const AiToolException('agent_required', '此操作需要桌面 Agent 模式');
    }
    final schema = tools.where((tool) => tool['name'] == name).firstOrNull;
    if (schema == null)
      throw const AiToolException('tool_unavailable', '当前文件访问范围不允许执行此操作');
    final definition = schema['inputSchema'] as Map;
    final props = definition['properties'] as Map;
    final unknown = args.keys.where((key) => !props.containsKey(key)).toList();
    final missing = (definition['required'] as List)
        .where((key) => !args.containsKey(key))
        .toList();
    if (unknown.isNotEmpty || missing.isNotEmpty) {
      throw AiToolException(
        'invalid_arguments',
        [
          if (unknown.isNotEmpty) '未知参数：${unknown.join(', ')}',
          if (missing.isNotEmpty) '缺少参数：${missing.join(', ')}',
        ].join('；'),
      );
    }
    for (final entry in args.entries) {
      final field = props[entry.key] as Map;
      final value = entry.value;
      final valid = switch (field['type']) {
        'string' =>
          value is String &&
              value.length <= (field['maxLength'] as int? ?? 1024),
        'boolean' => value is bool,
        'integer' =>
          value is int &&
              value >= (field['minimum'] as int? ?? 0) &&
              value <= (field['maximum'] as int? ?? 10000000),
        _ => false,
      };
      if (!valid ||
          field['enum'] is List && !(field['enum'] as List).contains(value))
        throw AiToolException(
          'invalid_arguments',
          '${entry.key}需要${field['type']}类型，范围${field['minimum'] ?? 0}至${field['maximum'] ?? field['maxLength'] ?? 1024}；请修正此参数后重试。',
        );
    }
    void check() {
      if (isCancelled?.call() == true)
        throw const AiToolException('cancelled', '操作已停止');
    }

    check();
    if (p.equals(
      scope.workspace,
      p.join(p.dirname(Platform.resolvedExecutable), 'workspace'),
    )) {
      await Directory(scope.workspace).create();
    }
    final owner = scope.ownerId ?? scope.workspace;
    if (name == 'list_processes') {
      return {
        'processes': [
          for (final process in _processes.values.where(
            (process) => process.owner == owner,
          ))
            {
              'processId': process.id,
              'running': process.running,
              'command': process.command,
              'directory': process.directory,
              'exitCode': process.exitCode,
            },
        ],
      };
    }
    if (const {
      'read_process',
      'write_process',
      'stop_process',
    }.contains(name)) {
      final process = _processes[args['processId']];
      if (process == null || process.owner != owner)
        throw const AiToolException('process_not_found', '本会话中未找到该命令进程');
      if (name == 'write_process') {
        await _confirm(name, {
          'input': args['input'],
          'command': process.command,
        });
        check();
        await process.write(
          args['input'] as String,
          close: args['closeInput'] == true,
        );
      }
      if (name == 'stop_process') process.stop();
      scope.onPhase?.call(name == 'stop_process' ? '正在停止命令' : '正在读取命令输出');
      return process.poll(
        Duration(milliseconds: args['waitMilliseconds'] as int? ?? 1000),
      );
    }
    if (name == 'get_file_environment') {
      await _confirm(name, const {}, readOnly: true);
      check();
      String? executable;
      AiToolException? failure;
      try {
        executable = await _findPowerShell();
      } on AiToolException catch (error) {
        failure = error;
      }
      return {
        'workspace': scope.workspace,
        'paths': folders(),
        'globalFileAccess': scope.global,
        'externalFileReads': true,
        'shell': 'PowerShell 7',
        'compilerDirectories': [
          for (final root in await aiDesktopToolchainRoots())
            if (root.toLowerCase().contains('msvc') && root.endsWith('bin'))
              p.join(root, 'Hostx64', 'x64'),
        ],
        'shellAvailable': failure == null ? executable != null : null,
        'shellStatus': failure != null
            ? 'unavailable'
            : executable == null
            ? 'missing'
            : 'available',
        if (executable != null) 'shellExecutable': executable,
        if (failure != null)
          'shellError': {'code': failure.code, 'message': failure.message},
      };
    }
    if (name == 'install_powershell') {
      if (await _findPowerShell() != null)
        return {'message': 'PowerShell 7 已可用', 'alreadyAvailable': true};
      await _confirm(name, const {}, always: true);
      check();
      final install = p.join(
        Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
        'DongCharles',
        'assistant-runtime',
        'powershell7',
      );
      final quoted = install.replaceAll("'", "''");
      final script =
          '''\$ErrorActionPreference='Stop'
\$r=Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
\$arch=if(\$env:PROCESSOR_ARCHITECTURE -eq 'ARM64'){'arm64'}else{'x64'}
\$a=\$r.assets | Where-Object { \$_.name -match ("^PowerShell-7\\..+-win-"+\$arch+"\\.zip\$") } | Select-Object -First 1
if(-not \$a -or \$a.browser_download_url -notlike 'https://github.com/PowerShell/PowerShell/releases/download/*'){throw 'Invalid release'}
\$temp=Join-Path \$env:TEMP ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path \$temp | Out-Null
try {
  \$zip=Join-Path \$temp 'runtime.zip'
  [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -UseBasicParsing -Uri \$a.browser_download_url -OutFile \$zip
  \$stage=Join-Path \$temp 'unpacked'
  Expand-Archive -LiteralPath \$zip -DestinationPath \$stage
  \$exe=Join-Path \$stage 'pwsh.exe'
  \$sig=Get-AuthenticodeSignature -LiteralPath \$exe
  if(\$sig.Status -ne 'Valid' -or \$sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation'){throw 'Signature verification failed'}
  if(Test-Path -LiteralPath '$quoted'){throw 'Runtime directory already exists'}
  New-Item -ItemType Directory -Path (Split-Path '$quoted') -Force | Out-Null
  Move-Item -LiteralPath \$stage -Destination '$quoted'
} finally { if(Test-Path -LiteralPath \$temp){Remove-Item -LiteralPath \$temp -Recurse -Force} }
''';
      final windowsPowerShell = p.join(
        Platform.environment['SystemRoot'] ?? r'C:\Windows',
        'System32',
        'WindowsPowerShell',
        'v1.0',
        'powershell.exe',
      );
      final result = await _process(
        windowsPowerShell,
        ['-NoProfile', '-NonInteractive', '-EncodedCommand', _encoded(script)],
        scope.workspace,
        isCancelled,
        const Duration(minutes: 5),
      );
      if (result['exitCode'] != 0) {
        throw const AiToolException('install_failed', '安装尚未完成，请重试');
      }
      _runtime.invalidate();
      if (await _findPowerShell() == null)
        throw const AiToolException('install_failed', '安装尚未完成，请重试');
      return {'message': 'PowerShell 7 已安装'};
    }
    if (name == 'run_powershell') {
      if (aiDirectReplacementShell(args['command'] as String) != null) {
        throw const AiToolException(
          'shell_not_allowed',
          '请直接使用PowerShell 7命令或调用所需程序，不要通过cmd或Windows PowerShell重新执行。程序访问失败应核对运行环境，而不是替换shell。',
        );
      }
      final installed = await _findPowerShell();
      if (installed == null)
        throw const AiToolException(
          'powershell_missing',
          'PowerShell 7 尚未安装，可调用安装工具请求用户确认',
        );
      final cwd = args['workingDirectory'] == null
          ? scope.workspace
          : await _resolve(
              scope,
              args['workingDirectory'] as String,
              write: !scope.global,
            );
      if (!await Directory(cwd).exists())
        throw const AiToolException('invalid_path', '工作目录不存在，请先检查实际路径');
      final command = args['command'] as String;
      final existing = _processes.values
          .where(
            (process) =>
                process.owner == owner &&
                process.running &&
                process.command == command &&
                process.directory == cwd &&
                process.workspace == (scope.global ? null : scope.workspace),
          )
          .firstOrNull;
      if (existing != null) {
        return {...await existing.poll(Duration.zero), 'reused': true};
      }
      final key = jsonEncode([
        owner,
        cwd,
        command,
        scope.global,
        scope.workspace,
      ]);
      final pending = _starting[key];
      if (pending != null) {
        final process = await pending.future;
        check();
        return {...await process.poll(Duration.zero), 'reused': true};
      }
      if (_closed) throw const AiToolException('cancelled', '命令已取消');
      final runningCount = _processes.values
          .where((p) => p.owner == owner && p.running)
          .length;
      final pendingCount = _starting.values
          .where((p) => p.owner == owner)
          .length;
      if (runningCount + pendingCount >= 4) {
        throw const AiToolException(
          'process_capacity',
          '已有多个命令运行，请先读取结果或停止不需要的命令',
        );
      }
      final flight = () async {
        await _confirm(name, {...args, 'path': cwd});
        check();
        if (_closed) throw const AiToolException('cancelled', '命令已取消');
        final engine = scope.global ? null : _engine;
        final exe = (await _runtime.executable(prepare: engine == null))!;
        if (engine != null) {
          await engine.prepare(
            powershell: exe,
            confirm: () async {
              await _confirm('install_agent_environment', {}, always: true);
              scope.onPhase?.call('正在初始化命令运行环境');
            },
          );
        }
        check();
        if (_closed) throw const AiToolException('cancelled', '命令已取消');
        scope.onPhase?.call('正在运行 PowerShell 7');
        while (_processes.length >= 32) {
          final completed = _processes.values
              .where((process) => !process.running)
              .firstOrNull;
          if (completed == null) break;
          _processes.remove(completed.id);
        }
        final process = await AiDesktopProcess.start(
          id: 'process-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
          owner: owner,
          executable: exe,
          command: command,
          encodedCommand: _encoded(command),
          directory: cwd,
          timeout: Duration(seconds: args['timeoutSeconds'] as int? ?? 120),
          cancelled: scope.isCancelled ?? isCancelled,
          sandboxWorkspace: scope.global ? null : scope.workspace,
          sandboxExecutable: sandboxExecutable,
          sandboxEngine: engine,
        );
        if (_closed ||
            scope.isCancelled?.call() == true ||
            isCancelled?.call() == true) {
          process.stop();
          await process.done.future;
          throw const AiToolException('cancelled', '命令已取消');
        }
        _processes[process.id] = process;
        return process;
      }();
      _starting[key] = (owner: owner, future: flight);
      final AiDesktopProcess process;
      try {
        process = await flight;
      } finally {
        _starting.remove(key);
      }
      final result = await process.poll(
        Duration(milliseconds: args['yieldMilliseconds'] as int? ?? 1000),
      );
      check();
      return result;
    }
    final path = await _resolve(
      scope,
      args['path'] as String,
      create: const {
        'write',
        'save_document',
        'create_directory',
      }.contains(name),
      write: !const {
        'list_directory',
        'read',
        'read_document_file',
      }.contains(name),
    );
    await _confirm(
      name,
      {'path': path},
      readOnly: const {
        'list_directory',
        'read',
        'read_document_file',
      }.contains(name),
    );
    check();
    final confirmedPath = await _resolve(
      scope,
      args['path'] as String,
      create: const {
        'write',
        'save_document',
        'create_directory',
      }.contains(name),
      write: !const {
        'list_directory',
        'read',
        'read_document_file',
      }.contains(name),
    );
    if (!p.equals(path, confirmedPath)) {
      throw const AiToolException('path_changed', '文件位置已变化，请重新选择');
    }
    if (name == 'delete_file' || name == 'move_file') {
      if (await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.file)
        throw const AiToolException('invalid_path', '请选择一个真实文件');
      if (name == 'delete_file') {
        final before = await aiFileText(File(path));
        check();
        await File(path).delete();
        final change = await AiFileChange.compare(
          path: path,
          operation: 'delete',
          before: before,
          after: '',
        );
        return {
          'path': path,
          'message': '文件已删除',
          '_fileChanges': [change.toJson()],
        };
      }
      final destination = await _resolve(
        scope,
        args['destination'] as String,
        create: true,
        write: true,
      );
      if (await FileSystemEntity.type(destination, followLinks: false) !=
          FileSystemEntityType.notFound)
        throw const AiToolException('file_exists', '目标已存在，未移动文件');
      check();
      await File(path).rename(destination);
      final change = AiFileChange(
        path: destination,
        previousPath: path,
        operation: 'move',
      );
      return {
        'path': destination,
        'message': '文件已移动',
        '_fileChanges': [change.toJson()],
      };
    }
    if (name == 'create_directory') {
      await Directory(path).create();
      return {'path': path, 'message': '目录已创建'};
    }
    if (name == 'list_directory') {
      final offset = args['offset'] as int? ?? 0,
          limit = args['limit'] as int? ?? 40;
      final entries = <Map<String, Object?>>[];
      var skipped = 0;
      await for (final entry in Directory(path).list(followLinks: false)) {
        check();
        if (skipped++ < offset) continue;
        entries.add({
          'name': p.basename(entry.path),
          'path': entry.path,
          'type': entry is Directory
              ? '文件夹'
              : entry is Link
              ? '链接'
              : '文件',
        });
        if (entries.length > limit) break;
      }
      return {
        'path': path,
        'entries': entries.take(limit).toList(),
        'nextOffset': entries.length > limit ? offset + limit : null,
      };
    }
    final file = File(path);
    if (name == 'read_document_file') {
      if (await file.length() > AiAttachmentReader.maxFileBytes)
        throw const AiToolException('file_too_large', '文件超过20 MB，请拆分后读取');
      final bytes = await file.readAsBytes();
      check();
      final offset = args['offset'] as int? ?? 0;
      final limit = args['limit'] as int? ?? 8;
      final query = args['query'] as String?;
      if (p.extension(path).toLowerCase() == '.pdf') {
        final pdf = PdfContentReader();
        return query == null
            ? pdf.read(
                bytes,
                offset: offset,
                limit: limit.clamp(1, 8),
                isCancelled: isCancelled,
              )
            : pdf.search(
                bytes,
                query: query,
                offset: offset,
                limit: limit,
                isCancelled: isCancelled,
              );
      }
      final cancellation = AiChatCancellation();
      try {
        final document = await AiAttachmentReader(desktop: true).read(
          AiAttachmentInput(name: p.basename(path), bytes: bytes),
          cancellation,
        );
        check();
        final lines = document.extractedText.split('\n');
        if (query != null)
          return DocumentTextSearch.search(
            [
              for (var i = 0; i < lines.length; i++)
                {'pageNumber': i + 1, 'text': lines[i]},
            ],
            query: query,
            offset: offset,
            limit: limit,
          );
        final selected = lines.skip(offset).take(limit).join('\n');
        return {
          'path': path,
          'lineCount': lines.length,
          'offset': offset,
          'text': selected.length > 16000
              ? selected.substring(0, 16000)
              : selected,
          'nextOffset': offset + limit < lines.length ? offset + limit : null,
        };
      } finally {
        cancellation.cancel();
      }
    }
    if (name == 'read') {
      if (await file.length() > 2 * 1024 * 1024)
        throw const AiToolException('file_too_large', '此文件较大，请使用文档检索工具');
      final content = await file.readAsString();
      final query = args['query'] as String?;
      final offset = query == null
          ? args['offset'] as int? ?? 0
          : content.toLowerCase().indexOf(query.toLowerCase());
      if (offset < 0) return {'path': path, 'found': false, 'text': ''};
      final start = offset.clamp(0, content.length),
          end = (offset + (args['limit'] as int? ?? 8000)).clamp(
            0,
            content.length,
          );
      return {
        'path': path,
        'text': content.substring(start, end),
        'offset': start,
        'nextOffset': end < content.length ? end : null,
      };
    }
    final existed = await file.exists();
    if (existed && args['overwrite'] != true)
      throw const AiToolException('file_exists', '文件已存在，编辑前请读取原文并明确允许覆盖');
    if (name == 'save_document') {
      final before = await aiFileText(file);
      final read = readDocumentFile;
      if (read == null)
        throw const AiToolException('file_unavailable', '文件暂不可用，请重新获取目录');
      final document = await read(
        args['kind'] as String,
        args['documentId'] as String,
      );
      check();
      final current = await _resolve(
        scope,
        args['path'] as String,
        create: true,
        write: true,
      );
      if (!p.equals(path, current))
        throw const AiToolException('path_changed', '文件位置已变化，请重新选择');
      if (!existed) await file.create(exclusive: true);
      await file.writeAsBytes(document.bytes, flush: true);
      final change = await AiFileChange.compare(
        path: path,
        operation: existed ? 'edit' : 'create',
        before: before,
        after: await aiFileText(file),
      );
      return {
        'path': path,
        'name': document.name,
        'size': document.bytes.lengthInBytes,
        'message': '文件已保存',
        '_fileChanges': [change.toJson()],
      };
    }
    final before = await aiFileText(file);
    check();
    // Exclusive creation prevents a new destination from overwriting a concurrently created file.
    if (!existed) await file.create(exclusive: true);
    await file.writeAsString(args['content'] as String, flush: true);
    final change = await AiFileChange.compare(
      path: path,
      operation: existed ? 'edit' : 'create',
      before: before,
      after: await aiFileText(file),
    );
    return {
      'path': path,
      'message': '文件已保存',
      '_fileChanges': [change.toJson()],
    };
  }

  String _encoded(String value) => base64Encode([
    for (final code in value.codeUnits) ...[code & 255, code >> 8],
  ]);
  Future<String?> _findPowerShell() async {
    return _runtime.executable();
  }

  Future<Map<String, Object?>> _process(
    String exe,
    List<String> arguments,
    String cwd,
    bool Function()? cancelled,
    Duration timeout,
  ) async {
    final process = await Process.start(
      exe,
      arguments,
      workingDirectory: cwd,
      includeParentEnvironment: false,
      environment: {
        for (final entry in Platform.environment.entries)
          if (!RegExp(
            r'key|token|secret|password',
            caseSensitive: false,
          ).hasMatch(entry.key))
            entry.key: entry.value,
      },
    );
    late final WindowsProcessJob job;
    try {
      job = WindowsProcessJob.attach(process.pid);
    } catch (_) {
      process.kill();
      await process.exitCode;
      throw const AiToolException('process_unavailable', '命令暂时无法启动，请重试');
    }
    var stopped = false, timedOut = false;
    final timer = Timer(timeout, () {
      timedOut = true;
      job.close();
    });
    final watcher = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (cancelled?.call() == true) {
        stopped = true;
        job.close();
      }
    });
    Future<String> read(Stream<List<int>> stream) async {
      final result = StringBuffer();
      await for (final chunk in stream.transform(
        const Utf8Decoder(allowMalformed: true),
      )) {
        if (result.length < 64000)
          result.write(
            chunk.substring(0, (64000 - result.length).clamp(0, chunk.length)),
          );
      }
      return result.toString();
    }

    final out = read(process.stdout), err = read(process.stderr);
    try {
      final code = await process.exitCode;
      job.close();
      final stdout = await out, stderr = await err;
      if (stopped) throw const AiToolException('cancelled', '操作已停止');
      if (timedOut)
        throw const AiToolException('command_timeout', '命令执行超时，请缩小任务后重试');
      return {'exitCode': code, 'text': stdout, 'error': stderr};
    } finally {
      job.close();
      timer.cancel();
      watcher.cancel();
    }
  }
}
