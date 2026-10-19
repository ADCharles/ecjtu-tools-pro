// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'chat_controller.dart';

extension AiChatModelProfileApi on AiChatController {
  List<String> get configuredModels => List.unmodifiable({
    ...(_activeRunner?._configuredModels ?? _configuredModels),
    if (configuration.model.trim().isNotEmpty) configuration.model.trim(),
  });

  Future<void> _loadConfiguredModels(AiProviderConfig config) async {
    final generation = ++_registryGeneration;
    var models = await _modelRegistry.load(config);
    if (config.model.trim().isNotEmpty &&
        !models.contains(config.model.trim())) {
      try {
        models = await _modelRegistry.register(config, [config.model.trim()]);
      } catch (_) {}
    }
    if (!_disposed &&
        generation == _registryGeneration &&
        _sameModelService(config, _configuration)) {
      _configuredModels = models;
    }
  }

  Future<List<String>> loadConfiguredModels(AiProviderConfig draft) async {
    if (_disposed) throw const AiProviderException('cancelled', '已停止操作');
    if (_sameModelService(draft, _configuration)) return configuredModels;
    return _modelRegistry.load(draft);
  }

  Future<void> _saveRegistry(Future<void> Function() operation) async {
    if (_disposed || busy || loading || _saving) {
      throw const AiProviderException('busy', '请等待当前操作结束后保存设置');
    }
    _saving = true;
    _notify();
    try {
      await operation();
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _applyRegisteredModels(AiProviderConfig config, List<String> models) {
    if (!_disposed && _sameModelService(config, _configuration)) {
      ++_registryGeneration;
      _configuredModels = models;
    }
    for (final runner in _runners.values) {
      if (!runner._disposed &&
          _sameModelService(config, runner._configuration)) {
        ++runner._registryGeneration;
        runner._configuredModels = models;
      }
    }
  }

  Future<void> registerConfiguredModels(
    Iterable<String> models, {
    AiProviderConfig? configuration,
  }) => _saveRegistry(() async {
    final target = configuration ?? _configuration;
    target.validate(requireKey: false, requireModel: false);
    final registered = await _modelRegistry.register(target, models);
    _applyRegisteredModels(target, registered);
  });

  Future<void> addConfiguredModel(
    AiProviderConfig draft, {
    AiModelProfile? profile,
  }) => _saveRegistry(() async {
    draft.validate(requireKey: false);
    final selectedProfile = profile ?? await loadModelProfile(draft);
    selectedProfile.validate();
    await _modelCapabilityStore.saveProfile(draft, selectedProfile);
    final registered = await _modelRegistry.register(draft, [draft.model]);
    _applyRegisteredModels(draft, registered);
  });

  Future<void> removeConfiguredModel(
    String model, {
    AiProviderConfig? configuration,
  }) => _saveRegistry(() async {
    final target = configuration ?? _configuration;
    target.validate(requireKey: false, requireModel: false);
    final registered = await _modelRegistry.remove(target, model);
    _applyRegisteredModels(target, registered);
  });

  AiModelProfile get modelProfile =>
      AiModelProfile.fromConfiguration(configuration);

  bool _sameProfileTarget(AiProviderConfig a, AiProviderConfig b) =>
      a.serviceId == b.serviceId &&
      a.protocol == b.protocol &&
      a.endpoint == b.endpoint &&
      a.model.trim() == b.model.trim();

  Future<AiModelProfile> loadModelProfile(AiProviderConfig draft) async {
    if (_disposed) throw const AiProviderException('cancelled', '已停止操作');
    if (_sameProfileTarget(draft, configuration)) return modelProfile;
    return _modelCapabilityStore.loadProfile(draft);
  }

  Future<void> saveModelProfile(AiModelProfile profile) async {
    if (loading) {
      throw const AiProviderException('busy', '请等待当前操作结束后保存设置');
    }
    await saveConfiguration(
      profile.applyTo(configuration),
      modelProfile: profile,
    );
  }

  Future<void> changeModel(String model) async {
    final target = configuration.copyWith(model: model.trim());
    final profile = await loadModelProfile(target);
    await saveConfiguration(profile.applyTo(target), modelProfile: profile);
  }
}
