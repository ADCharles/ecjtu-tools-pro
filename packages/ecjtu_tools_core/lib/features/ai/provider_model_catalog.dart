// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../update/update_models.dart';
import 'provider_models.dart';

class AiProviderModelCatalog {
  AiProviderModelCatalog({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  static const preferencesKey = 'ecjtu.ai.model.catalog.v1';
  final Future<SharedPreferences> Function() _preferences;
  final _memory = <String, List<String>>{};

  String _identity(AiProviderConfig config) => sha256Bytes(
    utf8.encode(
      '${config.serviceId.isEmpty || config.serviceId == 'legacy' ? '' : '${config.serviceId}|'}${config.protocol.name}|${config.endpoint}',
    ),
  );

  List<String> _normalize(Iterable<Object?> values, AiProviderConfig config) {
    final models =
        values
            .whereType<String>()
            .where(
              (name) =>
                  name.trim().isNotEmpty &&
                  name.length <= 256 &&
                  !name.contains(RegExp(r'[\x00-\x1f]')) &&
                  (config.apiKey.isEmpty || !name.contains(config.apiKey)),
            )
            .map((name) => name.trim())
            .toSet()
            .take(1000)
            .toList()
          ..sort();
    return List.unmodifiable(models);
  }

  Future<List<String>> load(AiProviderConfig config) async {
    final key = _identity(config);
    final hit = _memory[key];
    if (hit != null) return hit;
    try {
      final raw = (await _preferences()).getString(preferencesKey);
      if (raw != null && raw.length <= 512 * 1024) {
        final json = jsonDecode(raw);
        if (json is Map && json[key] is List) {
          return _memory[key] = _normalize(json[key] as List, config);
        }
      }
    } catch (_) {}
    return const [];
  }

  Future<List<String>> remember(
    AiProviderConfig config,
    Iterable<String> models,
  ) async {
    final key = _identity(config);
    final value = _memory[key] = _normalize(models, config);
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(preferencesKey);
      final existing = raw == null || raw.length > 512 * 1024
          ? null
          : jsonDecode(raw);
      final records = <String, Object?>{};
      if (existing is Map) {
        for (final entry in existing.entries) {
          if (entry.key is String &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(entry.key as String) &&
              entry.value is List &&
              (entry.value as List).length <= 1000) {
            records[entry.key as String] = entry.value;
          }
        }
      }
      records.remove(key);
      records[key] = value;
      while (records.length > 16) {
        records.remove(records.keys.first);
      }
      await prefs.setString(preferencesKey, jsonEncode(records));
    } catch (_) {}
    return value;
  }
}
