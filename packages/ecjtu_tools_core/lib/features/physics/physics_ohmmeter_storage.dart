// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_ohmmeter_calculator.dart';
import 'physics_ohmmeter_models.dart';

class OhmmeterStorage {
  static const key = 'ecjtu.physics.ohmmeter';

  Future<OhmmeterState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : decoded;
      return inputs == null ? null : OhmmeterState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    OhmmeterState state,
    OhmmeterCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '欧姆表的制作',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
