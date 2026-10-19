// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension AiChatServicesApi on AiChatController {
  bool get supportsServices => _store is AiProviderServicesStore;
  List<AiProviderService> get services => _services;
  Future<List<({String serviceId, String serviceName, String model})>>
  loadModelChoices() async {
    final groups = await Future.wait([
      for (final service in services)
        () async {
          final models = await loadConfiguredModels(service.configuration);
          return [
            for (final model in {
              ...models,
              if (service.configuration.model.isNotEmpty)
                service.configuration.model,
            })
              (serviceId: service.id, serviceName: service.name, model: model),
          ];
        }(),
    ]);
    return [for (final group in groups) ...group];
  }

  Future<void> selectServiceModel(String id, String model) async {
    if (id == configuration.serviceId) return changeModel(model);
    if (_store is! AiProviderServicesStore ||
        loading ||
        saving ||
        busy ||
        _disposed) {
      throw const AiProviderException('busy', '请等待当前操作结束后切换模型');
    }
    final selected = await (_store as AiProviderServicesStore).loadService(id);
    final target = selected.copyWith(model: model);
    final profile = await loadModelProfile(target);
    await saveConfiguration(profile.applyTo(target), modelProfile: profile);
  }

  Future<List<String>> loadCachedModels(AiProviderConfig configuration) =>
      _modelCatalog.load(configuration);

  Future<void> _refreshServices() async {
    if (_store case AiProviderServicesStore repository) {
      final value = await repository.listServices();
      if (!_disposed) _services = List.unmodifiable(value);
    }
  }

  Future<void> saveService(
    String name,
    AiProviderConfig draft, {
    String? apiKey,
    AiModelProfile? modelProfile,
    List<String>? configuredModels,
    Map<String, AiModelProfile>? modelProfiles,
  }) async {
    if (!supportsServices)
      throw const AiProviderException('configuration', '服务暂时无法保存');
    final id = draft.serviceId.isEmpty
        ? 's_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}'
        : draft.serviceId;
    await _saveConfiguration(
      draft.copyWith(serviceId: id),
      apiKey: apiKey,
      modelProfile: modelProfile,
      configuredModels: configuredModels,
      serviceName: name,
      modelProfiles: modelProfiles,
    );
  }

  Future<AiProviderConfig> resolveServiceDraft(
    AiProviderConfig draft, {
    String? apiKey,
  }) async {
    var key = '';
    if (apiKey != null) {
      key = apiKey;
    } else if (_sameModelService(draft, configuration)) {
      key = configuration.apiKey;
    } else if (draft.serviceId.isNotEmpty &&
        _store is AiProviderServicesStore &&
        _services.any((s) => s.id == draft.serviceId)) {
      final saved = await (_store as AiProviderServicesStore).loadService(
        draft.serviceId,
      );
      if (_sameModelService(draft, saved)) key = saved.apiKey;
    }
    return draft.withKey(key);
  }

  Future<void> selectService(String id) async {
    if (_store is! AiProviderServicesStore ||
        busy ||
        saving ||
        loading ||
        _disposed) {
      throw const AiProviderException('busy', '请等待当前操作结束后切换服务');
    }
    final selected = await (_store as AiProviderServicesStore).loadService(id);
    await saveConfiguration(selected);
  }

  Future<void> deleteService(String id) async {
    if (_store is! AiProviderServicesStore ||
        busy ||
        saving ||
        loading ||
        _disposed) {
      throw const AiProviderException('busy', '请等待当前操作结束后删除服务');
    }
    _saving = true;
    _notify();
    try {
      await (_store as AiProviderServicesStore).deleteService(id);
      await _refreshServices();
      if (_disposed) return;
      if (_configuration.serviceId == id) {
        final next = await _store.load();
        final profile = await _modelCapabilityStore.loadProfile(
          next,
          fallback: AiModelProfile.fromConfiguration(next),
        );
        if (_disposed) return;
        _cancelTitle();
        _configuration = profile.applyTo(next);
        await _loadModelCatalog(next);
        await _loadConfiguredModels(next);
        refreshContextEstimate();
      }
    } finally {
      _saving = false;
      _notify();
    }
  }
}
