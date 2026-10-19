// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_newton_rings_models.dart';

class NewtonRingsStorage {
  static const _key = 'ecjtu.physics.newton_rings';

  Future<NewtonRingsState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(_key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      if (inputs == null) return null;
      return NewtonRingsState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    NewtonRingsState state,
    NewtonRingsCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '牛顿环测球面曲率半径',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(_key, jsonEncode(payload), studentId);
  }
}
