// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_voltage_current_models.dart';

class VoltageCurrentStorage {
  static const key = 'ecjtu.physics.voltage_current';

  Future<VoltageCurrentState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : VoltageCurrentState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    VoltageCurrentState state,
    VoltageCurrentCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '电学元件伏安特性的研究',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': {
        'instrument': state.instrument.toJson(),
        'blocks': state.blocks
            .map((block) => block.toJson())
            .toList(growable: false),
        'diode': state.diode
            .map((point) => point.toJson())
            .toList(growable: false),
      },
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
