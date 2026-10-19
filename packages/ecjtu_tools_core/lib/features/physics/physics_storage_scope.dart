// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:shared_preferences/shared_preferences.dart';

class PhysicsStorageScope {
  static Future<String?> Function(String key)? componentRead;
  static Future<void> Function(String key, String value)? componentWrite;

  static const keyPrefix = 'ecjtu.physics.';

  static const baseKeys = <String>[
    'ecjtu.physics.newton_rings',
    'ecjtu.physics.electron_charge',
    'ecjtu.physics.galvanometer',
    'ecjtu.physics.electrostatic_field',
    'ecjtu.physics.voltage_current',
    'ecjtu.physics.youngs_modulus',
    'ecjtu.physics.potential_difference',
    'ecjtu.physics.sound_speed',
    'ecjtu.physics.liquid_refractive_index',
    'ecjtu.physics.solid_density',
    'ecjtu.physics.single_arm_bridge',
    'ecjtu.physics.hall_effect',
    'ecjtu.physics.franck_hertz',
    'ecjtu.physics.photoelectric_planck',
    'ecjtu.physics.millikan_oil_drop',
    'ecjtu.physics.metal_work_function',
    'ecjtu.physics.rigid_rotation',
    'ecjtu.physics.ohmmeter',
    'ecjtu.physics.enamel_wire_resistivity',
    'ecjtu.physics.rheostat_characteristic',
  ];

  static Future<String?> readRaw(String baseKey, [String? studentId]) async {
    if (componentRead != null) return componentRead!(baseKey);
    final preferences = await SharedPreferences.getInstance();
    final target = studentId?.trim() ?? '';
    final scoped = target.isEmpty ? baseKey : scopedKey(baseKey, target);
    final encoded = preferences.getString(scoped);
    if (encoded != null && encoded.isNotEmpty) return encoded;
    if (target.isEmpty) return null;

    final legacy = preferences.getString(baseKey);
    if (legacy == null || legacy.isEmpty) return null;
    await preferences.setString(scoped, legacy);
    await preferences.remove(baseKey);
    return legacy;
  }

  static Future<void> writeRaw(
    String baseKey,
    String encoded, [
    String? studentId,
  ]) async {
    if (componentWrite != null) return componentWrite!(baseKey, encoded);
    final preferences = await SharedPreferences.getInstance();
    final target = studentId?.trim() ?? '';
    await preferences.setString(
      target.isEmpty ? baseKey : scopedKey(baseKey, target),
      encoded,
    );
    if (target.isNotEmpty) await preferences.remove(baseKey);
  }

  static Future<void> mergeAll(
    String primaryStudentId,
    String aliasStudentId,
  ) async {
    final primary = primaryStudentId.trim();
    final alias = aliasStudentId.trim();
    if (primary.isEmpty || alias.isEmpty || primary == alias) return;
    final preferences = await SharedPreferences.getInstance();
    for (final baseKey in baseKeys) {
      final primaryKey = scopedKey(baseKey, primary);
      final aliasKey = scopedKey(baseKey, alias);
      var primaryRaw = preferences.getString(primaryKey);
      final aliasRaw = preferences.getString(aliasKey);
      final legacyRaw = preferences.getString(baseKey);
      if ((primaryRaw == null || primaryRaw.isEmpty) &&
          legacyRaw != null &&
          legacyRaw.isNotEmpty) {
        await preferences.setString(primaryKey, legacyRaw);
        primaryRaw = legacyRaw;
      }
      if ((primaryRaw == null || primaryRaw.isEmpty) &&
          aliasRaw != null &&
          aliasRaw.isNotEmpty) {
        await preferences.setString(primaryKey, aliasRaw);
      }
      await preferences.remove(baseKey);
      await preferences.remove(aliasKey);
    }
  }

  static Future<void> clearAccount(
    String studentId, {
    bool clearLegacy = false,
  }) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    for (final baseKey in baseKeys) {
      if (clearLegacy) await preferences.remove(baseKey);
      await preferences.remove(scopedKey(baseKey, target));
    }
  }

  static Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getKeys().where(
      (key) => key.startsWith(keyPrefix),
    );
    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  static String scopedKey(String baseKey, String studentId) =>
      '$baseKey.${Uri.encodeComponent(studentId.trim())}';
}
