// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_ohmmeter_models.dart';

class OhmmeterRowCalculation {
  const OhmmeterRowCalculation({
    required this.resistance,
    required this.measured,
    required this.theoretical,
  });

  final double? resistance;
  final double? measured;
  final double? theoretical;

  Map<String, Object?> toJson() => {
    'resistance': resistance,
    'measured': measured,
    'theoretical': theoretical,
  };
}

class OhmmeterCalculation {
  const OhmmeterCalculation({
    required this.shuntResistance,
    required this.limitingResistance,
    required this.batteryResistance,
    required this.branchResistance,
    required this.zResistance,
    required this.measuredResistance,
    required this.trueResistance,
    required this.relativeError,
    required this.rows,
  });

  final double? shuntResistance;
  final double? limitingResistance;
  final double? batteryResistance;
  final double? branchResistance;
  final double? zResistance;
  final double? measuredResistance;
  final double? trueResistance;
  final double? relativeError;
  final List<OhmmeterRowCalculation> rows;

  Map<String, Object?> toJson() => {
    'shuntResistance': shuntResistance,
    'limitingResistance': limitingResistance,
    'batteryResistance': batteryResistance,
    'branchResistance': branchResistance,
    'zResistance': zResistance,
    'measuredResistance': measuredResistance,
    'trueResistance': trueResistance,
    'relativeError': relativeError,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
  };
}

class OhmmeterCalculator {
  const OhmmeterCalculator._();

  static OhmmeterCalculation calculate(OhmmeterState state) {
    final shuntResistance = parse(state.shuntResistance);
    final limitingResistance = parse(state.limitingResistance);
    final batteryResistance = parse(state.batteryResistance);
    final branchResistance = shuntResistance != null && shuntResistance > 0
        ? 4 * shuntResistance / 7
        : null;
    final zResistance =
        branchResistance != null &&
            limitingResistance != null &&
            batteryResistance != null
        ? branchResistance + limitingResistance + batteryResistance
        : null;
    final measuredResistance = parse(state.measuredResistance);
    final trueResistance = parse(state.trueResistance);
    final relativeError =
        measuredResistance != null &&
            trueResistance != null &&
            trueResistance != 0
        ? (measuredResistance - trueResistance).abs() /
              trueResistance.abs() *
              100
        : null;
    final rows = state.calibration
        .map((row) {
          final resistance = parse(row.resistance);
          final measured = parse(row.measured);
          final theoretical =
              resistance != null &&
                  zResistance != null &&
                  zResistance + resistance != 0
              ? zResistance / (zResistance + resistance) * 100
              : null;
          return OhmmeterRowCalculation(
            resistance: resistance,
            measured: measured,
            theoretical: theoretical,
          );
        })
        .toList(growable: false);
    return OhmmeterCalculation(
      shuntResistance: shuntResistance,
      limitingResistance: limitingResistance,
      batteryResistance: batteryResistance,
      branchResistance: branchResistance,
      zResistance: zResistance,
      measuredResistance: measuredResistance,
      trueResistance: trueResistance,
      relativeError: relativeError,
      rows: rows,
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
}
