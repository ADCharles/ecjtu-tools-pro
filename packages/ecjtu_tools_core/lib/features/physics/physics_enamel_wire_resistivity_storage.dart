// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_enamel_wire_resistivity_models.dart';

class EnamelWireResistivityStorage {
  static const key = 'ecjtu.physics.enamel_wire_resistivity';

  Future<EnamelWireResistivityState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : decoded;
      return inputs == null
          ? null
          : EnamelWireResistivityState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    EnamelWireResistivityState state,
    EnamelWireResistivityCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '漆包线电阻率的测定',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
