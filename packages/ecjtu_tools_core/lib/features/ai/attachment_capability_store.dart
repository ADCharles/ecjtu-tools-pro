// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../update/update_models.dart';
import 'attachment_models.dart';
import 'provider_models.dart';
import 'provider_model_profile.dart';

class AiModelCapabilityStore {
  AiModelCapabilityStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  static const preferencesKey = 'ecjtu.ai.model.capabilities.v1';
  final Future<SharedPreferences> Function() _preferences;
  Future<void> _writes = Future.value();

  String _key(AiProviderConfig config) => sha256Bytes(
    utf8.encode(
      '${config.serviceId.isEmpty || config.serviceId == 'legacy' ? '' : '${config.serviceId}|'}${config.protocol.name}|${config.endpoint}|${config.model.trim()}',
    ),
  );

  Future<AiModelCapabilities> load(AiProviderConfig config) async =>
      (await loadProfile(config)).modelCapabilities;

  Future<AiModelProfile> loadProfile(
    AiProviderConfig config, {
    AiModelProfile fallback = const AiModelProfile(),
  }) async {
    await _writes.catchError((Object _) {});
    try {
      final raw = (await _preferences()).getString(preferencesKey);
      if (raw != null && raw.length <= 256 * 1024) {
        final records = jsonDecode(raw);
        if (records is Map && records[_key(config)] is Map) {
          return AiModelProfile.fromJson(
            records[_key(config)] as Map,
            fallback: fallback,
          );
        }
      }
    } catch (_) {}
    return fallback;
  }

  Future<void> save(AiProviderConfig config, AiModelCapabilities value) =>
      _write(config, (previous) => {...previous, ...value.toJson()});

  Future<void> saveProfile(AiProviderConfig config, AiModelProfile value) {
    return saveProfiles(config, {config.model: value});
  }

  Future<void> saveProfiles(
    AiProviderConfig config,
    Map<String, AiModelProfile> profiles,
  ) {
    final values = <String, Map<String, Object?>>{};
    for (final entry in profiles.entries) {
      final model = entry.key.trim();
      if (model.isEmpty || model.length > 256) {
        throw const AiProviderException('configuration', '请输入有效的模型名称');
      }
      entry.value.validate();
      values[model] = entry.value.toJson();
    }
    if (values.isEmpty) return Future.value();
    return _writeProfiles(config, values);
  }

  Future<void> _write(
    AiProviderConfig config,
    Map<String, Object?> Function(Map) update,
  ) => _writeRecords(config, (records) {
    final key = _key(config);
    records[key] = update(records[key] is Map ? records[key] as Map : {});
  });

  Future<void> _writeProfiles(
    AiProviderConfig config,
    Map<String, Map<String, Object?>> profiles,
  ) => _writeRecords(config, (records) {
    for (final entry in profiles.entries) {
      records[_key(config.copyWith(model: entry.key))] = entry.value;
    }
  });

  Future<void> _writeRecords(
    AiProviderConfig config,
    void Function(Map<String, Object?> records) update,
  ) {
    final operation = _writes.catchError((Object _) {}).then((_) async {
      try {
        final prefs = await _preferences();
        final raw = prefs.getString(preferencesKey);
        if (raw != null && raw.length > 256 * 1024)
          throw const FormatException();
        final decoded = raw == null ? null : jsonDecode(raw);
        final records = decoded is Map
            ? Map<String, Object?>.from(decoded)
            : <String, Object?>{};
        update(records);
        final encoded = jsonEncode(records);
        if (encoded == raw) return;
        if (encoded.length > 256 * 1024 ||
            !await prefs.setString(preferencesKey, encoded)) {
          throw const FormatException();
        }
      } catch (_) {
        throw const AiProviderException('storage', '模型设置保存失败，请重试');
      }
    });
    _writes = operation;
    return operation;
  }
}
