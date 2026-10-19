// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'attachment_models.dart';
import 'chat_permission_store.dart';

export 'chat_permission_store.dart'
    show ChatPermissionMode, ChatPermissionStore, ChatPermissionScope;

enum AiProviderProtocol {
  chatCompletions('OpenAI Chat Completions', '/chat/completions'),
  responses('OpenAI Responses', '/responses'),
  anthropicMessages('Anthropic Messages', '/messages');

  const AiProviderProtocol(this.label, this.path);
  final String label;
  final String path;
}

enum AiReasoningEffort {
  off('关闭'),
  low('低'),
  medium('中'),
  high('高'),
  xhigh('更高'),
  max('最高');

  const AiReasoningEffort(this.label);
  final String label;
}

List<AiReasoningEffort> aiReasoningLevelsFromJson(
  Object? value, {
  List<AiReasoningEffort> fallback = AiReasoningEffort.values,
}) {
  if (value is! List) return fallback;
  final levels = AiReasoningEffort.values
      .where(
        (effort) =>
            value.contains(effort.name) ||
            (effort == AiReasoningEffort.xhigh && value.contains('xigh')),
      )
      .toList();
  return levels.isEmpty ? fallback : List.unmodifiable(levels);
}

class AiProviderConfig {
  static const minContextTokenLimit = 2048;
  static const maxContextTokenLimit = 67108864;

  const AiProviderConfig({
    this.serviceId = '',
    this.protocol = AiProviderProtocol.chatCompletions,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = '',
    this.apiKey = '',
    this.permissionMode = ChatPermissionMode.askChanges,
    this.streaming = false,
    this.contextTokenLimit = 16384,
    this.autoCompact = true,
    this.autoCompactThreshold = 80,
    this.reasoningEffort = AiReasoningEffort.off,
    this.supportedReasoningEfforts = AiReasoningEffort.values,
    this.privacyProtection = true,
    this.multiAccountInteraction = false,
    this.planAndExecute = false,
    this.reflection = false,
    this.longTermMemory = false,
    this.modelCapabilities = const AiModelCapabilities(),
  });

  final AiProviderProtocol protocol;
  final String serviceId;
  final String baseUrl;
  final String model;
  final String apiKey;
  final ChatPermissionMode permissionMode;
  final bool streaming;
  final int contextTokenLimit;
  final bool autoCompact;
  final int autoCompactThreshold;
  final AiReasoningEffort reasoningEffort;
  final List<AiReasoningEffort> supportedReasoningEfforts;
  final bool privacyProtection;
  final bool multiAccountInteraction;
  final bool planAndExecute, reflection, longTermMemory;
  final AiModelCapabilities modelCapabilities;

  Uri get endpoint {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const AiProviderException('configuration', '请填写有效的 API 基础地址');
    }
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (!path.endsWith(protocol.path)) path += protocol.path;
    return uri.replace(path: path);
  }

  void validate({bool requireKey = true, bool requireModel = true}) {
    if (serviceId.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(serviceId)) {
      throw const AiProviderException('configuration', '服务配置无效');
    }
    endpoint;
    if (autoCompactThreshold < 50 || autoCompactThreshold > 95) {
      throw const AiProviderException('configuration', '自动压缩阈值请设为 50 至 95');
    }
    if (contextTokenLimit < minContextTokenLimit ||
        contextTokenLimit > maxContextTokenLimit) {
      throw const AiProviderException(
        'configuration',
        '上下文上限请设为 $minContextTokenLimit 至 $maxContextTokenLimit',
      );
    }
    if (requireModel && model.trim().isEmpty) {
      throw const AiProviderException('configuration', '请填写模型名称');
    }
    if (requireKey && apiKey.trim().isEmpty) {
      throw const AiProviderException('configuration', '请先在设置中保存 API 密钥');
    }
  }

  AiProviderConfig copyWith({
    String? serviceId,
    AiProviderProtocol? protocol,
    String? baseUrl,
    String? model,
    String? apiKey,
    ChatPermissionMode? permissionMode,
    bool? streaming,
    int? contextTokenLimit,
    bool? autoCompact,
    int? autoCompactThreshold,
    AiReasoningEffort? reasoningEffort,
    List<AiReasoningEffort>? supportedReasoningEfforts,
    bool? privacyProtection,
    bool? multiAccountInteraction,
    bool? planAndExecute,
    bool? reflection,
    bool? longTermMemory,
    AiModelCapabilities? modelCapabilities,
  }) => AiProviderConfig(
    serviceId: serviceId ?? this.serviceId,
    protocol: protocol ?? this.protocol,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    apiKey: apiKey ?? this.apiKey,
    permissionMode: permissionMode ?? this.permissionMode,
    streaming: streaming ?? this.streaming,
    contextTokenLimit: contextTokenLimit ?? this.contextTokenLimit,
    autoCompact: autoCompact ?? this.autoCompact,
    autoCompactThreshold: autoCompactThreshold ?? this.autoCompactThreshold,
    reasoningEffort: reasoningEffort ?? this.reasoningEffort,
    supportedReasoningEfforts:
        supportedReasoningEfforts ?? this.supportedReasoningEfforts,
    privacyProtection: privacyProtection ?? this.privacyProtection,
    multiAccountInteraction:
        multiAccountInteraction ?? this.multiAccountInteraction,
    planAndExecute: planAndExecute ?? this.planAndExecute,
    reflection: reflection ?? this.reflection,
    longTermMemory: longTermMemory ?? this.longTermMemory,
    modelCapabilities: modelCapabilities ?? this.modelCapabilities,
  );

  AiProviderConfig withKey(String key) => copyWith(
    baseUrl: baseUrl.trim(),
    model: model.trim(),
    apiKey: key.trim(),
  );

  Map<String, Object?> toPreferences() => {
    if (serviceId.isNotEmpty) 'serviceId': serviceId,
    'protocol': protocol.name,
    'baseUrl': baseUrl.trim(),
    'model': model.trim(),
    'streaming': streaming,
    'contextTokenLimit': contextTokenLimit,
    'autoCompact': autoCompact,
    'autoCompactThreshold': autoCompactThreshold,
    'reasoningEffort': reasoningEffort.name,
    'supportedReasoningEfforts': [
      for (final effort in supportedReasoningEfforts) effort.name,
    ],
    'privacyProtection': privacyProtection,
    'multiAccountInteraction': multiAccountInteraction,
    'planAndExecute': planAndExecute,
    'reflection': reflection,
    'longTermMemory': longTermMemory,
    'modelCapabilities': modelCapabilities.toJson(),
  };

  factory AiProviderConfig.fromPreferences(
    Map value, {
    ChatPermissionMode permissionMode = ChatPermissionMode.askChanges,
  }) => AiProviderConfig(
    serviceId: value['serviceId'] as String? ?? '',
    protocol:
        AiProviderProtocol.values
            .where((v) => v.name == value['protocol'])
            .firstOrNull ??
        AiProviderProtocol.chatCompletions,
    baseUrl: value['baseUrl'] as String? ?? 'https://api.openai.com/v1',
    model: value['model'] as String? ?? '',
    permissionMode: permissionMode,
    streaming: value['streaming'] == true,
    supportedReasoningEfforts: aiReasoningLevelsFromJson(
      value['supportedReasoningEfforts'],
    ),
    autoCompact: value['autoCompact'] != false,
    privacyProtection: value['privacyProtection'] != false,
    multiAccountInteraction: value['multiAccountInteraction'] == true,
    planAndExecute: value['planAndExecute'] == true,
    reflection: value['reflection'] == true,
    longTermMemory: value['longTermMemory'] == true,
    reasoningEffort:
        AiReasoningEffort.values
            .where(
              (v) =>
                  v.name ==
                  (value['reasoningEffort'] == 'xigh'
                      ? 'xhigh'
                      : value['reasoningEffort']),
            )
            .firstOrNull ??
        AiReasoningEffort.off,
    autoCompactThreshold: (value['autoCompactThreshold'] as int? ?? 80).clamp(
      50,
      95,
    ),
    contextTokenLimit: (value['contextTokenLimit'] as int? ?? 16384).clamp(
      minContextTokenLimit,
      maxContextTokenLimit,
    ),
    modelCapabilities: value['modelCapabilities'] is Map
        ? AiModelCapabilities.fromJson(value['modelCapabilities'] as Map)
        : const AiModelCapabilities(),
  );

  String redact(String text) =>
      apiKey.isEmpty ? text : text.replaceAll(apiKey, '[密钥已隐藏]');

  @override
  String toString() => 'AiProviderConfig(${protocol.name}, key: [hidden])';
}

class AiProviderException implements Exception {
  const AiProviderException(this.code, this.message, {this.retryAfter});
  final String code;
  final String message;
  final Duration? retryAfter;

  @override
  String toString() => message;
}

class AiChatCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get signal => _cancelled.future;

  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }

  void check() {
    if (isCancelled) {
      throw const AiProviderException('cancelled', '已停止生成');
    }
  }

  Future<T> race<T>(Future<T> operation, {required Duration timeout}) async {
    check();
    return Future.any<T>([
      operation,
      signal.then<T>(
        (_) => throw const AiProviderException('cancelled', '已停止生成'),
      ),
    ]).timeout(
      timeout,
      onTimeout: () =>
          throw const AiProviderException('timeout', '等待超时，请查看当前结果后再继续'),
    );
  }
}

class AiProviderToolCall {
  const AiProviderToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
  final String id;
  final String name;
  final String arguments;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments,
  };
  factory AiProviderToolCall.fromJson(Map value) => AiProviderToolCall(
    id: value['id'] as String,
    name: value['name'] as String,
    arguments: value['arguments'] as String,
  );
}

class AiProviderToolProgress {
  const AiProviderToolProgress({required this.id, required this.name});
  final String id, name;
}

enum AiProviderRole { user, assistant, tool, context }

class AiProviderMessage {
  const AiProviderMessage({
    required this.role,
    this.text = '',
    this.toolCalls = const [],
    this.toolCallId,
    this.toolName,
    this.isError = false,
    this.responsesOutput = const [],
    this.reasoning = '',
    this.anthropicThinking = const [],
    this.attachments = const [],
  });
  final AiProviderRole role;
  final String text;
  final List<AiProviderToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;
  final bool isError;

  // Responses reasoning items must accompany their function calls on replay.
  final List<Map<String, Object?>> responsesOutput;
  final String reasoning;
  final List<Map<String, Object?>> anthropicThinking;
  final List<AiChatAttachment> attachments;

  Map<String, Object?> toJson({bool includeAttachmentData = true}) => {
    'role': role.name,
    'text': text,
    'toolCalls': toolCalls.map((call) => call.toJson()).toList(),
    'toolCallId': toolCallId,
    'toolName': toolName,
    'isError': isError,
    'responsesOutput': responsesOutput,
    'reasoning': reasoning,
    'anthropicThinking': anthropicThinking,
    if (attachments.isNotEmpty)
      'attachments': attachments
          .map((a) => a.toJson(includeData: includeAttachmentData))
          .toList(),
  };

  factory AiProviderMessage.fromJson(Map value) => AiProviderMessage(
    role: AiProviderRole.values.byName(value['role'] as String),
    text: value['text'] as String? ?? '',
    toolCalls: (value['toolCalls'] as List? ?? const [])
        .map((call) => AiProviderToolCall.fromJson(call as Map))
        .toList(),
    toolCallId: value['toolCallId'] as String?,
    toolName: value['toolName'] as String?,
    isError: value['isError'] == true,
    responsesOutput: (value['responsesOutput'] as List? ?? const [])
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList(),
    reasoning: value['reasoning'] as String? ?? '',
    anthropicThinking: (value['anthropicThinking'] as List? ?? const [])
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList(),
    attachments: (value['attachments'] as List? ?? const [])
        .map((item) => AiChatAttachment.fromJson(item as Map))
        .toList(),
  );
}

class AiProviderUsage {
  const AiProviderUsage({
    this.inputTokens,
    this.outputTokens,
    this.cachedInputTokens,
  });
  final int? inputTokens;
  final int? outputTokens;
  final int? cachedInputTokens;
}

class AiConnectionTestResult {
  const AiConnectionTestResult({required this.model, required this.latency});
  final String model;
  final Duration latency;
}

class AiConversationTestResult {
  const AiConversationTestResult({required this.text, required this.latency});
  final String text;
  final Duration latency;
}

int estimateAiTokens(String text) {
  var dense = 0;
  var other = 0;
  for (final rune in text.runes) {
    if (rune >= 0x2e80) {
      dense++;
    } else {
      other++;
    }
  }
  return dense + (other / 4).ceil();
}

class AiProviderReply {
  const AiProviderReply({
    this.text = '',
    this.toolCalls = const [],
    this.responsesOutput = const [],
    this.usage = const AiProviderUsage(),
    this.reasoning = '',
    this.anthropicThinking = const [],
  });
  final String text;
  final List<AiProviderToolCall> toolCalls;
  final List<Map<String, Object?>> responsesOutput;
  final AiProviderUsage usage;
  final String reasoning;
  final List<Map<String, Object?>> anthropicThinking;

  AiProviderMessage toMessage() => AiProviderMessage(
    role: AiProviderRole.assistant,
    text: text,
    toolCalls: toolCalls,
    responsesOutput: responsesOutput,
    reasoning: reasoning,
    anthropicThinking: anthropicThinking,
  );
}
