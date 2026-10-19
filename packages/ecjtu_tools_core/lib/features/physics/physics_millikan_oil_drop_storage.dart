// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_millikan_oil_drop_models.dart';

class MillikanOilDropStorage {
  static const key = 'ecjtu.physics.millikan_oil_drop';

  Future<MillikanState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : MillikanState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    MillikanState state,
    MillikanCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '密立根油滴实验',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
