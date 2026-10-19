// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_solid_density_models.dart';

class SolidDensityStorage {
  static const key = 'ecjtu.physics.solid_density';

  Future<SolidDensityState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : SolidDensityState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    SolidDensityState state,
    SolidDensityCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '固体密度的测量',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
