// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'provider_models.dart';

class AiProviderService {
  AiProviderService({
    required this.id,
    required this.name,
    required AiProviderConfig configuration,
    required this.hasApiKey,
  }) : configuration = configuration.copyWith(serviceId: id, apiKey: '');
  final String id, name;
  final AiProviderConfig configuration;
  final bool hasApiKey;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'configuration': configuration.toPreferences(),
    'hasApiKey': hasApiKey,
  };
  factory AiProviderService.fromJson(Map value) {
    final id = value['id'], name = value['name'];
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 80 ||
        value['configuration'] is! Map) {
      throw const AiProviderException('storage', '服务配置暂时无法读取');
    }
    final configuration = AiProviderConfig.fromPreferences(
      value['configuration'] as Map,
    ).copyWith(serviceId: id);
    configuration.validate(requireKey: false, requireModel: false);
    return AiProviderService(
      id: id,
      name: name,
      configuration: configuration,
      hasApiKey: value['hasApiKey'] == true,
    );
  }
}

abstract interface class AiProviderServicesStore {
  Future<List<AiProviderService>> listServices();
  Future<AiProviderConfig> loadService(String id);
  Future<AiProviderConfig> saveService(
    String name,
    AiProviderConfig configuration, {
    String? apiKey,
  });
  Future<void> deleteService(String id);
}
