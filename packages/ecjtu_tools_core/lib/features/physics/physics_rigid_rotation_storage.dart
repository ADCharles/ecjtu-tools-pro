// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_rigid_rotation_models.dart';

class RigidRotationStorage {
  static const key = 'ecjtu.physics.rigid_rotation';

  Future<RigidRotationState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : RigidRotationState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    RigidRotationState state,
    RigidRotationCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '刚体转动惯量的研究',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
