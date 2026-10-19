// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../update/update_models.dart';
import 'provider_models.dart';

class AiProviderModelRegistry {
  AiProviderModelRegistry({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const preferencesKey = 'ecjtu.ai.model.registry.v1';
  static const maxModels = 128;
  static const _maxRecords = 128;
  static const _maxBytes = 1024 * 1024;
  final Future<SharedPreferences> Function() _preferences;
  Future<void> _writes = Future.value();

  String _identity(AiProviderConfig config) => sha256Bytes(
    utf8.encode(
      '${config.serviceId.isEmpty || config.serviceId == 'legacy' ? '' : '${config.serviceId}|'}${config.protocol.name}|${config.endpoint}',
    ),
  );

  List<String> _normalize(Iterable<Object?> values, AiProviderConfig config) {
    final models = <String>{};
    for (final value in values) {
      if (value is! String) throw const FormatException();
      final model = value.trim();
      if (model.isEmpty ||
          model.length > 256 ||
          model.contains(RegExp(r'[\x00-\x1f]')) ||
          (config.apiKey.isNotEmpty && model.contains(config.apiKey))) {
        throw const AiProviderException('configuration', '请输入有效的模型名称');
      }
      models.add(model);
    }
    if (models.length > maxModels) {
      throw const AiProviderException('configuration', '最多添加 128 个模型');
    }
    return List.unmodifiable(models);
  }

  Map<String, Object?> _decode(String? raw) {
    if (raw == null) return {};
    if (raw.length > _maxBytes) throw const FormatException();
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded.length > _maxRecords) {
      throw const FormatException();
    }
    return Map<String, Object?>.from(decoded);
  }

  Future<List<String>> load(AiProviderConfig config) async {
    await _writes.catchError((Object _) {});
    try {
      final records = _decode((await _preferences()).getString(preferencesKey));
      final models = records[_identity(config)];
      if (models is List) return _normalize(models, config);
    } catch (_) {}
    return const [];
  }

  Future<List<String>> save(AiProviderConfig config, Iterable<String> models) {
    final selected = _normalize(models, config);
    return _write(config, (_) => selected);
  }

  Future<List<String>> register(
    AiProviderConfig config,
    Iterable<String> models,
  ) {
    final additions = _normalize(models, config);
    return _write(
      config,
      (previous) => _normalize([...previous, ...additions], config),
    );
  }

  Future<List<String>> remove(AiProviderConfig config, String model) => _write(
    config,
    (previous) =>
        List.unmodifiable(previous.where((name) => name != model.trim())),
  );

  Future<List<String>> _write(
    AiProviderConfig config,
    List<String> Function(List<String>) update,
  ) {
    final key = _identity(config);
    final operation = _writes.catchError((Object _) {}).then((_) async {
      try {
        final prefs = await _preferences();
        final raw = prefs.getString(preferencesKey);
        final records = _decode(raw);
        final previous = records[key];
        final models = update(
          previous is List ? _normalize(previous, config) : [],
        );
        records[key] = models;
        final encoded = jsonEncode(records);
        if (records.length > _maxRecords || encoded.length > _maxBytes) {
          throw const FormatException();
        }
        if (encoded != raw && !await prefs.setString(preferencesKey, encoded)) {
          throw const FormatException();
        }
        return models;
      } on AiProviderException {
        rethrow;
      } catch (_) {
        throw const AiProviderException('storage', '模型列表保存失败，请重试');
      }
    });
    _writes = operation.then<void>((_) {}, onError: (Object _) {});
    return operation;
  }
}
