// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'electricity_models.dart';

class ElectricityStorage {
  String _snapshotKey(String studentId) =>
      'ecjtu.electricity.snapshot.${Uri.encodeComponent(studentId)}';

  Future<Map<String, Object?>?> readSnapshot(String studentId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_snapshotKey(studentId));
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map ||
          value['state'] is! Map ||
          value['updatedAt'] is! String)
        return null;
      return {
        'updatedAt': value['updatedAt'],
        'state': ElectricityRechargeState.fromJson(value['state']).toJson(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> writeSnapshot(
    String studentId,
    ElectricityRechargeState state,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _snapshotKey(studentId),
      jsonEncode({
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'state': state.toJson(),
      }),
    );
  }

  Future<List<String>> readCustomAmounts(String studentId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_amountKey(studentId));
      if (raw == null || raw.isEmpty) return const <String>[];
      final value = jsonDecode(raw);
      if (value is! List) return const <String>[];
      return value
          .map((item) => item.toString().trim())
          .where(_validAmount)
          .toSet()
          .take(20)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> writeCustomAmounts(
    String studentId,
    List<String> amounts,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final values = amounts
        .map((value) => value.trim())
        .where(_validAmount)
        .toSet()
        .take(20)
        .toList(growable: false);
    await preferences.setString(_amountKey(studentId), jsonEncode(values));
  }

  Future<ElectricityPendingPayment?> readPending(String studentId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_pendingKey(studentId));
      if (raw == null || raw.isEmpty) return null;
      final value = ElectricityPendingPayment.fromJson(jsonDecode(raw));
      return value.paymentUrl.isEmpty || value.partnerJourno.isEmpty
          ? null
          : value;
    } catch (_) {
      return null;
    }
  }

  Future<void> writePending(
    String studentId,
    ElectricityPendingPayment payment,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingKey(studentId),
      jsonEncode(payment.toJson()),
    );
    await preferences.setString(
      '${_pendingKey(studentId)}.last',
      jsonEncode(payment.toJson()),
    );
  }

  Future<ElectricityPendingPayment?> readLatest(String studentId) async {
    final pending = await readPending(studentId);
    if (pending != null) return pending;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('${_pendingKey(studentId)}.last');
    if (raw == null) return null;
    try {
      final payment = ElectricityPendingPayment.fromJson(jsonDecode(raw));
      return payment.paymentUrl.isEmpty || payment.partnerJourno.isEmpty
          ? null
          : payment;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPending(String studentId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingKey(studentId));
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primaryId = primaryStudentId.trim();
    final aliasId = aliasStudentId.trim();
    if (primaryId.isEmpty || aliasId.isEmpty || primaryId == aliasId) return;
    final primaryAmounts = await readCustomAmounts(primaryId);
    final aliasAmounts = await readCustomAmounts(aliasId);
    await writeCustomAmounts(primaryId, [...primaryAmounts, ...aliasAmounts]);
    final primaryPending = await readPending(primaryId);
    final aliasPending = await readPending(aliasId);
    if (primaryPending == null && aliasPending != null) {
      await writePending(primaryId, aliasPending);
    }
    await clearAccount(aliasId);
  }

  Future<void> clearAccount(String studentId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_amountKey(studentId));
    await preferences.remove(_pendingKey(studentId));
    await preferences.remove('${_pendingKey(studentId)}.last');
    await preferences.remove(_snapshotKey(studentId));
  }

  String _amountKey(String studentId) =>
      'ecjtu.electricity.custom_amounts.${Uri.encodeComponent(studentId)}';

  String _pendingKey(String studentId) =>
      'ecjtu.electricity.pending_payment.${Uri.encodeComponent(studentId)}';

  bool _validAmount(String value) =>
      RegExp(r'^\d{1,4}(?:\.\d{1,2})?$').hasMatch(value) &&
      (double.tryParse(value) ?? 0) > 0;
}
