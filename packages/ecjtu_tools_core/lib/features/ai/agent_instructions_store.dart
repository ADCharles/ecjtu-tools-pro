// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'provider_models.dart';

abstract interface class AiAgentInstructionsStore {
  static const maxCharacters = 8192;
  static const maxTokens = 2048;

  static String validate(String value) {
    final text = value.replaceAll('\r\n', '\n').trim();
    if (text.length > maxCharacters || estimateAiTokens(text) > maxTokens) {
      throw const AiProviderException(
        'agent_instructions_limit',
        '长期指令过长，请精简至 2048 tokens 以内',
      );
    }
    return text;
  }

  Future<String> load();
  Future<void> save(String text);
}

class AiFileAgentInstructionsStore implements AiAgentInstructionsStore {
  AiFileAgentInstructionsStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  Future<void> _writes = Future.value();

  Future<File> _file() async {
    final root = await _directory();
    return File(
      '${root.path}${Platform.pathSeparator}ai-chat-config${Platform.pathSeparator}agent.md',
    );
  }

  @override
  Future<String> load() async {
    await _writes;
    final file = await _file();
    if (!await file.exists()) return '';
    if (await file.length() > AiAgentInstructionsStore.maxCharacters * 4) {
      throw const AiProviderException(
        'agent_instructions_limit',
        '长期指令过长，请精简至 2048 tokens 以内',
      );
    }
    return AiAgentInstructionsStore.validate(await file.readAsString());
  }

  @override
  Future<void> save(String text) {
    final value = AiAgentInstructionsStore.validate(text);
    final next = _writes.then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
      final pending = File('${file.path}.pending');
      await pending.writeAsString(value, flush: true);
      await pending.rename(file.path);
    });
    _writes = next.catchError((_) {});
    return next;
  }
}

class AiMemoryAgentInstructionsStore implements AiAgentInstructionsStore {
  AiMemoryAgentInstructionsStore([this.text = '']);
  String text;
  @override
  Future<String> load() async => AiAgentInstructionsStore.validate(text);
  @override
  Future<void> save(String value) async {
    text = AiAgentInstructionsStore.validate(value);
  }
}
