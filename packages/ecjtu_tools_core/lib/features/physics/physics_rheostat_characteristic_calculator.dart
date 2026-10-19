// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_rheostat_characteristic_models.dart';

class RheostatCharacteristicCalculator {
  const RheostatCharacteristicCalculator._();

  static RheostatCalculation calculate(RheostatState state) {
    final rangeResistance = parse(state.rangeResistance);
    final rows = state.rows
        .map((row) => _calculateRow(row, rangeResistance))
        .toList(growable: false);
    final directMean = _average(
      rows.map((row) => row.directResistance).toList(growable: false),
    );
    final correctedMean = _average(
      rows.map((row) => row.correctedResistance).toList(growable: false),
    );
    final squaredDifferences = rows
        .map(
          (row) => row.correctedResistance != null && correctedMean != null
              ? (row.correctedResistance! - correctedMean) *
                    (row.correctedResistance! - correctedMean)
              : null,
        )
        .toList(growable: false);
    final aUncertainty = _sampleStandardDeviation(
      rows.map((row) => row.correctedResistance).toList(growable: false),
    );
    final testVoltage = parse(state.testVoltage);
    final testCurrentAmpere =
        testVoltage != null && directMean != null && directMean != 0
        ? testVoltage / directMean
        : null;
    final testCurrentMilliampere = testCurrentAmpere == null
        ? null
        : testCurrentAmpere * 1000;
    final denominator = rangeResistance != null && testCurrentAmpere != null
        ? rangeResistance * testCurrentAmpere - (testVoltage ?? 0)
        : null;
    final voltageDerivative =
        denominator != null &&
            denominator != 0 &&
            rangeResistance != null &&
            testCurrentAmpere != null
        ? rangeResistance *
              rangeResistance *
              testCurrentAmpere /
              (denominator * denominator)
        : null;
    final currentDerivative =
        denominator != null &&
            denominator != 0 &&
            rangeResistance != null &&
            testVoltage != null
        ? -(rangeResistance * rangeResistance) *
              testVoltage /
              (denominator * denominator)
        : null;
    final voltageUncertaintyMillivolt = parse(state.voltageUncertainty);
    final currentUncertaintyMilliampere = parse(state.currentUncertainty);
    final voltageUncertaintyVolt = voltageUncertaintyMillivolt == null
        ? null
        : voltageUncertaintyMillivolt / 1000;
    final currentUncertaintyAmpere = currentUncertaintyMilliampere == null
        ? null
        : currentUncertaintyMilliampere / 1000;
    final bUncertainty =
        voltageDerivative != null &&
            currentDerivative != null &&
            voltageUncertaintyVolt != null &&
            currentUncertaintyAmpere != null
        ? math.sqrt(
            math.pow(voltageDerivative * voltageUncertaintyVolt, 2).toDouble() +
                math
                    .pow(currentDerivative * currentUncertaintyAmpere, 2)
                    .toDouble(),
          )
        : null;
    final totalUncertainty = aUncertainty != null && bUncertainty != null
        ? math.sqrt(
            math.pow(aUncertainty, 2).toDouble() +
                math.pow(bUncertainty, 2).toDouble(),
          )
        : null;
    final relativeError =
        totalUncertainty != null && correctedMean != null && correctedMean != 0
        ? totalUncertainty / correctedMean
        : null;
    return RheostatCalculation(
      rangeResistance: rangeResistance,
      rows: rows,
      directMean: directMean,
      correctedMean: correctedMean,
      squaredDifferences: squaredDifferences,
      aUncertainty: aUncertainty,
      testVoltage: testVoltage,
      testCurrentMilliampere: testCurrentMilliampere,
      testCurrentAmpere: testCurrentAmpere,
      voltageDerivative: voltageDerivative,
      currentDerivative: currentDerivative,
      voltageUncertaintyVolt: voltageUncertaintyVolt,
      currentUncertaintyAmpere: currentUncertaintyAmpere,
      bUncertainty: bUncertainty,
      totalUncertainty: totalUncertainty,
      relativeError: relativeError,
    );
  }

  static RheostatRowCalculation _calculateRow(
    RheostatMeasurementInput input,
    double? rangeResistance,
  ) {
    final voltageMillivolt = parse(input.voltage);
    final currentMilliampere = parse(input.current);
    final voltage = voltageMillivolt == null ? null : voltageMillivolt / 1000;
    final current = currentMilliampere == null
        ? null
        : currentMilliampere / 1000;
    final directResistance = voltage != null && current != null && current != 0
        ? voltage / current
        : null;
    final denominator =
        voltage != null && current != null && rangeResistance != null
        ? rangeResistance * current - voltage
        : null;
    final correctedResistance =
        denominator != null && denominator != 0 && rangeResistance != null
        ? rangeResistance * voltage! / denominator
        : null;
    return RheostatRowCalculation(
      voltageMillivolt: voltageMillivolt,
      currentMilliampere: currentMilliampere,
      voltage: voltage,
      current: current,
      directResistance: directResistance,
      correctedResistance: correctedResistance,
    );
  }

  static double? _average(List<double?> values) {
    final usable = values.whereType<double>().toList(growable: false);
    if (usable.isEmpty) return null;
    return usable.reduce((left, right) => left + right) / usable.length;
  }

  static double? _sampleStandardDeviation(List<double?> values) {
    final usable = values.whereType<double>().toList(growable: false);
    if (usable.length < 2) return null;
    final mean = _average(usable)!;
    final variance =
        usable
            .map((value) => (value - mean) * (value - mean))
            .reduce((left, right) => left + right) /
        (usable.length - 1);
    return math.sqrt(variance);
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

  static String percent(double? value, {int digits = 4}) {
    final formatted = format(
      value == null ? null : value * 100,
      digits: digits,
    );
    return formatted == '—' ? formatted : '$formatted%';
  }
}
