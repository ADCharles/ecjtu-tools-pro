// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'ai_chat_settings_port.dart';
import 'chat_controller.dart';
import 'provider_models.dart';

class AiChatLocalSettingsAdapter
    implements AiChatSettingsPort, AiChatServicesPort {
  AiChatLocalSettingsAdapter(this.controller);
  final AiChatController controller;
  final _operations = <String, AiChatCancellation>{};

  @override
  Future<AiChatSettingsSnapshot> read() async => AiChatSettingsSnapshot(
    configuration: controller.configuration,
    hasApiKey: controller.configuration.apiKey.isNotEmpty,
    availableModels: controller.availableModels,
    configuredModels: controller.configuredModels,
    services: controller.services,
    supportsServices: controller.supportsServices,
    multiAccountInteractionAvailable:
        controller.multiAccountInteractionAvailable,
  );

  @override
  Future<void> save(
    AiProviderConfig configuration, {
    String? apiKey,
    AiModelCapabilities? modelCapabilities,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
    Map<String, AiModelProfile>? modelProfiles,
  }) async {
    final current = controller.configuration;
    await controller.saveConfiguration(
      current.copyWith(
        serviceId: configuration.serviceId,
        protocol: configuration.protocol,
        baseUrl: configuration.baseUrl,
        model: configuration.model,
        permissionMode: configuration.permissionMode,
        streaming: configuration.streaming,
        contextTokenLimit: configuration.contextTokenLimit,
        autoCompact: configuration.autoCompact,
        autoCompactThreshold: configuration.autoCompactThreshold,
        reasoningEffort: configuration.reasoningEffort,
        supportedReasoningEfforts: configuration.supportedReasoningEfforts,
        privacyProtection: configuration.privacyProtection,
        multiAccountInteraction: configuration.multiAccountInteraction,
        planAndExecute: configuration.planAndExecute,
        reflection: configuration.reflection,
        longTermMemory: configuration.longTermMemory,
      ),
      apiKey: apiKey,
      modelProfile: modelProfile,
      configuredModels: configuredModels,
    );
    if (modelCapabilities != null && modelProfile == null) {
      await controller.saveModelCapabilities(modelCapabilities);
    }
  }

  @override
  Future<AiModelProfile> loadModelProfile(AiProviderConfig configuration) =>
      controller.loadModelProfile(configuration);
  @override
  Future<List<String>> loadConfiguredModels(AiProviderConfig configuration) =>
      controller.loadConfiguredModels(configuration);

  Future<AiProviderConfig> _requestConfig(
    AiProviderConfig draft,
    String? apiKey,
  ) async {
    final value = await controller.resolveServiceDraft(draft, apiKey: apiKey);
    if (value.apiKey.isEmpty) {
      throw const AiProviderException('configuration', '请填写 API 密钥');
    }
    return value;
  }

  @override
  Future<List<String>> fetchModels(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async => controller.fetchModels(
    await _requestConfig(configuration, apiKey),
    cancellation: cancellation,
  );

  @override
  Future<AiConnectionTestResult> testConnection(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async => controller.testConnection(
    await _requestConfig(configuration, apiKey),
    cancellation: cancellation,
  );

  @override
  Future<AiConversationTestResult> testConversation(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async => controller.testConversation(
    await _requestConfig(configuration, apiKey),
    cancellation: cancellation,
  );

  @override
  Future<String> loadAgentInstructions() async {
    final text = await controller.loadAgentInstructions(refresh: true);
    if (controller.agentInstructionsError case final error?) {
      throw AiProviderException('agent_read', error);
    }
    return text;
  }

  @override
  Future<void> saveAgentInstructions(String text) =>
      controller.saveAgentInstructions(text);

  @override
  Future<void> saveService(
    String name,
    AiProviderConfig configuration, {
    String? apiKey,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
    Map<String, AiModelProfile>? modelProfiles,
  }) => controller.saveService(
    name,
    configuration,
    apiKey: apiKey,
    modelProfile: modelProfile,
    configuredModels: configuredModels,
    modelProfiles: modelProfiles,
  );
  @override
  Future<void> deleteService(String id) => controller.deleteService(id);
  @override
  Future<void> selectService(String id) => controller.selectService(id);
  @override
  Future<List<String>> loadCachedModels(AiProviderConfig configuration) =>
      controller.loadCachedModels(configuration);

  /// Called by the owning window's typed settings-intent binding.
  Future<Map<String, Object?>> handle(AiChatSettingsRequest request) async {
    final args = request.arguments;
    String? id;
    AiChatCancellation? registered;
    try {
      request.validate();
      Object? value;
      switch (request.command) {
        case AiChatSettingsCommand.read:
          value = (await read()).toMap();
        case AiChatSettingsCommand.save:
        case AiChatSettingsCommand.serviceSave:
          if (request.command == AiChatSettingsCommand.serviceSave) {
            await saveService(
              args['name'] as String,
              aiSettingsConfigFromMap(args['configuration'] as Map),
              apiKey: args['apiKey'] as String?,
              modelProfile: args['modelProfile'] is Map
                  ? aiSettingsProfileFromMap(args['modelProfile'] as Map)
                  : null,
              configuredModels: args['configuredModels'] == null
                  ? null
                  : aiSettingsConfiguredModels(args['configuredModels']),
              modelProfiles: args['modelProfiles'] == null
                  ? null
                  : aiSettingsProfiles(args['modelProfiles']),
            );
            break;
          }
          await save(
            aiSettingsConfigFromMap(args['configuration'] as Map),
            apiKey: args['apiKey'] as String?,
            modelCapabilities: args['modelCapabilities'] is Map
                ? AiModelCapabilities.fromJson(args['modelCapabilities'] as Map)
                : null,
            modelProfile: args['modelProfile'] is Map
                ? aiSettingsProfileFromMap(args['modelProfile'] as Map)
                : null,
            configuredModels: args['configuredModels'] == null
                ? null
                : aiSettingsConfiguredModels(args['configuredModels']),
          );
        case AiChatSettingsCommand.serviceDelete:
          await deleteService(args['serviceId'] as String);
        case AiChatSettingsCommand.serviceSelect:
          await selectService(args['serviceId'] as String);
        case AiChatSettingsCommand.modelProfile:
          value = (await loadModelProfile(
            aiSettingsConfigFromMap(args['configuration'] as Map),
          )).toJson();
        case AiChatSettingsCommand.configuredModels:
          value = await loadConfiguredModels(
            aiSettingsConfigFromMap(args['configuration'] as Map),
          );
        case AiChatSettingsCommand.cachedModels:
          value = await loadCachedModels(
            aiSettingsConfigFromMap(args['configuration'] as Map),
          );
        case AiChatSettingsCommand.models:
        case AiChatSettingsCommand.testConnection:
        case AiChatSettingsCommand.testConversation:
          id = args['operationId'] as String;
          if (id.isEmpty ||
              _operations.containsKey(id) ||
              _operations.length >= 4) {
            throw const AiProviderException('settings_request', '设置操作无效');
          }
          final cancellation = AiChatCancellation();
          _operations[id] = cancellation;
          registered = cancellation;
          final config = aiSettingsConfigFromMap(args['configuration'] as Map);
          final key = args['apiKey'] as String?;
          if (request.command == AiChatSettingsCommand.models) {
            value = await fetchModels(
              config,
              apiKey: key,
              cancellation: cancellation,
            );
          } else if (request.command == AiChatSettingsCommand.testConnection) {
            final result = await testConnection(
              config,
              apiKey: key,
              cancellation: cancellation,
            );
            value = {
              'model': result.model,
              'latencyMs': result.latency.inMilliseconds,
            };
          } else {
            final result = await testConversation(
              config,
              apiKey: key,
              cancellation: cancellation,
            );
            value = {
              'text': result.text,
              'latencyMs': result.latency.inMilliseconds,
            };
          }
        case AiChatSettingsCommand.cancel:
          _operations[args['operationId']]?.cancel();
        case AiChatSettingsCommand.agentRead:
          value = await loadAgentInstructions();
        case AiChatSettingsCommand.agentSave:
          await saveAgentInstructions(args['text'] as String);
      }
      return {'ok': true, 'value': value};
    } on AiProviderException catch (error) {
      var message = controller.configuration.redact(error.message);
      final key = args['apiKey'];
      if (key is String && key.isNotEmpty) {
        message = message.replaceAll(key, '[密钥已隐藏]');
      }
      return {'ok': false, 'code': error.code, 'message': message};
    } catch (_) {
      return {
        'ok': false,
        'code': 'settings_request',
        'message': '设置操作未完成，请重试',
      };
    } finally {
      if (id != null && identical(_operations[id], registered)) {
        _operations.remove(id);
      }
    }
  }

  void cancelPending() {
    for (final operation in _operations.values) {
      operation.cancel();
    }
  }
}
