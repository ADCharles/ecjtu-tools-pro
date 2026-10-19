// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/serialized_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'provider_models.dart';
import 'provider_services.dart';

abstract interface class AiProviderStore {
  Future<AiProviderConfig> load();
  Future<AiProviderConfig> save(AiProviderConfig config, {String? apiKey});
}

class AiProviderStorage implements AiProviderStore, AiProviderServicesStore {
  AiProviderStorage({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferences,
    ChatPermissionStore? permissionStore,
  }) : _secure = secureStorage ?? const SerializedSecureStorage(),
       _preferences = preferences ?? SharedPreferences.getInstance,
       _permissions =
           permissionStore ?? ChatPermissionStore(preferences: preferences);

  static const preferencesKey = 'ecjtu.ai.chat.provider.v1';
  static const servicesKey = 'ecjtu.ai.chat.services.v2';
  Future<void> _writes = Future.value();
  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> Function() _preferences;
  final ChatPermissionStore _permissions;
  final _credentialCache = <String, Future<String>>{};

  Future<String> _readCredential(String key) =>
      _credentialCache.putIfAbsent(key, () async {
        try {
          final value = await _secure.read(key: key) ?? '';
          if (value.isEmpty) _credentialCache.remove(key);
          return value;
        } catch (_) {
          _credentialCache.remove(key);
          rethrow;
        }
      });

  String _credentialKey(AiProviderConfig config) => config.serviceId.isNotEmpty
      ? 'ecjtu.ai.chat.key.service.${config.serviceId}'
      : 'ecjtu.ai.chat.key.${base64Url.encode(utf8.encode('${config.protocol.name}|${config.endpoint}'))}';

  @override
  Future<AiProviderConfig> load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(servicesKey);
    if (raw != null) {
      final record = _decodeServices(raw);
      final id = record['activeId'];
      if (id is String && id.isNotEmpty) return loadService(id);
      return AiProviderConfig(permissionMode: await _permissions.readMode());
    }
    return _loadLegacy();
  }

  Future<AiProviderConfig> _loadLegacy() async {
    try {
      final prefs = await _preferences();
      final mode = await _permissions.readMode();
      final raw = prefs.getString(preferencesKey);
      if (raw == null) return AiProviderConfig(permissionMode: mode);
      final json = jsonDecode(raw) as Map;
      final config = AiProviderConfig.fromPreferences(
        json,
        permissionMode: mode,
      );
      return config.withKey(await _readCredential(_credentialKey(config)));
    } catch (_) {
      throw const AiProviderException('storage', 'AI 设置暂时无法读取，请稍后重新打开');
    }
  }

  @override
  Future<AiProviderConfig> save(
    AiProviderConfig config, {
    String? apiKey,
  }) async {
    if (config.serviceId.isNotEmpty) {
      final services = await listServices();
      final service = services
          .where((s) => s.id == config.serviceId)
          .firstOrNull;
      return saveService(service?.name ?? '服务', config, apiKey: apiKey);
    }
    config.validate(requireKey: false, requireModel: false);
    try {
      final credentialKey = _credentialKey(config);
      final key = apiKey?.trim() ?? await _readCredential(credentialKey);
      if (key.isNotEmpty && jsonEncode(config.toPreferences()).contains(key)) {
        throw const AiProviderException('configuration', 'API 地址或模型名称不能包含密钥');
      }
      if (apiKey != null) {
        if (key.isEmpty) {
          await _secure.delete(key: credentialKey);
        } else {
          await _secure.write(key: credentialKey, value: key);
        }
        _credentialCache[credentialKey] = Future.value(key);
      }
      final prefs = await _preferences();
      if (!await prefs.setString(
        preferencesKey,
        jsonEncode(config.toPreferences()),
      )) {
        throw const AiProviderException('storage', 'AI 设置保存失败，请稍后重试');
      }
      await _permissions.writeMode(config.permissionMode);
      return config.withKey(key);
    } catch (_) {
      throw const AiProviderException('storage', 'AI 设置保存失败，请稍后重试');
    }
  }

  Map<String, Object?> _decodeServices(String raw) {
    if (raw.length > 256 * 1024)
      throw const AiProviderException('storage', '服务配置暂时无法读取');
    final value = jsonDecode(raw);
    if (value is! Map ||
        value['services'] is! List ||
        (value['services'] as List).length > 32) {
      throw const AiProviderException('storage', '服务配置暂时无法读取');
    }
    return Map<String, Object?>.from(value);
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final next = _writes.catchError((Object _) {}).then((_) => operation());
    _writes = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _writeServices(
    SharedPreferences prefs,
    Map<String, Object?> value,
  ) async {
    final encoded = jsonEncode(value);
    if (encoded.length > 256 * 1024 ||
        !await prefs.setString(servicesKey, encoded)) {
      throw const AiProviderException('storage', '服务配置保存失败，请重试');
    }
  }

  @override
  Future<List<AiProviderService>> listServices() => _serialized(() async {
    final prefs = await _preferences();
    var raw = prefs.getString(servicesKey);
    if (raw == null) {
      final legacy = await _loadLegacy();
      final hasLegacy = prefs.containsKey(preferencesKey);
      if (hasLegacy && legacy.apiKey.isNotEmpty) {
        await _secure.write(
          key: _credentialKey(legacy.copyWith(serviceId: 'legacy')),
          value: legacy.apiKey,
        );
      }
      final records = hasLegacy
          ? [
              AiProviderService(
                id: 'legacy',
                name: '服务 1',
                configuration: legacy.copyWith(serviceId: 'legacy'),
                hasApiKey: legacy.apiKey.isNotEmpty,
              ).toJson(),
            ]
          : const <Object?>[];
      await _writeServices(prefs, {
        'activeId': hasLegacy ? 'legacy' : '',
        'services': records,
      });
      raw = prefs.getString(servicesKey)!;
    }
    return List.unmodifiable(
      (_decodeServices(raw)['services'] as List).map(
        (v) => AiProviderService.fromJson(v as Map),
      ),
    );
  });

  @override
  Future<AiProviderConfig> loadService(String id) async {
    final services = await listServices();
    final service = services.where((s) => s.id == id).firstOrNull;
    if (service == null)
      throw const AiProviderException('configuration', '服务已更新，请重新选择');
    final config = service.configuration.copyWith(
      permissionMode: await _permissions.readMode(),
    );
    return config.withKey(await _readCredential(_credentialKey(config)));
  }

  @override
  Future<AiProviderConfig> saveService(
    String name,
    AiProviderConfig configuration, {
    String? apiKey,
  }) async {
    await listServices();
    return _serialized(() async {
      final prefs = await _preferences();
      final record = _decodeServices(prefs.getString(servicesKey)!);
      final services = (record['services'] as List)
          .map((v) => AiProviderService.fromJson(v as Map))
          .toList();
      final id = configuration.serviceId.isEmpty
          ? 's_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}'
          : configuration.serviceId;
      final config = configuration.copyWith(serviceId: id);
      config.validate(requireKey: false, requireModel: false);
      final previous = services.where((s) => s.id == id).firstOrNull;
      if (name.trim().isEmpty ||
          name.length > 80 ||
          (previous == null && services.length >= 32)) {
        throw const AiProviderException('configuration', '请填写服务名称，最多保存 32 个服务');
      }
      final credential = _credentialKey(config);
      final oldKey = await _readCredential(credential);
      final sameEndpoint =
          previous?.configuration.endpoint == config.endpoint &&
          previous?.configuration.protocol == config.protocol;
      final key = apiKey?.trim() ?? (sameEndpoint ? oldKey : '');
      if (key.isNotEmpty &&
          jsonEncode({
            'name': name,
            'configuration': config.toPreferences(),
          }).contains(key)) {
        throw const AiProviderException('configuration', '服务名称、地址和模型名称不能包含密钥');
      }
      final entry = AiProviderService(
        id: id,
        name: name.trim(),
        configuration: config,
        hasApiKey: key.isNotEmpty,
      );
      final next = [
        for (final s in services) s.id == id ? entry : s,
        if (previous == null) entry,
      ];
      try {
        if (key != oldKey) {
          if (key.isEmpty) {
            await _secure.delete(key: credential);
          } else {
            await _secure.write(key: credential, value: key);
          }
        }
        await _writeServices(prefs, {
          'activeId': id,
          'services': next.map((s) => s.toJson()).toList(),
        });
      } catch (_) {
        if (key != oldKey) {
          if (oldKey.isEmpty) {
            await _secure.delete(key: credential);
          } else {
            await _secure.write(key: credential, value: oldKey);
          }
        }
        rethrow;
      }
      await prefs.setString(preferencesKey, jsonEncode(config.toPreferences()));
      if (key.isEmpty) {
        _credentialCache.remove(credential);
      } else {
        _credentialCache[credential] = Future.value(key);
      }
      await _permissions.writeMode(config.permissionMode);
      return config.withKey(key);
    });
  }

  @override
  Future<void> deleteService(String id) async {
    await listServices();
    await _serialized(() async {
      final prefs = await _preferences();
      final record = _decodeServices(prefs.getString(servicesKey)!);
      final services = (record['services'] as List)
          .map((v) => AiProviderService.fromJson(v as Map))
          .toList();
      final removed = services.where((s) => s.id == id).firstOrNull;
      if (removed == null)
        throw const AiProviderException('configuration', '服务已更新，请重试');
      services.removeWhere((s) => s.id == id);
      await _writeServices(prefs, {
        'activeId': record['activeId'] == id
            ? (services.firstOrNull?.id ?? '')
            : record['activeId'],
        'services': services.map((s) => s.toJson()).toList(),
      });
      await _secure.delete(key: _credentialKey(removed.configuration));
      _credentialCache.remove(_credentialKey(removed.configuration));
    });
  }
}
