// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'physics_storage_scope.dart';

import 'physics_photoelectric_planck_models.dart';

class PhotoelectricPlanckStorage {
  static const key = 'ecjtu.physics.photoelectric_planck';

  Future<PhotoelectricPlanckState?> read([String? studentId]) async {
    try {
      final encoded = await PhysicsStorageScope.readRaw(key, studentId);
      if (encoded == null || encoded.isEmpty) return null;
      final decoded = jsonDecode(encoded);
      final inputs = decoded is Map ? decoded['inputs'] : null;
      return inputs == null ? null : PhotoelectricPlanckState.fromJson(inputs);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    PhotoelectricPlanckState state,
    PhotoelectricPlanckCalculation calculation, [
    String? studentId,
  ]) async {
    final payload = <String, Object?>{
      'experiment': '光电效应测普朗克常量',
      'savedAt': DateTime.now().toIso8601String(),
      'inputs': state.toJson(),
      'output': calculation.toJson(),
    };
    await PhysicsStorageScope.writeRaw(key, jsonEncode(payload), studentId);
  }
}
