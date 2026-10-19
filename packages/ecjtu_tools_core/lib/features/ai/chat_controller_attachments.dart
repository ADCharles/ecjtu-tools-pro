// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension AiChatAttachmentApi on AiChatController {
  Future<AiChatAttachment?> _lookupDocument(String id) async {
    final found =
        _turnDocuments[id] ??
        _turns
            .expand((t) => t)
            .expand((m) => m.attachments)
            .where((a) => a.summary.id == id)
            .firstOrNull;
    if (found != null) return found;
    if (!_entries.any((e) => attachmentsForEntry(e).any((a) => a.id == id)))
      return null;
    final generation = _conversationGeneration;
    final account = _accountId;
    final archived = await _sessionStore.load(
      '$_namespace|attachment-archive|$_activeSessionId',
    );
    if (_disposed ||
        generation != _conversationGeneration ||
        account != _accountId)
      return null;
    return archived
        .expand((s) => s.turns)
        .expand((t) => t)
        .expand((m) => m.attachments)
        .where((a) => a.summary.id == id)
        .firstOrNull;
  }

  bool Function() captureAttachmentTarget() {
    final generation = _conversationGeneration;
    final account = _readAccountId();
    return () =>
        !_disposed &&
        generation == _conversationGeneration &&
        account == _readAccountId();
  }

  List<AiAttachmentSummary> get stagedAttachments =>
      _activeRunner?.stagedAttachments ??
      List.unmodifiable(_stagedAttachments.map((a) => a.summary));
  bool get importingAttachments =>
      _activeRunner?.importingAttachments ?? (_attachmentCancellation != null);
  String? get attachmentError =>
      _activeRunner?.attachmentError ?? _attachmentError;
  AiModelCapabilities get modelCapabilities => configuration.modelCapabilities;

  List<AiAttachmentSummary> attachmentsForEntry(AiChatEntry entry) =>
      entry.kind != AiChatEntryKind.user
      ? const []
      : List.unmodifiable(
          (entry.result?['attachments'] as List? ?? const [])
              .whereType<Map>()
              .map(AiAttachmentSummary.fromJson),
        );

  Future<void> saveModelCapabilities(AiModelCapabilities value) =>
      saveModelProfile(modelProfile.copyWith(modelCapabilities: value));

  Future<void> pickAttachments({bool imagesOnly = false}) => _importAttachments(
    (cancellation) async {
      final files = await cancellation.race(
        _attachmentPicker(imagesOnly),
        timeout: const Duration(minutes: 5),
      );
      if (files.length + _stagedAttachments.length >
          AiAttachmentReader.maxAttachments) {
        throw const AiProviderException('attachment_count', '每条消息最多添加 6 个附件');
      }
      final inputs = <AiAttachmentInput>[];
      var total = _stagedAttachments.fold<int>(
        0,
        (n, a) => n + a.summary.byteLength,
      );
      for (final file in files) {
        cancellation.check();
        final length = await cancellation.race(
          file.length(),
          timeout: const Duration(seconds: 10),
        );
        total += length;
        if (length > AiAttachmentReader.maxFileBytes ||
            total > AiAttachmentReader.maxTotalBytes) {
          throw const AiProviderException('attachment_size', '附件过大，请缩小或拆分后重试');
        }
        final bytes = await cancellation.race(
          file.readAsBytes(),
          timeout: const Duration(seconds: 30),
        );
        cancellation.check();
        inputs.add(AiAttachmentInput(name: file.name, bytes: bytes));
      }
      return inputs;
    },
  );

  Future<void> stageAttachments(Iterable<AiAttachmentInput> inputs) =>
      _importAttachments((_) async => inputs.toList());

  Future<void> stageClipboardImage(Uint8List bytes) {
    final extension =
        bytes.length >= 3 &&
            bytes[0] == 255 &&
            bytes[1] == 216 &&
            bytes[2] == 255
        ? 'jpg'
        : bytes.length >= 6 &&
              ascii.decode(bytes.sublist(0, 3), allowInvalid: true) == 'GIF'
        ? 'gif'
        : bytes.length >= 12 &&
              ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF'
        ? 'webp'
        : 'png';
    return stageAttachments([
      AiAttachmentInput(name: '粘贴图片.$extension', bytes: bytes),
    ]);
  }

  Future<void> _importAttachments(
    Future<List<AiAttachmentInput>> Function(AiChatCancellation) load,
  ) async {
    if (_activeRunner case final runner?) {
      await runner._importAttachments(load);
      return;
    }
    _syncAccount();
    if (_disposed || loading || _saving || importingAttachments) return;
    final cancellation = AiChatCancellation();
    _attachmentCancellation = cancellation;
    _attachmentError = null;
    final account = _accountId;
    final generation = _conversationGeneration;
    _notify();
    try {
      final inputs = await load(cancellation);
      cancellation.check();
      if (inputs.length + _stagedAttachments.length >
          AiAttachmentReader.maxAttachments) {
        throw const AiProviderException('attachment_count', '每条消息最多添加 6 个附件');
      }
      var total = _stagedAttachments.fold<int>(
        0,
        (n, a) => n + a.summary.byteLength,
      );
      final ready = <AiChatAttachment>[];
      for (final input in inputs) {
        total += input.bytes.length;
        if (total > AiAttachmentReader.maxTotalBytes)
          throw const AiProviderException(
            'attachment_size',
            '附件合计超过 32 MB，请拆分后重试',
          );
        ready.add(
          await _attachmentReader.read(
            AiAttachmentInput(
              name: _configuration.redact(input.name),
              bytes: input.bytes,
            ),
            cancellation,
          ),
        );
      }
      _syncAccount();
      cancellation.check();
      if (!_disposed &&
          account == _accountId &&
          generation == _conversationGeneration) {
        _stagedAttachments.addAll([
          for (final a in ready)
            a.summary.kind != AiAttachmentKind.image
                ? a
                : AiChatAttachment(
                    summary: AiAttachmentSummary.fromJson({
                      ...a.summary.toJson(),
                      'imageNumber': ++_imageSequence,
                    }),
                    encodedData: a.encodedData,
                    extractedText: a.extractedText,
                    pageCount: a.pageCount,
                  ),
        ]);
        _attachmentCancellation = null;
        _notify();
        unawaited(_persistCurrentSession());
      }
    } on AiProviderException catch (error) {
      if (!_disposed &&
          !cancellation.isCancelled &&
          account == _accountId &&
          generation == _conversationGeneration)
        _attachmentError = error.message;
    } catch (_) {
      if (!_disposed &&
          !cancellation.isCancelled &&
          account == _accountId &&
          generation == _conversationGeneration)
        _attachmentError = '附件暂时无法读取，请重新选择';
    } finally {
      cancellation.cancel();
      if (identical(_attachmentCancellation, cancellation))
        _attachmentCancellation = null;
      _notify();
    }
  }

  void removeStagedAttachment(String id) {
    if (_activeRunner case final runner?) {
      runner.removeStagedAttachment(id);
      return;
    }
    _stagedAttachments.removeWhere((a) => a.summary.id == id);
    _attachmentError = null;
    _notify();
  }

  void clearStagedAttachments() {
    if (_activeRunner case final runner?) {
      runner.clearStagedAttachments();
      return;
    }
    _attachmentCancellation?.cancel();
    _attachmentCancellation = null;
    _stagedAttachments.clear();
    _attachmentError = null;
    _notify();
  }

  Future<bool> sendAttachments(String text) {
    if (busy || importingAttachments) return Future.value(false);
    return send(text);
  }

  Future<Uint8List?> readAttachmentBytes(
    String id, {
    AiChatCancellation? cancellation,
  }) async {
    if (_activeRunner case final runner?)
      return runner.readAttachmentBytes(id, cancellation: cancellation);
    _syncAccount();
    if (_disposed || loading) return null;
    final token = cancellation ?? AiChatCancellation();
    final generation = _conversationGeneration;
    final account = _accountId;
    final namespace = '$_namespace|attachment-archive|$_activeSessionId';
    var found =
        _turnDocuments[id] ??
        _stagedAttachments.where((a) => a.summary.id == id).firstOrNull;
    found ??= _turns
        .expand((turn) => turn)
        .expand((message) => message.attachments)
        .where((a) => a.summary.id == id)
        .firstOrNull;
    if (found == null) {
      if (!_entries.any(
        (entry) => attachmentsForEntry(entry).any((a) => a.id == id),
      ))
        return null;
      final saved = await token.race(
        _sessionStore.load(namespace),
        timeout: const Duration(seconds: 30),
      );
      found = saved
          .expand((s) => s.turns)
          .expand((turn) => turn)
          .expand((m) => m.attachments)
          .where((a) => a.summary.id == id)
          .firstOrNull;
    }
    token.check();
    if (found == null || found.encodedData.isEmpty) return null;
    final bytes = await token.race(
      compute(
        base64Decode,
        found.encodedData,
        debugLabel: 'ai-attachment-preview',
      ),
      timeout: const Duration(seconds: 30),
    );
    _syncAccount();
    token.check();
    return !_disposed &&
            generation == _conversationGeneration &&
            account == _accountId
        ? bytes
        : null;
  }

  Future<void> _clearAttachmentArchive(AiChatSession session) async {
    if (!session.messageVersions.any(
          (v) => v.prompts.values
              .expand((p) => p.inactive.values)
              .any((s) => s.turn.any((m) => m.attachments.isNotEmpty)),
        ) &&
        !session.entries.any(
          (e) =>
              (e.result?['contextArchive'] as Map?)?['turns'] is List &&
              ((e.result!['contextArchive'] as Map)['turns'] as List).any(
                (t) =>
                    t is List &&
                    t.any((m) => m is Map && m['attachments'] is List),
              ),
        ))
      return;
    await _sessionStore.save(
      '$_namespace|attachment-archive|${session.id}',
      const [],
    );
  }

  Future<void> _archiveAttachmentData(
    List<List<AiProviderMessage>> turns,
    AiChatCancellation cancellation,
    int generation,
  ) async {
    final attachments = {
      for (final turn in turns)
        for (final message in turn)
          for (final a in message.attachments)
            if (a.encodedData.isNotEmpty) a.summary.id: a,
    };
    if (attachments.isEmpty) return;
    final namespace = '$_namespace|attachment-archive|$_activeSessionId';
    try {
      final saved = await _sessionStore.load(namespace);
      _checkSummaryCancellation(cancellation, generation);
      final records = <String, AiChatAttachment>{
        for (final session in saved)
          for (final turn in session.turns)
            for (final message in turn)
              for (final a in message.attachments) a.summary.id: a,
        ...attachments,
      };
      await _sessionStore.save(namespace, [
        AiChatSession(
          id: 'attachments',
          title: '',
          updatedAt: DateTime.now(),
          turns: [
            [
              AiProviderMessage(
                role: AiProviderRole.user,
                attachments: records.values.toList(),
              ),
            ],
          ],
        ),
      ]);
      _checkSummaryCancellation(cancellation, generation);
    } on AiProviderException {
      rethrow;
    } catch (_) {
      throw const AiProviderException('attachment_storage', '附件暂时无法归档，原上下文已保留');
    }
  }

  AiProviderMessage _filterAttachmentMessage(
    AiProviderMessage message,
    AiPrivacyPolicy policy,
  ) {
    if (message.attachments.isEmpty)
      return AiProviderMessage.fromJson(policy.filter(message.toJson()) as Map);
    final json = Map<String, Object?>.from(
      policy.filter(message.toJson(includeAttachmentData: false)) as Map,
    );
    final filtered = (json['attachments'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    json['attachments'] = [
      for (final a in message.attachments)
        for (final item in filtered)
          if (item['id'] == a.summary.id)
            {...item, if (a.encodedData.isNotEmpty) 'data': a.encodedData},
    ];
    return AiProviderMessage.fromJson(json);
  }

  AiProviderMessage _attachmentProjection(AiProviderMessage message) {
    if (message.attachments.any((a) => a.extractedText.length > 4000)) {
      message = AiProviderMessage(
        role: message.role,
        text: message.text,
        toolCalls: message.toolCalls,
        toolCallId: message.toolCallId,
        toolName: message.toolName,
        isError: message.isError,
        responsesOutput: message.responsesOutput,
        reasoning: message.reasoning,
        anthropicThinking: message.anthropicThinking,
        attachments: [
          for (final a in message.attachments)
            if (a.extractedText.length > 4000)
              AiChatAttachment(
                summary: a.summary,
                pageCount: a.pageCount,
                extractedText:
                    'attachmentId: ${a.summary.id}\n'
                    '此文件可用 search_document 搜索正文，再用 read_document 读取相关页或行。'
                    '${a.summary.partialText ? '导入时仅提取了部分正文，PDF检索使用完整原文件。' : ''}',
              )
            else
              a,
        ],
      );
    }
    if (message.attachments.isEmpty ||
        message.attachments.every((a) => a.supportedBy(modelCapabilities)))
      return message;
    final json = message.toJson(includeAttachmentData: false);
    json['text'] = [
      message.text,
      for (final a in message.attachments)
        if (!a.supportedBy(modelCapabilities))
          '${a.summary.label}（当前模型${a.summary.kind == AiAttachmentKind.image ? '未开启图片识别' : '未开启 PDF 支持'}，不能分析其内容）',
    ].join('\n');
    json['attachments'] = message.attachments
        .where((a) => a.supportedBy(modelCapabilities))
        .map((a) => a.toJson())
        .toList();
    return AiProviderMessage.fromJson(json);
  }
}
