// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'provider_models.dart';
import 'chat_execution_mode.dart';
import 'file_change.dart';

class AiChatLink {
  const AiChatLink({required this.title, required this.uri});
  final String title;
  final Uri uri;
}

enum AiChatEntryKind { user, assistant, tool, notice, reasoning, progress }

class AiChatGenerationStats {
  const AiChatGenerationStats({
    this.inputTokens,
    this.outputTokens,
    this.cachedInputTokens,
    required this.modelMilliseconds,
  });
  final int? inputTokens, outputTokens, cachedInputTokens;
  final int modelMilliseconds;
  double? get tokensPerSecond =>
      outputTokens != null && outputTokens! >= 0 && modelMilliseconds > 0
      ? outputTokens! * 1000 / modelMilliseconds
      : null;
  double? get cacheHitRate =>
      inputTokens != null &&
          inputTokens! > 0 &&
          cachedInputTokens != null &&
          cachedInputTokens! >= 0 &&
          cachedInputTokens! <= inputTokens!
      ? cachedInputTokens! / inputTokens!
      : null;
  Map<String, Object?> toJson() => {
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'cachedInputTokens': cachedInputTokens,
    'modelMilliseconds': modelMilliseconds,
  };
  factory AiChatGenerationStats.fromJson(Map value) => AiChatGenerationStats(
    inputTokens: value['inputTokens'] as int?,
    outputTokens: value['outputTokens'] as int?,
    cachedInputTokens: value['cachedInputTokens'] as int?,
    modelMilliseconds: value['modelMilliseconds'] as int? ?? 0,
  );
}

class AiChatUsageSummary {
  AiChatUsageSummary(Iterable<AiChatGenerationStats> requests) {
    for (final request in requests) {
      requestCount++;
      if (request.inputTokens case final int tokens when tokens >= 0) {
        inputRequests++;
        inputTokens += tokens;
      }
      if (request.outputTokens case final int tokens when tokens >= 0) {
        outputRequests++;
        outputTokens += tokens;
      }
      if (request.cacheHitRate != null) {
        cacheRequests++;
        cacheInputTokens += request.inputTokens!;
        cachedInputTokens += request.cachedInputTokens!;
      }
      if (request.tokensPerSecond != null) {
        timedOutputTokens += request.outputTokens!;
        modelMilliseconds += request.modelMilliseconds;
      }
    }
  }
  int requestCount = 0, cacheRequests = 0;
  int inputRequests = 0, outputRequests = 0;
  int inputTokens = 0, outputTokens = 0, cachedInputTokens = 0;
  int cacheInputTokens = 0, timedOutputTokens = 0, modelMilliseconds = 0;
  double? get cacheHitRate =>
      cacheInputTokens > 0 ? cachedInputTokens / cacheInputTokens : null;
  double? get tokensPerSecond => modelMilliseconds > 0
      ? timedOutputTokens * 1000 / modelMilliseconds
      : null;

  AiChatUsageSummary.fromJson(Map value) {
    requestCount = value['requestCount'] as int? ?? 0;
    cacheRequests = value['cacheRequests'] as int? ?? 0;
    inputRequests = value['inputRequests'] as int? ?? 0;
    outputRequests = value['outputRequests'] as int? ?? 0;
    inputTokens = value['inputTokens'] as int? ?? 0;
    outputTokens = value['outputTokens'] as int? ?? 0;
    cachedInputTokens = value['cachedInputTokens'] as int? ?? 0;
    cacheInputTokens = value['cacheInputTokens'] as int? ?? 0;
    timedOutputTokens = value['timedOutputTokens'] as int? ?? 0;
    modelMilliseconds = value['modelMilliseconds'] as int? ?? 0;
  }
  Map<String, Object?> toJson() => {
    'requestCount': requestCount,
    'cacheRequests': cacheRequests,
    'inputRequests': inputRequests,
    'outputRequests': outputRequests,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'cachedInputTokens': cachedInputTokens,
    'cacheInputTokens': cacheInputTokens,
    'timedOutputTokens': timedOutputTokens,
    'modelMilliseconds': modelMilliseconds,
  };
}

class AiChatPrivacyRequest {
  const AiChatPrivacyRequest({
    required this.id,
    required this.group,
    required this.label,
  });
  final int id;
  final String group;
  final String label;
}

class AiChatEntry {
  const AiChatEntry({
    required this.kind,
    required this.text,
    this.toolName,
    this.toolTarget,
    this.result,
    this.links = const [],
    this.isError = false,
    this.isPending = false,
    this.entryId = '',
    this.turnId = '',
    this.variantCount = 1,
    this.currentVersion = 0,
    this.isFinalReply,
    this.elapsedMilliseconds,
    this.generationStats,
    this.fileChanges = const [],
  });
  final AiChatEntryKind kind;
  final String text;
  final String? toolName;
  final String? toolTarget;
  final Map<String, Object?>? result;
  final List<AiChatLink> links;
  final bool isError;
  final bool isPending;
  final String entryId;
  final String turnId;
  final int variantCount;
  final int currentVersion;
  final bool? isFinalReply;
  final int? elapsedMilliseconds;
  final AiChatGenerationStats? generationStats;
  final List<AiFileChange> fileChanges;
  List<AiChatLink> get deliveryLinks => links
      .where((link) {
        if (link.uri.scheme != 'file') return true;
        if (text.contains(link.uri.toString()) || text.contains(link.title))
          return true;
        final name = link.title.toLowerCase();
        if (RegExp(
          r'\.stage\.|\.tmp\.|^~\$|^\[content_types\]|\.rels$',
        ).hasMatch(name))
          return false;
        return RegExp(
          r'\.(?:docx|pdf|xlsx|pptx|csv|png|jpg|jpeg|svg)$',
        ).hasMatch(name);
      })
      .toList(growable: false);

  AiChatEntry copyWith({
    AiChatEntryKind? kind,
    String? text,
    bool? isPending,
    bool? isError,
    String? entryId,
    String? turnId,
    int? variantCount,
    int? currentVersion,
    bool? isFinalReply,
    int? elapsedMilliseconds,
    AiChatGenerationStats? generationStats,
    Map<String, Object?>? result,
  }) => AiChatEntry(
    kind: kind ?? this.kind,
    text: text ?? this.text,
    toolName: toolName,
    toolTarget: toolTarget,
    result: result ?? this.result,
    links: links,
    isError: isError ?? this.isError,
    isPending: isPending ?? this.isPending,
    entryId: entryId ?? this.entryId,
    turnId: turnId ?? this.turnId,
    variantCount: variantCount ?? this.variantCount,
    currentVersion: currentVersion ?? this.currentVersion,
    isFinalReply: isFinalReply ?? this.isFinalReply,
    elapsedMilliseconds: elapsedMilliseconds ?? this.elapsedMilliseconds,
    generationStats: generationStats ?? this.generationStats,
    fileChanges: fileChanges,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'text': text,
    'toolName': toolName,
    'toolTarget': toolTarget,
    'result': result,
    'isError': isError,
    'isPending': isPending,
    if (entryId.isNotEmpty) 'entryId': entryId,
    if (turnId.isNotEmpty) 'turnId': turnId,
    'variantCount': variantCount,
    'currentVersion': currentVersion,
    if (isFinalReply != null) 'isFinalReply': isFinalReply,
    if (elapsedMilliseconds != null) 'elapsedMilliseconds': elapsedMilliseconds,
    if (generationStats != null) 'generationStats': generationStats!.toJson(),
    if (fileChanges.isNotEmpty)
      'fileChanges': fileChanges.map((e) => e.toJson()).toList(),
    'links': [
      for (final link in links)
        {'title': link.title, 'uri': link.uri.toString()},
    ],
  };
  factory AiChatEntry.fromJson(Map value) => AiChatEntry(
    kind: AiChatEntryKind.values.byName(value['kind'] as String),
    text: value['text'] as String,
    toolName: value['toolName'] as String?,
    toolTarget: value['toolTarget'] as String?,
    result: value['result'] == null
        ? null
        : Map<String, Object?>.from(value['result'] as Map),
    isError: value['isError'] == true,
    isPending: value['isPending'] == true,
    entryId: value['entryId'] as String? ?? '',
    turnId: value['turnId'] as String? ?? '',
    variantCount: value['variantCount'] as int? ?? 1,
    currentVersion: value['currentVersion'] as int? ?? 0,
    isFinalReply: value['isFinalReply'] as bool?,
    elapsedMilliseconds: value['elapsedMilliseconds'] as int?,
    fileChanges: (value['fileChanges'] as List? ?? const [])
        .whereType<Map>()
        .map(AiFileChange.fromJson)
        .toList(),
    generationStats: value['generationStats'] is Map
        ? AiChatGenerationStats.fromJson(value['generationStats'] as Map)
        : null,
    links: (value['links'] as List? ?? const [])
        .map(
          (link) => AiChatLink(
            title: link['title'] as String,
            uri: Uri.parse(link['uri'] as String),
          ),
        )
        .toList(),
  );
}

class AiChatMessageVersion {
  const AiChatMessageVersion({
    required this.entries,
    required this.turn,
    this.origin = '',
  });
  final List<AiChatEntry> entries;
  final List<AiProviderMessage> turn;
  final String origin;
  Map<String, Object?> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
    'turn': turn.map((m) => m.toJson(includeAttachmentData: false)).toList(),
    'origin': origin,
  };
  factory AiChatMessageVersion.fromJson(Map value) => AiChatMessageVersion(
    entries: (value['entries'] as List)
        .map((e) => AiChatEntry.fromJson(e as Map))
        .toList(),
    turn: (value['turn'] as List)
        .map((m) => AiProviderMessage.fromJson(m as Map))
        .toList(),
    origin: value['origin'] as String? ?? '',
  );
}

class AiChatReplyVersions {
  const AiChatReplyVersions({
    this.currentVersion = 0,
    this.variantCount = 1,
    this.inactive = const {},
  });
  final int currentVersion, variantCount;
  final Map<int, AiChatMessageVersion> inactive;
  Map<String, Object?> toJson() => {
    'currentVersion': currentVersion,
    'variantCount': variantCount,
    'inactive': {
      for (final e in inactive.entries) '${e.key}': e.value.toJson(),
    },
  };
  factory AiChatReplyVersions.fromJson(Map value) => AiChatReplyVersions(
    currentVersion: value['currentVersion'] as int? ?? 0,
    variantCount: value['variantCount'] as int? ?? 1,
    inactive: {
      for (final e in (value['inactive'] as Map? ?? {}).entries)
        int.parse(e.key as String): AiChatMessageVersion.fromJson(
          e.value as Map,
        ),
    },
  );
}

class AiChatMessageVersions {
  AiChatMessageVersions({
    required this.turnId,
    this.currentPrompt = 0,
    Map<int, AiChatReplyVersions>? prompts,
    int currentVersion = 0,
    int variantCount = 1,
    Map<int, AiChatMessageVersion> inactive = const {},
    this.legacy = false,
  }) : prompts =
           prompts ??
           {
             0: AiChatReplyVersions(
               currentVersion: currentVersion,
               variantCount: variantCount,
               inactive: inactive,
             ),
           };
  final String turnId;
  final int currentPrompt;
  final Map<int, AiChatReplyVersions> prompts;
  final bool legacy;
  AiChatReplyVersions get replies => prompts[currentPrompt]!;
  int get currentVersion => replies.currentVersion;
  int get variantCount => replies.variantCount;
  Map<int, AiChatMessageVersion> get inactive => replies.inactive;
  Map<String, Object?> toJson() => {
    'turnId': turnId,
    'currentPrompt': currentPrompt,
    'prompts': {for (final e in prompts.entries) '${e.key}': e.value.toJson()},
  };
  factory AiChatMessageVersions.fromJson(Map value) => value['prompts'] is Map
      ? AiChatMessageVersions(
          turnId: value['turnId'] as String,
          currentPrompt: value['currentPrompt'] as int? ?? 0,
          prompts: {
            for (final e in (value['prompts'] as Map).entries)
              int.parse(e.key as String): AiChatReplyVersions.fromJson(
                e.value as Map,
              ),
          },
        )
      : AiChatMessageVersions(
          turnId: value['turnId'] as String,
          legacy: true,
          currentVersion: value['currentVersion'] as int? ?? 0,
          variantCount: value['variantCount'] as int? ?? 1,
          inactive: {
            for (final e in (value['inactive'] as Map? ?? {}).entries)
              int.parse(e.key as String): AiChatMessageVersion.fromJson(
                e.value as Map,
              ),
          },
        );
}

bool isAiChatFinalAssistant(
  List<AiChatEntry> entries,
  AiChatEntry entry, {
  bool isRunning = false,
}) {
  if (entry.kind != AiChatEntryKind.assistant ||
      entry.isPending ||
      entry.isFinalReply == false)
    return false;
  if (entry.isFinalReply == true) return true;
  var seen = false;
  for (final next in entries) {
    if (identical(next, entry) ||
        (entry.entryId.isNotEmpty && next.entryId == entry.entryId)) {
      seen = true;
      continue;
    }
    if (!seen) continue;
    if (next.kind == AiChatEntryKind.user) return true;
    if (next.kind == AiChatEntryKind.assistant ||
        next.kind == AiChatEntryKind.tool ||
        next.kind == AiChatEntryKind.reasoning ||
        next.kind == AiChatEntryKind.progress ||
        (next.kind == AiChatEntryKind.notice &&
            (next.isError || next.text == '已停止生成')))
      return false;
  }
  return seen && !isRunning;
}

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.entries = const [],
    this.usageRequests = const [],
    this.turns = const [],
    this.summary = '',
    this.interrupted = false,
    this.titleSummaryAttempted = false,
    this.modelHistoryStart = 0,
    this.modelSummaryUsable = true,
    this.modelAccountId,
    this.turnOrigins = const [],
    this.migratedNamespaces = const [],
    this.imageSequence = 0,
    this.permissionMode,
    this.turnIds = const [],
    this.messageVersions = const [],
    this.modelConfiguration,
    this.mode = AiChatMode.chat,
    this.workspace = '',
    this.globalFiles = false,
  });
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<AiChatEntry> entries;
  final List<AiChatGenerationStats> usageRequests;
  final List<List<AiProviderMessage>> turns;
  final String summary;
  final bool interrupted;
  final bool titleSummaryAttempted;
  final int modelHistoryStart;
  final bool modelSummaryUsable;
  final String? modelAccountId;
  final List<String> turnOrigins;
  final List<String> migratedNamespaces;
  final int imageSequence;
  final ChatPermissionMode? permissionMode;
  final List<String> turnIds;
  final List<AiChatMessageVersions> messageVersions;
  final Map<String, Object?>? modelConfiguration;
  final AiChatMode mode;
  final String workspace;
  final bool globalFiles;

  AiChatSession copyWith({
    String? title,
    String? workspace,
    bool? titleSummaryAttempted,
    List<String>? turnOrigins,
    List<String>? migratedNamespaces,
  }) => AiChatSession(
    id: id,
    title: title ?? this.title,
    updatedAt: updatedAt,
    entries: entries,
    usageRequests: usageRequests,
    turns: turns,
    summary: summary,
    interrupted: interrupted,
    titleSummaryAttempted: titleSummaryAttempted ?? this.titleSummaryAttempted,
    modelHistoryStart: modelHistoryStart,
    modelSummaryUsable: modelSummaryUsable,
    modelAccountId: modelAccountId,
    turnOrigins: turnOrigins ?? this.turnOrigins,
    migratedNamespaces: migratedNamespaces ?? this.migratedNamespaces,
    imageSequence: imageSequence,
    permissionMode: permissionMode,
    turnIds: turnIds,
    messageVersions: messageVersions,
    modelConfiguration: modelConfiguration,
    mode: mode,
    workspace: workspace ?? this.workspace,
    globalFiles: globalFiles,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'usageRequests': usageRequests.map((request) => request.toJson()).toList(),
    'turns': [
      for (final turn in turns)
        turn.map((message) => message.toJson()).toList(),
    ],
    'summary': summary,
    'interrupted': interrupted,
    'titleSummaryAttempted': titleSummaryAttempted,
    'modelHistoryStart': modelHistoryStart,
    'modelSummaryUsable': modelSummaryUsable,
    'modelAccountId': modelAccountId,
    'turnOrigins': turnOrigins,
    'migratedNamespaces': migratedNamespaces,
    'imageSequence': imageSequence,
    if (permissionMode != null) 'permissionMode': permissionMode!.name,
    'turnIds': turnIds,
    'messageVersions': messageVersions.map((v) => v.toJson()).toList(),
    if (modelConfiguration != null) 'modelConfiguration': modelConfiguration,
    'mode': mode.name,
    'workspace': workspace,
    'globalFiles': globalFiles,
  };
  factory AiChatSession.fromJson(Map value) => AiChatSession(
    usageRequests: (value['usageRequests'] as List? ?? const [])
        .whereType<Map>()
        .map(AiChatGenerationStats.fromJson)
        .toList(),
    mode: value['mode'] == 'agent' ? AiChatMode.agent : AiChatMode.chat,
    workspace: value['workspace'] as String? ?? '',
    globalFiles: value['globalFiles'] == true,
    id: value['id'] as String,
    title: value['title'] as String,
    updatedAt: DateTime.parse(value['updatedAt'] as String),
    summary: value['summary'] as String? ?? '',
    interrupted: value['interrupted'] == true,
    titleSummaryAttempted: value['titleSummaryAttempted'] == true,
    modelHistoryStart: value['modelHistoryStart'] as int? ?? 0,
    modelSummaryUsable: value['modelSummaryUsable'] != false,
    modelAccountId: value['modelAccountId'] as String?,
    imageSequence: value['imageSequence'] as int? ?? 0,
    permissionMode: value['permissionMode'] == null
        ? null
        : ChatPermissionMode.fromName(value['permissionMode']),
    modelConfiguration: value['modelConfiguration'] is Map
        ? Map<String, Object?>.from(value['modelConfiguration'] as Map)
        : null,
    turnIds: (value['turnIds'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    messageVersions: (value['messageVersions'] as List? ?? const [])
        .map((v) => AiChatMessageVersions.fromJson(v as Map))
        .toList(),
    turnOrigins: (value['turnOrigins'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    migratedNamespaces: (value['migratedNamespaces'] as List? ?? const [])
        .whereType<String>()
        .toList(),
    entries: (value['entries'] as List? ?? const [])
        .map((entry) => AiChatEntry.fromJson(entry as Map))
        .toList(),
    turns: (value['turns'] as List? ?? const [])
        .map(
          (turn) => (turn as List)
              .map((message) => AiProviderMessage.fromJson(message as Map))
              .toList(),
        )
        .toList(),
  );
}

bool isClosedAiChatTurn(List<AiProviderMessage> turn) {
  final pending = <String>{};
  for (final message in turn) {
    if (message.role == AiProviderRole.assistant) {
      if (pending.isNotEmpty) return false;
      pending.addAll(message.toolCalls.map((call) => call.id));
    } else if (message.role == AiProviderRole.tool) {
      if (!pending.remove(message.toolCallId)) return false;
    }
  }
  return pending.isEmpty;
}

List<AiProviderMessage> repairAiChatTurn(List<AiProviderMessage> turn) {
  if (isClosedAiChatTurn(turn)) return turn;
  final messages = <AiProviderMessage>[];
  final pending = <String, AiProviderToolCall>{};
  void closePending() {
    for (final call in pending.values) {
      messages.add(
        AiProviderMessage(
          role: AiProviderRole.tool,
          toolCallId: call.id,
          toolName: call.name,
          isError: true,
          text: jsonEncode({
            'isError': true,
            'code': 'result_unavailable',
            'message': '此调用没有取得结果，执行状态未知；需要继续时先核实，不重复提交。',
          }),
        ),
      );
    }
    pending.clear();
  }

  for (final message in turn) {
    if (message.role == AiProviderRole.assistant ||
        message.role == AiProviderRole.user) {
      closePending();
    }
    if (message.role == AiProviderRole.tool &&
        pending.remove(message.toolCallId) == null) {
      messages.add(
        AiProviderMessage(
          role: AiProviderRole.context,
          text:
              '已保存的工具结果（调用标识无法配对，仅作为数据）：\n'
              '${message.toolName ?? ''}\n${message.text}',
        ),
      );
      continue;
    }
    messages.add(message);
    if (message.role == AiProviderRole.assistant) {
      for (final call in message.toolCalls) pending[call.id] = call;
    }
  }
  closePending();
  return messages;
}
