// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_single_arm_bridge_models.dart';

class SingleArmBridgeStorage {
  static const key = 'ecjtu.physics.single_arm_bridge';

  Future<SingleArmBridgeState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : SingleArmBridgeState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    SingleArmBridgeState state,
    SingleArmBridgeCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '单臂电桥法测电阻',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
