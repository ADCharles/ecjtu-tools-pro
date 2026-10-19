// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'enhancement_models.dart';

class EnhancementStorage {
  static const legacyKey = 'ecjtu.smart_work.leave_templates';
  static const _keyPrefix = 'ecjtu.smart_work.leave_templates.';

  Future<List<QuickLeaveTemplate>> readTemplates([String? studentId]) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final target = studentId?.trim() ?? '';
      if (target.isEmpty) {
        return _decode(preferences.getString(legacyKey)) ?? const [];
      }

      final accountTemplates = _decode(preferences.getString(_key(target)));
      if (accountTemplates != null) return accountTemplates;

      final legacyTemplates = _decode(preferences.getString(legacyKey));
      if (legacyTemplates == null) return const [];

      await preferences.setString(
        _key(target),
        jsonEncode(
          legacyTemplates.map((template) => template.toJson()).toList(),
        ),
      );
      await preferences.remove(legacyKey);
      return legacyTemplates;
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeTemplates(
    List<QuickLeaveTemplate> templates, [
    String? studentId,
  ]) async {
    final preferences = await SharedPreferences.getInstance();
    final values = templates
        .where((template) => template.name.trim().isNotEmpty)
        .take(20)
        .toList(growable: false);
    final target = studentId?.trim() ?? '';
    final key = target.isEmpty ? legacyKey : _key(target);
    await preferences.setString(
      key,
      jsonEncode(values.map((template) => template.toJson()).toList()),
    );
    if (target.isNotEmpty) await preferences.remove(legacyKey);
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primaryId = primaryStudentId.trim();
    final aliasId = aliasStudentId.trim();
    if (primaryId.isEmpty || aliasId.isEmpty || primaryId == aliasId) return;
    final primary = await readTemplates(primaryId);
    final alias = await readTemplates(aliasId);
    final merged = <QuickLeaveTemplate>[];
    final seen = <String>{};
    for (final template in [...primary, ...alias]) {
      final identity = jsonEncode(template.toJson());
      if (seen.add(identity)) merged.add(template);
    }
    await writeTemplates(merged, primaryId);
    await clearTemplates(aliasId);
  }

  Future<void> clearTemplates(String studentId) async {
    final preferences = await SharedPreferences.getInstance();
    final target = studentId.trim();
    if (target.isEmpty) return;
    await preferences.remove(_key(target));
    await preferences.remove(legacyKey);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getKeys().where(
      (key) => key == legacyKey || key.startsWith(_keyPrefix),
    );
    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  List<QuickLeaveTemplate>? _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! List) return null;
      return value
          .map(QuickLeaveTemplate.fromJson)
          .where((template) => template.name.trim().isNotEmpty)
          .take(20)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  String _key(String studentId) =>
      '$_keyPrefix${Uri.encodeComponent(studentId.trim())}';
}
