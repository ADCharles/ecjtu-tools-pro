// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension _AiChatRunners on AiChatController {
  Set<String> get runningSessionIds => {
    for (final entry in _runners.entries)
      if (entry.value.busy) entry.key,
    if (_isConversationRunner && busy && _activeSessionId != null)
      _activeSessionId!,
  };

  AiChatController _ensureRunner() {
    if (_isConversationRunner) return this;
    final id = _activeSessionId!;
    return _runners.putIfAbsent(id, () {
      // Each conversation owns its request, approval and history. The parent
      // remains the sole writer of the shared conversation index.
      final runner = AiChatController(
        bridge: bridge,
        provider: _provider,
        store: _store,
        sessionStore: _AiConversationStore(this, id, _namespace),
        agentInstructionsStore: _agentStore,
        modelCatalog: _modelCatalog,
        attachmentReader: _attachmentReader,
        attachmentPicker: _attachmentPicker,
        modelCapabilityStore: _modelCapabilityStore,
        modelRegistry: _modelRegistry,
        maxHistoryTurns: maxHistoryTurns,
        toolTimeout: toolTimeout,
        enableTitleSummaries: enableTitleSummaries,
        conversationRunner: true,
      );
      runner._configuration = _configuration;
      runner._namespace = _namespace;
      runner._accountId = _accountId;
      runner._loading = false;
      runner._memoryWritable = _memoryWritable;
      runner._sessions.add(_sessions.firstWhere((session) => session.id == id));
      _copyConversationTo(runner);
      runner._services = _services;
      runner._availableModels = _availableModels;
      runner._configuredModels = _configuredModels;
      runner._agentInstructions = _agentInstructions;
      runner._agentLoad = _agentLoad.then((text) {
        runner._agentInstructions = text;
        return text;
      });
      var wasBusy = runner.busy;
      runner.addListener(() {
        if (_disposed || _runners[id] != runner) return;
        if (_activeSessionId == id || wasBusy != runner.busy) _notify();
        wasBusy = runner.busy;
      });
      return runner;
    });
  }

  void _copyConversationTo(AiChatController target) {
    target._mode = _mode;
    target._workspace = _workspace;
    target._globalFiles = _globalFiles;
    target._activeSessionId = _activeSessionId;
    target._activeConversationTitle = _activeConversationTitle;
    target._entries
      ..clear()
      ..addAll(_entries);
    target._turns
      ..clear()
      ..addAll(_turns);
    target._turnOrigins
      ..clear()
      ..addAll(_turnOrigins);
    target._turnIds
      ..clear()
      ..addAll(_turnIds);
    target._messageVersions
      ..clear()
      ..addAll(_messageVersions);
    target._migratedNamespaces
      ..clear()
      ..addAll(_migratedNamespaces);
    target._summary = _summary;
    target._sessionPermissionMode = _sessionPermissionMode;
    target._imageSequence = _imageSequence;
    target._stagedAttachments
      ..clear()
      ..addAll(_stagedAttachments);
    target._attachmentError = _attachmentError;
    target._lastInterrupted = _lastInterrupted;
    target._estimatedContextTokens = _estimatedContextTokens;
    target._lastUsage = _lastUsage;
    target._usageRequests
      ..clear()
      ..addAll(_usageRequests);
    target._modelHistoryStart = _modelHistoryStart;
    target._modelSummaryUsable = _modelSummaryUsable;
    target._modelAccountId = _modelAccountId;
  }

  void _captureRunner() {
    final runner = _activeRunner;
    if (runner == null) {
      if (_activeSessionId case final id?)
        _sessionConfigurations[id] = _configuration;
      return;
    }
    runner._copyConversationTo(this);
    _configuration = runner._configuration;
    _sessionConfigurations[runner._activeSessionId!] = runner._configuration;
  }

  void _retireRunners() {
    final retired = _runners.values.toList();
    _runners.clear();
    _sessionConfigurations.clear();
    for (final runner in retired) runner.dispose();
  }
}

class _AiConversationStore implements AiChatSessionStore {
  _AiConversationStore(this.parent, this.id, this.namespace);
  final AiChatController parent;
  final String id, namespace;

  @override
  Future<List<AiChatSession>> load(String scope) =>
      parent._sessionStore.load(scope);

  @override
  Future<void> save(String scope, List<AiChatSession> sessions) async {
    if (scope != namespace) {
      await parent._sessionStore.save(scope, sessions);
      return;
    }
    if (!merge(scope, sessions)) return;
    await parent._sessionStore.save(scope, List.of(parent._sessions));
  }

  bool merge(String scope, List<AiChatSession> sessions) {
    if (scope != namespace || parent._namespace != namespace) return false;
    final index = parent._sessions.indexWhere((session) => session.id == id);
    if (index < 0) return false;
    final updated = sessions.where((session) => session.id == id).firstOrNull;
    if (updated == null) return false;
    parent._sessions[index] = updated.copyWith(
      titleSummaryAttempted:
          updated.titleSummaryAttempted ||
          parent._sessions[index].titleSummaryAttempted,
    );
    return true;
  }
}
