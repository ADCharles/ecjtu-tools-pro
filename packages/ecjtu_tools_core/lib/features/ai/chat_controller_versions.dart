// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension AiChatMessageVersionApi on AiChatController {
  void _bindEntryIdentities(String sessionId) {
    var turnId = '';
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final id = entry.entryId.isEmpty ? '$sessionId:legacy:$i' : entry.entryId;
      if (entry.kind == AiChatEntryKind.user) {
        turnId = entry.turnId.isEmpty ? id : entry.turnId;
      }
      final belongs = entry.result?['contextArchive'] == null;
      _entries[i] = entry.copyWith(
        entryId: id,
        turnId: entry.turnId.isEmpty && belongs ? turnId : entry.turnId,
      );
    }
    var userIndex = _entries.length - 1;
    for (var i = _turns.length - 1; i >= 0; i--) {
      if (_turnIds[i].isNotEmpty) continue;
      final question = _turns[i]
          .where((m) => m.role == AiProviderRole.user)
          .firstOrNull
          ?.text;
      while (userIndex >= 0) {
        final entry = _entries[userIndex--];
        if (entry.kind == AiChatEntryKind.user && entry.text == question) {
          _turnIds[i] = entry.turnId;
          break;
        }
      }
    }
    for (final group in _messageVersions.values.toList()) {
      final current = _captureVersion(group.turnId);
      if (group.legacy && current != null) {
        final questions = <String>[];
        final buckets = <int, Map<int, AiChatMessageVersion>>{};
        final chosen = <int, int>{};
        var activePrompt = 0;
        for (var i = 0; i < group.variantCount; i++) {
          final snapshot = i == group.currentVersion
              ? current
              : group.inactive[i];
          if (snapshot == null) continue;
          final text =
              snapshot.entries
                  .where((e) => e.kind == AiChatEntryKind.user)
                  .firstOrNull
                  ?.text ??
              '';
          if (!questions.contains(text)) questions.add(text);
          final prompt = questions.indexOf(text);
          final variants = buckets.putIfAbsent(prompt, () => {});
          final reply = variants.length;
          variants[reply] = snapshot;
          chosen[prompt] = reply;
          if (i == group.currentVersion) {
            activePrompt = prompt;
            chosen[prompt] = reply;
          }
        }
        final activeReply = buckets[activePrompt]!.entries
            .firstWhere((e) => identical(e.value, current))
            .key;
        chosen[activePrompt] = activeReply;
        final migrated = AiChatMessageVersions(
          turnId: group.turnId,
          currentPrompt: activePrompt,
          prompts: {
            for (final bucket in buckets.entries)
              bucket.key: AiChatReplyVersions(
                currentVersion: chosen[bucket.key]!,
                variantCount: bucket.value.length,
                inactive: {
                  for (final reply in bucket.value.entries)
                    if (bucket.key != activePrompt || reply.key != activeReply)
                      reply.key: reply.value,
                },
              ),
          },
        );
        _messageVersions[group.turnId] = migrated;
      }
      _stampVersionEntries(group.turnId, _messageVersions[group.turnId]!);
    }
  }

  AiChatEntry? _versionEntry(String entryId) => _entries
      .where((e) => e.entryId == entryId && entryId.isNotEmpty)
      .firstOrNull;

  AiChatMessageVersion? _captureVersion(String turnId) {
    final entries = _entries.where((e) => e.turnId == turnId).toList();
    if (entries.isEmpty) return null;
    final index = _turnIds.indexOf(turnId);
    if (index >= 0) {
      if (index < _modelHistoryStart) return null;
      return AiChatMessageVersion(
        entries: entries,
        turn: _turns[index],
        origin: _turnOrigins[index],
      );
    }
    if (_modelHistoryStart > 0 || !_modelSummaryUsable) return null;
    final question = entries
        .where((e) => e.kind == AiChatEntryKind.user)
        .firstOrNull
        ?.text;
    for (final entry in _entries.reversed) {
      final archive = entry.result?['contextArchive'];
      if (archive is! Map || archive['turns'] is! List) continue;
      final turns = archive['turns'] as List;
      final ids = archive['turnIds'] as List? ?? const [];
      final origins = archive['turnOrigins'] as List? ?? const [];
      for (var i = 0; i < turns.length; i++) {
        final raw = turns[i] as List;
        final matchesId = i < ids.length && ids[i] == turnId;
        final missingId = i >= ids.length || ids[i] == '';
        if (!matchesId &&
            !(missingId &&
                raw.any(
                  (m) =>
                      m is Map && m['role'] == 'user' && m['text'] == question,
                )))
          continue;
        final source = raw
            .map((m) => AiProviderMessage.fromJson(m as Map))
            .toList();
        if (!isClosedAiChatTurn(source)) continue;
        return AiChatMessageVersion(
          entries: entries,
          turn: source,
          origin: i < origins.length ? origins[i] as String : '',
        );
      }
    }
    return null;
  }

  bool canEditMessage(String entryId) {
    if (_activeRunner case final runner?) return runner.canEditMessage(entryId);
    final entry = _versionEntry(entryId);
    return entry?.kind == AiChatEntryKind.user &&
        _captureVersion(entry!.turnId) != null;
  }

  bool canRegenerateMessage(String entryId) {
    if (_activeRunner case final runner?)
      return runner.canRegenerateMessage(entryId);
    final entry = _versionEntry(entryId);
    return entry?.kind == AiChatEntryKind.assistant &&
        isAiChatFinalAssistant(_entries, entry!, isRunning: busy) &&
        _captureVersion(entry.turnId) != null;
  }

  Future<List<AiProviderMessage>> _hydrateVersionAttachments(
    List<AiProviderMessage> turn,
  ) async {
    final needed = turn
        .expand((m) => m.attachments)
        .where((a) => a.encodedData.isEmpty && a.extractedText.isEmpty)
        .map((a) => a.summary.id)
        .toSet();
    if (needed.isEmpty) return turn;
    final sources = <String, AiChatAttachment>{
      for (final t in _turns)
        for (final m in t)
          for (final a in m.attachments)
            if (a.encodedData.isNotEmpty) a.summary.id: a,
    };
    if (!needed.every(sources.containsKey)) {
      final archived = await _sessionStore.load(
        '$_namespace|attachment-archive|$_activeSessionId',
      );
      for (final session in archived) {
        for (final t in session.turns) {
          for (final m in t) {
            for (final a in m.attachments) sources[a.summary.id] = a;
          }
        }
      }
    }
    if (!needed.every(sources.containsKey)) {
      throw const AiProviderException('attachment_storage', '附件暂时无法读取，请稍后重试');
    }
    return [
      for (final message in turn)
        if (message.attachments.isEmpty)
          message
        else
          AiProviderMessage.fromJson({
            ...message.toJson(includeAttachmentData: false),
            'attachments': [
              for (final a in message.attachments)
                (sources[a.summary.id] ?? a).toJson(),
            ],
          }),
    ];
  }

  void _stampVersionEntries(String turnId, AiChatMessageVersions versions) {
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.turnId != turnId) continue;
      final user = entry.kind == AiChatEntryKind.user;
      final finalReply = isAiChatFinalAssistant(_entries, entry);
      _entries[i] = entry.copyWith(
        variantCount: user
            ? versions.prompts.length
            : finalReply
            ? versions.replies.variantCount
            : 1,
        currentVersion: user
            ? versions.currentPrompt
            : finalReply
            ? versions.replies.currentVersion
            : 0,
      );
    }
  }

  Future<bool> editUserMessage(String entryId, String text) async {
    if (_shuttingDown) return false;
    if (!_isConversationRunner && !loading && !_disposed)
      return _ensureRunner().editUserMessage(entryId, text);
    final entry = _versionEntry(entryId);
    if (entry?.kind != AiChatEntryKind.user ||
        text.trim().isEmpty ||
        text.trimLeft().startsWith('/'))
      return false;
    return _generateMessageVersion(entry!.turnId, text: text);
  }

  Future<bool> regenerate(String entryId) async {
    if (_shuttingDown) return false;
    if (!_isConversationRunner && !loading && !_disposed)
      return _ensureRunner().regenerate(entryId);
    final entry = _versionEntry(entryId);
    if (!canRegenerateMessage(entryId)) return false;
    return _generateMessageVersion(entry!.turnId);
  }

  Future<bool> submitMessageEdit(String entryId, String text) async {
    if (_shuttingDown) return false;
    if (!_isConversationRunner && !loading && !_disposed)
      return _ensureRunner().submitMessageEdit(entryId, text);
    if (!canEditMessage(entryId) ||
        text.trim().isEmpty ||
        text.trimLeft().startsWith('/'))
      return false;
    return _submitMessageVersion(_versionEntry(entryId)!.turnId, text: text);
  }

  Future<bool> submitRegeneration(String entryId) async {
    if (_shuttingDown) return false;
    if (!_isConversationRunner && !loading && !_disposed)
      return _ensureRunner().submitRegeneration(entryId);
    if (!canRegenerateMessage(entryId)) return false;
    return _submitMessageVersion(_versionEntry(entryId)!.turnId);
  }

  Future<bool> _submitMessageVersion(String turnId, {String? text}) {
    final accepted = Completer<bool>();
    unawaited(
      _generateMessageVersion(turnId, text: text, accepted: accepted).then(
        (_) {
          if (!accepted.isCompleted) accepted.complete(false);
        },
        onError: (Object error, StackTrace stack) {
          if (!accepted.isCompleted) accepted.complete(false);
        },
      ),
    );
    return accepted.future;
  }

  Future<bool> _generateMessageVersion(
    String turnId, {
    String? text,
    Completer<bool>? accepted,
  }) async {
    _syncAccount();
    if (_disposed || busy || loading || _saving || importingAttachments)
      return false;
    final original = _captureVersion(turnId);
    if (original == null) return false;
    final generation = _conversationGeneration;
    final oldEntries = List<AiChatEntry>.of(_entries);
    final oldTurns = List<List<AiProviderMessage>>.of(_turns);
    final oldOrigins = List<String>.of(_turnOrigins);
    final oldIds = List<String>.of(_turnIds);
    final oldSummary = _summary;
    final oldHistoryStart = _modelHistoryStart;
    final oldSummaryUsable = _modelSummaryUsable;
    final oldModelAccount = _modelAccountId;
    final oldUsage = _lastUsage;
    final oldInterrupted = _lastInterrupted;
    final start = oldEntries.indexWhere((e) => e.turnId == turnId);
    final index = oldIds.indexOf(turnId);
    final sourceLength = index < 0 ? oldTurns.length : index;
    _editingVersion = true;
    _preparingVersion = true;
    final versionCancellation = AiChatCancellation();
    _versionCancellation = versionCancellation;
    _cancelTitle();
    // Replace the visible reply immediately. Attachment hydration and the
    // previous snapshot save must not delay the next model request.
    if (text == null) {
      _entries.removeWhere(
        (entry) => entry.turnId == turnId && entry.kind != AiChatEntryKind.user,
      );
    } else {
      final replacement = _configuration.redact(text.trim());
      for (var i = 0; i < _entries.length; i++) {
        if (_entries[i].turnId == turnId &&
            _entries[i].kind == AiChatEntryKind.user) {
          _entries[i] = _entries[i].copyWith(text: replacement);
        } else if (_entries[i].turnId == turnId) {
          _entries.removeAt(i--);
        }
      }
    }
    _notify();
    accepted?.complete(true);
    var committed = false;
    try {
      final hydrated = await versionCancellation.race(
        _hydrateVersionAttachments(original.turn),
        timeout: const Duration(seconds: 30),
      );
      versionCancellation.check();
      if (_disposed || generation != _conversationGeneration) return false;
      final user = hydrated.where((m) => m.role == AiProviderRole.user).first;
      _entries.removeWhere((e) => e.turnId == turnId);
      _turns.removeRange(sourceLength, _turns.length);
      _turnOrigins.removeRange(sourceLength, _turnOrigins.length);
      _turnIds.removeRange(sourceLength, _turnIds.length);
      List<AiProviderMessage>? seed;
      List<AiChatEntry>? seedEntries;
      String? replyId;
      if (text == null) {
        final finalReply = original.entries
            .where((e) => e.kind == AiChatEntryKind.assistant)
            .lastOrNull;
        replyId = finalReply?.entryId;
        var end = hydrated.length;
        if (end > 0 &&
            hydrated.last.role == AiProviderRole.assistant &&
            hydrated.last.toolCalls.isEmpty)
          --end;
        seed = _projectTurn(
          hydrated.take(end).toList(),
          origin: original.origin,
        );
        seedEntries = original.entries
            .where(
              (e) =>
                  e.entryId != replyId &&
                  !(e.kind == AiChatEntryKind.reasoning &&
                      e == original.entries.last),
            )
            .toList();
      }
      _preparingVersion = false;
      final sent = await _send(
        text ?? user.text,
        replacementTurnId: turnId,
        replacementAttachments: user.attachments,
        seedTurn: seed,
        seedEntries: seedEntries,
        replacementReplyId: replyId,
        resumeTools: text == null && original.entries.last.isError,
      );
      if (_disposed || generation != _conversationGeneration) return false;
      if (!sent ||
          (_lastInterrupted && accepted == null) ||
          _turnIds.isEmpty ||
          _turnIds.last != turnId)
        return false;
      final fresh = _entries.where((e) => e.turnId == turnId).toList();
      if (!fresh.any(
        (e) => e.kind == AiChatEntryKind.assistant && e.text.trim().isNotEmpty,
      ))
        return false;
      await _archiveAttachmentData(
        [original.turn, _turns.last],
        versionCancellation,
        generation,
      );
      versionCancellation.check();
      final group =
          _messageVersions[turnId] ?? AiChatMessageVersions(turnId: turnId);
      final previous = group.replies;
      final savedPrevious = AiChatReplyVersions(
        currentVersion: previous.currentVersion,
        variantCount: previous.variantCount,
        inactive: {...previous.inactive, previous.currentVersion: original},
      );
      final prompt = text == null ? group.currentPrompt : group.prompts.length;
      final nextReplies = text != null
          ? const AiChatReplyVersions()
          : AiChatReplyVersions(
              currentVersion: previous.variantCount,
              variantCount: previous.variantCount + 1,
              inactive: savedPrevious.inactive,
            );
      final versions = AiChatMessageVersions(
        turnId: turnId,
        currentPrompt: prompt,
        prompts: {
          ...group.prompts,
          group.currentPrompt: savedPrevious,
          prompt: nextReplies,
        },
      );
      _messageVersions[turnId] = versions;
      final addedArchives = _entries
          .where(
            (e) =>
                e.result?['contextArchive'] != null && !oldEntries.contains(e),
          )
          .toList();
      _entries
        ..clear()
        ..addAll(oldEntries.take(start))
        ..addAll(fresh)
        ..addAll(oldEntries.skip(start).where((e) => e.turnId != turnId))
        ..addAll(addedArchives);
      if (index >= 0) {
        _turns.addAll(oldTurns.skip(index + 1));
        _turnOrigins.addAll(oldOrigins.skip(index + 1));
        _turnIds.addAll(oldIds.skip(index + 1));
      }
      _stampVersionEntries(turnId, versions);
      committed = true;
      return true;
    } on AiProviderException {
      return false;
    } finally {
      if (!_disposed && generation == _conversationGeneration && !committed) {
        _entries
          ..clear()
          ..addAll(oldEntries);
        _turns
          ..clear()
          ..addAll(oldTurns);
        _turnOrigins
          ..clear()
          ..addAll(oldOrigins);
        _turnIds
          ..clear()
          ..addAll(oldIds);
        _summary = oldSummary;
        _modelHistoryStart = oldHistoryStart;
        _modelSummaryUsable = oldSummaryUsable;
        _modelAccountId = oldModelAccount;
        _lastUsage = oldUsage;
        _lastInterrupted = oldInterrupted;
      }
      _editingVersion = false;
      _preparingVersion = false;
      if (identical(_versionCancellation, versionCancellation)) {
        _versionCancellation = null;
      }
      if (!_disposed && generation == _conversationGeneration) {
        _refreshContextEstimate();
        unawaited(_persistCurrentSession());
        _notify();
        if (!busy && _queuedInputs.isNotEmpty) unawaited(_drainQueuedInput());
      }
    }
  }

  Future<void> selectMessageVersion(String entryId, int versionIndex) async {
    if (_shuttingDown) return;
    if (!_isConversationRunner && !loading && !_disposed) {
      await _ensureRunner().selectMessageVersion(entryId, versionIndex);
      return;
    }
    _syncAccount();
    if (_disposed || busy || loading || _saving) return;
    final entry = _versionEntry(entryId);
    if (entry == null) return;
    if (entry.kind != AiChatEntryKind.user && !canRegenerateMessage(entryId))
      return;
    final group = _messageVersions[entry.turnId];
    if (group == null) return;
    final prompt = entry.kind == AiChatEntryKind.user
        ? versionIndex
        : group.currentPrompt;
    final targetReplies = group.prompts[prompt];
    if (targetReplies == null) return;
    final reply = entry.kind == AiChatEntryKind.user
        ? targetReplies.currentVersion
        : versionIndex;
    if (prompt == group.currentPrompt && reply == group.replies.currentVersion)
      return;
    final selected = targetReplies.inactive[reply];
    final current = _captureVersion(entry.turnId);
    if (selected == null || current == null) return;
    final generation = _conversationGeneration;
    final cancellation = AiChatCancellation();
    _versionCancellation = cancellation;
    _editingVersion = true;
    _notify();
    try {
      final turn = await cancellation.race(
        _hydrateVersionAttachments(selected.turn),
        timeout: const Duration(seconds: 30),
      );
      cancellation.check();
      if (_disposed || generation != _conversationGeneration) return;
      final index = _turnIds.indexOf(entry.turnId);
      final position = _entries.indexWhere((e) => e.turnId == entry.turnId);
      _entries.removeWhere((e) => e.turnId == entry.turnId);
      _entries.insertAll(position, selected.entries);
      if (index >= 0) {
        _turns[index] = turn;
        _turnOrigins[index] = selected.origin;
      } else {
        _turns.add(turn);
        _turnOrigins.add(selected.origin);
        _turnIds.add(entry.turnId);
      }
      final prompts = Map<int, AiChatReplyVersions>.of(group.prompts);
      final previous = group.replies;
      prompts[group.currentPrompt] = AiChatReplyVersions(
        currentVersion: previous.currentVersion,
        variantCount: previous.variantCount,
        inactive: {...previous.inactive, previous.currentVersion: current},
      );
      final selectedReplies = prompts[prompt]!;
      final inactive = Map<int, AiChatMessageVersion>.of(
        selectedReplies.inactive,
      )..remove(reply);
      prompts[prompt] = AiChatReplyVersions(
        currentVersion: reply,
        variantCount: selectedReplies.variantCount,
        inactive: inactive,
      );
      final next = AiChatMessageVersions(
        turnId: entry.turnId,
        currentPrompt: prompt,
        prompts: prompts,
      );
      _messageVersions[entry.turnId] = next;
      _stampVersionEntries(entry.turnId, next);
      _refreshContextEstimate();
    } on AiProviderException {
      return;
    } finally {
      _editingVersion = false;
      if (identical(_versionCancellation, cancellation))
        _versionCancellation = null;
      if (!_disposed && generation == _conversationGeneration) {
        await _persistCurrentSession();
        _notify();
      }
    }
  }
}
