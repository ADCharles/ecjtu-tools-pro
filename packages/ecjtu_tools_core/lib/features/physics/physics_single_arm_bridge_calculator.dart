// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_single_arm_bridge_models.dart';

class SingleArmBridgeCalculator {
  const SingleArmBridgeCalculator._();

  static SingleArmBridgeCalculation calculate(SingleArmBridgeState state) {
    return SingleArmBridgeCalculation(
      r1: _statistics(state.r1),
      r2: _statistics(state.r2),
      parallel: _statistics(state.parallel),
    );
  }

  static SingleArmBridgeStatistics _statistics(List<String> inputs) {
    final List<double?> values = inputs
        .map<double?>(parse)
        .toList(growable: false);
    final usable = values.whereType<double>().toList(growable: false);
    if (usable.isEmpty) {
      return SingleArmBridgeStatistics(
        values: values,
        average: null,
        standardDeviation: null,
      );
    }
    final average =
        usable.fold<double>(0, (sum, value) => sum + value) / usable.length;
    if (usable.length < 2) {
      return SingleArmBridgeStatistics(
        values: values,
        average: average,
        standardDeviation: null,
      );
    }
    final variance =
        usable
            .map((value) => math.pow(value - average, 2).toDouble())
            .fold<double>(0, (sum, value) => sum + value) /
        (usable.length - 1);
    return SingleArmBridgeStatistics(
      values: values,
      average: average,
      standardDeviation: math.sqrt(variance),
    );
  }

  static double? parse(Object? raw) {
    final decimal = PhysicsDecimal.parse(raw);
    if (decimal == null) return null;
    final value = decimal.toDouble();
    return value.isFinite ? value : null;
  }

  static String format(double? value, {int digits = 6}) {
    if (value == null || !value.isFinite) return '—';
    if (value == 0) return '0';
    final absolute = value.abs();
    if (absolute >= 1e6 || absolute < 1e-4) {
      var result = value.toStringAsExponential(math.max(1, digits));
      result = result
          .replaceFirst(RegExp(r'(\.\d*?[1-9])0+e'), r'$1e')
          .replaceFirst(RegExp(r'\.0+e'), 'e')
          .replaceFirstMapped(
            RegExp(r'e([+-])0+(\d+)'),
            (match) => 'e${match.group(1)}${match.group(2)}',
          );
      return result;
    }
    final fixed = value.toStringAsFixed(digits);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String resultText(SingleArmBridgeStatistics statistics) {
    if (statistics.average == null) return '—';
    return '${format(statistics.average)} ± '
        '${format(statistics.standardDeviation)} Ω';
  }
}
