// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'package:flutter/services.dart';

import '../../platform/ai_chat_window_host.dart';
import 'ai_chat_settings_port.dart';
import 'provider_models.dart';
import 'attachment_models.dart';

typedef AiChatSettingsTransport =
    Future<Object?> Function(AiChatSettingsRequest);

class AiChatRemoteSettingsAdapter
    implements AiChatSettingsPort, AiChatServicesPort {
  AiChatRemoteSettingsAdapter(this.transport);
  factory AiChatRemoteSettingsAdapter.forClient(AiChatWindowClient client) =>
      AiChatRemoteSettingsAdapter((request) {
        final operation = AiChatWindowOperation.values
            .where((value) => value.name == 'settings')
            .firstOrNull;
        if (operation == null) {
          throw const AiProviderException(
            'settings_unavailable',
            '设置暂时无法连接，请重试',
          );
        }
        return client.invoke(
          AiChatWindowIntent(
            operation: operation,
            conversationId: client.state['conversationId'] as String?,
            arguments: request.toMap(),
          ),
        );
      });

  final AiChatSettingsTransport transport;
  int _sequence = 0;
  final String _prefix = DateTime.now().microsecondsSinceEpoch.toString();

  Future<Object?> _call(AiChatSettingsRequest request) async {
    try {
      final result = await transport(request);
      if (result is! Map) {
        throw const AiProviderException('settings_unavailable', '设置暂时无法连接，请重试');
      }
      if (result['ok'] != true) {
        throw AiProviderException(
          result['code'] as String? ?? 'settings_request',
          result['message'] as String? ?? '设置操作未完成，请重试',
        );
      }
      return result['value'];
    } on PlatformException catch (error) {
      throw AiProviderException(error.code, error.message ?? '设置操作未完成，请重试');
    }
  }

  @override
  Future<AiChatSettingsSnapshot> read() async => AiChatSettingsSnapshot.fromMap(
    await _call(const AiChatSettingsRequest(AiChatSettingsCommand.read)) as Map,
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
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.save, {
        'configuration': aiSettingsConfigToMap(configuration),
        'apiKey': apiKey,
        if (modelCapabilities != null)
          'modelCapabilities': modelCapabilities.toJson(),
        if (modelProfile != null) 'modelProfile': modelProfile.toJson(),
        'configuredModels': ?configuredModels,
      }),
    );
  }

  @override
  Future<List<String>> loadConfiguredModels(
    AiProviderConfig configuration,
  ) async => aiSettingsConfiguredModels(
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.configuredModels, {
        'configuration': aiSettingsConfigToMap(configuration),
      }),
    ),
  );

  @override
  Future<AiModelProfile> loadModelProfile(
    AiProviderConfig configuration,
  ) async => aiSettingsProfileFromMap(
    await _call(
          AiChatSettingsRequest(AiChatSettingsCommand.modelProfile, {
            'configuration': aiSettingsConfigToMap(configuration),
          }),
        )
        as Map,
  );

  Future<Object?> _cancellable(
    AiChatSettingsCommand command,
    AiProviderConfig config,
    String? apiKey,
    AiChatCancellation cancellation,
  ) async {
    cancellation.check();
    final id = '$_prefix-${++_sequence}';
    var finished = false;
    unawaited(
      cancellation.signal.then((_) async {
        if (!finished) {
          try {
            await _call(
              AiChatSettingsRequest(AiChatSettingsCommand.cancel, {
                'operationId': id,
              }),
            );
          } catch (_) {
            /* The owner may already have closed the window. */
          }
        }
      }),
    );
    try {
      final value = await _call(
        AiChatSettingsRequest(command, {
          'operationId': id,
          'configuration': aiSettingsConfigToMap(config),
          'apiKey': apiKey,
        }),
      );
      cancellation.check();
      return value;
    } finally {
      finished = true;
    }
  }

  @override
  Future<List<String>> fetchModels(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async => List<String>.from(
    await _cancellable(
          AiChatSettingsCommand.models,
          configuration,
          apiKey,
          cancellation,
        )
        as List,
  );

  @override
  Future<AiConnectionTestResult> testConnection(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async {
    final result =
        await _cancellable(
              AiChatSettingsCommand.testConnection,
              configuration,
              apiKey,
              cancellation,
            )
            as Map;
    return AiConnectionTestResult(
      model: result['model'] as String,
      latency: Duration(milliseconds: result['latencyMs'] as int),
    );
  }

  @override
  Future<AiConversationTestResult> testConversation(
    AiProviderConfig configuration, {
    String? apiKey,
    required AiChatCancellation cancellation,
  }) async {
    final result =
        await _cancellable(
              AiChatSettingsCommand.testConversation,
              configuration,
              apiKey,
              cancellation,
            )
            as Map;
    return AiConversationTestResult(
      text: result['text'] as String,
      latency: Duration(milliseconds: result['latencyMs'] as int),
    );
  }

  @override
  Future<String> loadAgentInstructions() async =>
      await _call(const AiChatSettingsRequest(AiChatSettingsCommand.agentRead))
          as String;
  @override
  Future<void> saveAgentInstructions(String text) async {
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.agentSave, {'text': text}),
    );
  }

  @override
  Future<void> saveService(
    String name,
    AiProviderConfig configuration, {
    String? apiKey,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
    Map<String, AiModelProfile>? modelProfiles,
  }) async {
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.serviceSave, {
        'name': name,
        'configuration': aiSettingsConfigToMap(configuration),
        'apiKey': apiKey,
        if (modelProfiles != null)
          'modelProfiles': {
            for (final e in modelProfiles.entries) e.key: e.value.toJson(),
          },
        if (modelProfile != null) 'modelProfile': modelProfile.toJson(),
        if (configuredModels != null) 'configuredModels': configuredModels,
      }),
    );
  }

  @override
  Future<void> deleteService(String id) async {
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.serviceDelete, {
        'serviceId': id,
      }),
    );
  }

  @override
  Future<void> selectService(String id) async {
    await _call(
      AiChatSettingsRequest(AiChatSettingsCommand.serviceSelect, {
        'serviceId': id,
      }),
    );
  }

  @override
  Future<List<String>> loadCachedModels(AiProviderConfig configuration) async =>
      List<String>.from(
        await _call(
              AiChatSettingsRequest(AiChatSettingsCommand.cachedModels, {
                'configuration': aiSettingsConfigToMap(configuration),
              }),
            )
            as List,
      );
}
