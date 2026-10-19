// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'provider_models.dart';
import 'attachment_models.dart';
import 'provider_model_profile.dart';
import 'provider_services.dart';

export 'provider_model_profile.dart';
export 'provider_services.dart';

enum AiChatSettingsCommand {
  read,
  save,
  models,
  testConnection,
  testConversation,
  cancel,
  agentRead,
  agentSave,
  modelProfile,
  configuredModels,
  serviceSave,
  serviceDelete,
  serviceSelect,
  cachedModels,
}

class AiChatSettingsRequest {
  const AiChatSettingsRequest(this.command, [this.arguments = const {}]);
  final AiChatSettingsCommand command;
  final Map<String, Object?> arguments;

  void validate() {
    final allowed = switch (command) {
      AiChatSettingsCommand.read ||
      AiChatSettingsCommand.agentRead => <String>{},
      AiChatSettingsCommand.save || AiChatSettingsCommand.serviceSave => {
        'configuration',
        'apiKey',
        'modelCapabilities',
        'modelProfile',
        'configuredModels',
        if (command == AiChatSettingsCommand.serviceSave) ...[
          'name',
          'modelProfiles',
        ],
      },
      AiChatSettingsCommand.serviceDelete ||
      AiChatSettingsCommand.serviceSelect => {'serviceId'},
      AiChatSettingsCommand.models ||
      AiChatSettingsCommand.testConnection ||
      AiChatSettingsCommand.testConversation => {
        'configuration',
        'apiKey',
        'operationId',
      },
      AiChatSettingsCommand.cancel => {'operationId'},
      AiChatSettingsCommand.agentSave => {'text'},
      AiChatSettingsCommand.modelProfile ||
      AiChatSettingsCommand.configuredModels ||
      AiChatSettingsCommand.cachedModels => {'configuration'},
    };
    if (arguments.keys.any((key) => !allowed.contains(key))) _invalid();
    if (command == AiChatSettingsCommand.serviceSave) {
      final name = arguments['name'];
      if (name is! String || name.trim().isEmpty || name.length > 80)
        _invalid();
    }
    if (command == AiChatSettingsCommand.serviceDelete ||
        command == AiChatSettingsCommand.serviceSelect) {
      final id = arguments['serviceId'];
      if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id))
        _invalid();
    }
    final key = arguments['apiKey'];
    if (key != null && (key is! String || key.length > 8192)) _invalid();
    if (command == AiChatSettingsCommand.save ||
        command == AiChatSettingsCommand.serviceSave ||
        command == AiChatSettingsCommand.models ||
        command == AiChatSettingsCommand.testConnection ||
        command == AiChatSettingsCommand.testConversation ||
        command == AiChatSettingsCommand.modelProfile ||
        command == AiChatSettingsCommand.cachedModels ||
        command == AiChatSettingsCommand.configuredModels) {
      final config = arguments['configuration'];
      if (config is! Map) _invalid();
      aiSettingsConfigFromMap(config);
    }
    if (arguments['modelProfiles'] != null)
      aiSettingsProfiles(arguments['modelProfiles']);
    if (arguments['modelCapabilities'] != null) {
      _capabilities(arguments['modelCapabilities']);
    }
    if (arguments['modelProfile'] != null) {
      final value = arguments['modelProfile'];
      if (value is! Map) _invalid();
      aiSettingsProfileFromMap(value);
    }
    if (arguments['configuredModels'] != null) {
      aiSettingsConfiguredModels(arguments['configuredModels']);
    }
    if (command == AiChatSettingsCommand.models ||
        command == AiChatSettingsCommand.testConnection ||
        command == AiChatSettingsCommand.testConversation ||
        command == AiChatSettingsCommand.cancel) {
      final id = arguments['operationId'];
      if (id is! String ||
          id.isEmpty ||
          id.length > 96 ||
          !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
        _invalid();
      }
    }
    if (command == AiChatSettingsCommand.agentSave) {
      final text = arguments['text'];
      if (text is! String || text.length > 8192) _invalid();
    }
  }

  Map<String, Object?> toMap() => {
    'command': command.name,
    'arguments': arguments,
  };

  factory AiChatSettingsRequest.fromMap(Map value) {
    final command = AiChatSettingsCommand.values
        .where((item) => item.name == value['command'])
        .firstOrNull;
    final arguments = value['arguments'];
    if (command == null ||
        arguments is! Map ||
        value.keys.any((key) => key != 'command' && key != 'arguments') ||
        arguments.keys.any((key) => key is! String)) {
      throw const AiProviderException('settings_request', '设置操作无效');
    }
    final request = AiChatSettingsRequest(
      command,
      Map<String, Object?>.from(arguments),
    );
    request.validate();
    return request;
  }
}

Map<String, Object?> aiSettingsConfigToMap(AiProviderConfig config) => {
  ...config.toPreferences(),
  'permissionMode': config.permissionMode.name,
  'modelCapabilities': config.modelCapabilities.toJson(),
};

AiModelProfile aiSettingsProfileFromMap(Map value) {
  const keys = {
    'contextTokenLimit',
    'reasoningEffort',
    'supportedReasoningEfforts',
    'visionEnabled',
    'pdfEnabled',
  };
  if ((value.length != keys.length && value.length != keys.length - 1) ||
      value.keys.any((key) => !keys.contains(key)) ||
      value['contextTokenLimit'] is! int ||
      value['visionEnabled'] is! bool ||
      value['pdfEnabled'] is! bool ||
      !AiReasoningEffort.values.any(
        (effort) => effort.name == value['reasoningEffort'],
      )) {
    _invalid();
  }
  final limit = value['contextTokenLimit'] as int;
  if (limit < AiProviderConfig.minContextTokenLimit ||
      limit > AiProviderConfig.maxContextTokenLimit) {
    _invalid();
  }
  _reasoningLevels(value);
  return AiModelProfile.fromJson(value);
}

void _reasoningLevels(Map value) {
  if (!value.containsKey('supportedReasoningEfforts')) return;
  final levels = value['supportedReasoningEfforts'];
  if (levels is! List ||
      levels.isEmpty ||
      levels.length > AiReasoningEffort.values.length ||
      levels.toSet().length != levels.length ||
      levels.any(
        (name) =>
            !AiReasoningEffort.values.any((effort) => effort.name == name),
      ) ||
      !levels.contains(value['reasoningEffort']))
    _invalid();
}

Never _invalid() =>
    throw const AiProviderException('settings_request', '设置操作无效');
List<String> aiSettingsConfiguredModels(Object? value) {
  if (value is! List ||
      value.length > 128 ||
      value.any(
        (model) =>
            model is! String || model.trim().isEmpty || model.length > 256,
      )) {
    _invalid();
  }
  return List<String>.from(value);
}

Map<String, AiModelProfile> aiSettingsProfiles(Object? value) {
  if (value is! Map ||
      value.length > 128 ||
      value.keys.any((k) => k is! String || k.isEmpty || k.length > 256) ||
      value.values.any((v) => v is! Map))
    _invalid();
  return {
    for (final e in value.entries)
      e.key as String: aiSettingsProfileFromMap(e.value as Map),
  };
}

AiModelCapabilities _capabilities(Object? value) {
  if (value is! Map ||
      value.length != 2 ||
      value['visionEnabled'] is! bool ||
      value['pdfEnabled'] is! bool) {
    _invalid();
  }
  return AiModelCapabilities.fromJson(value);
}

AiProviderConfig aiSettingsConfigFromMap(Map value) {
  const keys = {
    'serviceId',
    'protocol',
    'baseUrl',
    'model',
    'permissionMode',
    'streaming',
    'contextTokenLimit',
    'autoCompact',
    'autoCompactThreshold',
    'reasoningEffort',
    'supportedReasoningEfforts',
    'privacyProtection',
    'multiAccountInteraction',
    'modelCapabilities',
    'planAndExecute',
    'reflection',
    'longTermMemory',
  };
  if (value.keys.any((key) => !keys.contains(key))) _invalid();
  for (final name in ['planAndExecute', 'reflection', 'longTermMemory']) {
    if (value.containsKey(name) && value[name] is! bool) _invalid();
  }
  if (value.containsKey('serviceId') &&
      (value['serviceId'] is! String ||
          !RegExp(
            r'^[a-zA-Z0-9_-]{0,64}$',
          ).hasMatch(value['serviceId'] as String)))
    _invalid();
  for (final name in [
    'streaming',
    'autoCompact',
    'privacyProtection',
    'multiAccountInteraction',
  ]) {
    if (value[name] is! bool) _invalid();
  }
  if (value['baseUrl'] is! String ||
      (value['baseUrl'] as String).length > 4096 ||
      value['model'] is! String ||
      (value['model'] as String).length > 256 ||
      value['contextTokenLimit'] is! int ||
      value['autoCompactThreshold'] is! int ||
      !AiProviderProtocol.values.any(
        (item) => item.name == value['protocol'],
      ) ||
      !ChatPermissionMode.values.any(
        (item) => item.name == value['permissionMode'],
      ) ||
      !AiReasoningEffort.values.any(
        (item) => item.name == value['reasoningEffort'],
      )) {
    _invalid();
  }
  _reasoningLevels(value);
  final config = AiProviderConfig(
    serviceId: value['serviceId'] as String? ?? '',
    protocol: AiProviderProtocol.values.byName(value['protocol'] as String),
    baseUrl: value['baseUrl'] as String,
    model: value['model'] as String,
    permissionMode: ChatPermissionMode.values.byName(
      value['permissionMode'] as String,
    ),
    streaming: value['streaming'] as bool,
    contextTokenLimit: value['contextTokenLimit'] as int,
    autoCompact: value['autoCompact'] as bool,
    autoCompactThreshold: value['autoCompactThreshold'] as int,
    reasoningEffort: AiReasoningEffort.values.byName(
      value['reasoningEffort'] as String,
    ),
    supportedReasoningEfforts: aiReasoningLevelsFromJson(
      value['supportedReasoningEfforts'],
    ),
    privacyProtection: value['privacyProtection'] as bool,
    multiAccountInteraction: value['multiAccountInteraction'] as bool,
    planAndExecute: value['planAndExecute'] == true,
    reflection: value['reflection'] == true,
    longTermMemory: value['longTermMemory'] == true,
    modelCapabilities: value.containsKey('modelCapabilities')
        ? _capabilities(value['modelCapabilities'])
        : const AiModelCapabilities(),
  );
  config.validate(requireKey: false, requireModel: false);
  return config;
}

class AiChatSettingsSnapshot {
  AiChatSettingsSnapshot({
    required AiProviderConfig configuration,
    required this.hasApiKey,
    required this.availableModels,
    required this.multiAccountInteractionAvailable,
    this.configuredModels = const [],
    this.services = const [],
    this.supportsServices = false,
  }) : configuration = configuration.withKey('');

  final AiProviderConfig configuration;
  final bool hasApiKey;
  final List<String> availableModels;
  final List<String> configuredModels;
  final bool multiAccountInteractionAvailable;
  final List<AiProviderService> services;
  final bool supportsServices;

  Map<String, Object?> toMap() => {
    'configuration': aiSettingsConfigToMap(configuration),
    'hasApiKey': hasApiKey,
    'availableModels': availableModels,
    'configuredModels': configuredModels,
    'multiAccountInteractionAvailable': multiAccountInteractionAvailable,
    'services': services.map((s) => s.toJson()).toList(),
    'supportsServices': supportsServices,
  };

  factory AiChatSettingsSnapshot.fromMap(Map value) => AiChatSettingsSnapshot(
    configuration: aiSettingsConfigFromMap(value['configuration'] as Map),
    hasApiKey: value['hasApiKey'] as bool,
    availableModels: List<String>.from(value['availableModels'] as List),
    configuredModels: aiSettingsConfiguredModels(
      value['configuredModels'] ?? const [],
    ),
    multiAccountInteractionAvailable:
        value['multiAccountInteractionAvailable'] as bool,
    services: (value['services'] as List? ?? const [])
        .take(32)
        .map((s) => AiProviderService.fromJson(s as Map))
        .toList(),
    supportsServices: value['supportsServices'] == true,
  );
}

abstract interface class AiChatServicesPort {
  Future<List<String>> loadCachedModels(AiProviderConfig configuration);
  Future<void> saveService(
    String name,
    AiProviderConfig configuration, {
    String? apiKey,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
    Map<String, AiModelProfile>? modelProfiles,
  });
  Future<void> deleteService(String id);
  Future<void> selectService(String id);
}

abstract interface class AiChatSettingsPort {
  Future<AiChatSettingsSnapshot> read();
  Future<void> save(
    AiProviderConfig configuration, {
    String? apiKey,
    AiModelCapabilities? modelCapabilities,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
  });
  Future<AiModelProfile> loadModelProfile(AiProviderConfig configuration);
  Future<List<String>> loadConfiguredModels(AiProviderConfig configuration);
  Future<List<String>> fetchModels(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  });
  Future<AiConnectionTestResult> testConnection(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  });
  Future<AiConversationTestResult> testConversation(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  });
  Future<String> loadAgentInstructions();
  Future<void> saveAgentInstructions(String text);
}
