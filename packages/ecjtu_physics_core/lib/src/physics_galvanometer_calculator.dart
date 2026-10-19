// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';
import 'physics_galvanometer_models.dart';

class GalvanometerCalculator {
  const GalvanometerCalculator._();

  static GalvanometerCalculation calculate(GalvanometerState state) {
    final resistance = _calculateResistance(state.resistance);
    final sensitivity = _calculateSensitivity(state, resistance);
    return GalvanometerCalculation(
      resistance: resistance,
      sensitivity: sensitivity,
    );
  }

  static GalvanometerResistanceResult _calculateResistance(
    List<GalvanometerResistanceInput> inputs,
  ) {
    final rows = List<GalvanometerResistanceRowResult>.generate(
      GalvanometerState.resistanceCount,
      (index) {
        final source = index < inputs.length
            ? inputs[index]
            : const GalvanometerResistanceInput();
        final uLow = PhysicsDecimal.parse(source.uLow);
        final rLow = PhysicsDecimal.parse(source.rLow);
        final uHigh = PhysicsDecimal.parse(source.uHigh);
        final rHigh = PhysicsDecimal.parse(source.rHigh);
        final partiallyFilled = [
          source.uLow,
          source.rLow,
          source.uHigh,
          source.rHigh,
        ].any((value) => value.trim().isNotEmpty);
        if (uLow == null || rLow == null || uHigh == null || rHigh == null) {
          return GalvanometerResistanceRowResult(
            index: index,
            uLow: source.uLow,
            rLow: source.rLow,
            uHigh: source.uHigh,
            rHigh: source.rHigh,
            complete: false,
            partiallyFilled: partiallyFilled,
          );
        }
        if ((uHigh - uLow).isZero) {
          return GalvanometerResistanceRowResult(
            index: index,
            uLow: source.uLow,
            rLow: source.rLow,
            uHigh: source.uHigh,
            rHigh: source.rHigh,
            complete: false,
            partiallyFilled: partiallyFilled,
            error: '相邻电压不能相同。',
          );
        }
        final denominator = uHigh - uLow;
        final numerator = (uLow * rHigh) - (uHigh * rLow);
        final rg = numerator.divide(denominator);
        return GalvanometerResistanceRowResult(
          index: index,
          uLow: source.uLow,
          rLow: source.rLow,
          uHigh: source.uHigh,
          rHigh: source.rHigh,
          rg: rg.format(),
          complete: true,
          partiallyFilled: partiallyFilled,
        );
      },
      growable: false,
    );
    final valid = rows.where((row) => row.complete).toList(growable: false);
    if (valid.length != GalvanometerState.resistanceCount) {
      return GalvanometerResistanceResult(
        rows: rows,
        complete: false,
        message: '请填写完整的 5 组电流计内阻数据。',
      );
    }
    final rgValues = valid
        .map((row) => PhysicsDecimal.parse(row.rg)!)
        .toList(growable: false);
    final mean = _average(rgValues)!;
    final error = _average(
      rgValues.map((value) => (value - mean).abs()).toList(growable: false),
    )!;
    return GalvanometerResistanceResult(
      rows: rows,
      complete: true,
      average: mean.format(),
      averageAbsoluteDeviation: error.format(),
    );
  }

  static GalvanometerSensitivityResult _calculateSensitivity(
    GalvanometerState state,
    GalvanometerResistanceResult resistance,
  ) {
    final ra = PhysicsDecimal.parse(state.critical.ra);
    final rb = PhysicsDecimal.parse(state.critical.rb);
    final rc = PhysicsDecimal.parse(state.critical.rc);
    final averageRg = PhysicsDecimal.parse(resistance.average);
    final resistanceSum = averageRg != null && rc != null
        ? averageRg + rc
        : null;
    final baseAvailable =
        ra != null &&
        rb != null &&
        rc != null &&
        averageRg != null &&
        resistanceSum != null &&
        !ra.isZero &&
        !resistanceSum.isZero;
    final rows = List<GalvanometerSensitivityRowResult>.generate(
      GalvanometerState.sensitivityCount,
      (index) {
        final source = index < state.sensitivity.length
            ? state.sensitivity[index]
            : const GalvanometerSensitivityInput();
        final u = PhysicsDecimal.parse(source.u);
        final d = PhysicsDecimal.parse(source.d);
        final partiallyFilled =
            source.u.trim().isNotEmpty || source.d.trim().isNotEmpty;
        if (!baseAvailable || u == null || d == null || d.isZero) {
          return GalvanometerSensitivityRowResult(
            index: index,
            u: source.u,
            d: source.d,
            complete: false,
            partiallyFilled: partiallyFilled,
          );
        }
        final current = (PhysicsDecimal.fromInt(1000000) * u * rb).divide(
          ra * resistanceSum,
        );
        final constant = current.divide(d);
        if (constant.isZero) {
          return GalvanometerSensitivityRowResult(
            index: index,
            u: source.u,
            d: source.d,
            complete: false,
            currentMicroAmp: current.format(),
            constant: constant.format(),
            partiallyFilled: partiallyFilled,
          );
        }
        final sensitivity = PhysicsDecimal.fromInt(1).divide(constant);
        return GalvanometerSensitivityRowResult(
          index: index,
          u: source.u,
          d: source.d,
          currentMicroAmp: current.format(),
          constant: constant.format(),
          sensitivity: sensitivity.format(),
          complete: true,
          partiallyFilled: partiallyFilled,
        );
      },
      growable: false,
    );
    final valid = rows.where((row) => row.complete).toList(growable: false);
    if (valid.length != GalvanometerState.sensitivityCount) {
      return GalvanometerSensitivityResult(
        rows: rows,
        complete: false,
        message: '请填写完整的 6 次电流计常量数据。',
      );
    }
    final currentValues = valid
        .map((row) => PhysicsDecimal.parse(row.currentMicroAmp)!)
        .toList(growable: false);
    final constantValues = valid
        .map((row) => PhysicsDecimal.parse(row.constant)!)
        .toList(growable: false);
    final sensitivityValues = valid
        .map((row) => PhysicsDecimal.parse(row.sensitivity)!)
        .toList(growable: false);
    final averageCurrent = _average(currentValues)!;
    final averageConstant = _average(constantValues)!;
    final averageSensitivity = _average(sensitivityValues)!;
    final rowsWithDeviation = rows
        .map(
          (row) => row.copyWith(
            deviation: row.complete
                ? (PhysicsDecimal.parse(row.sensitivity)! - averageSensitivity)
                      .format()
                : null,
          ),
        )
        .toList(growable: false);
    final error = _average(
      sensitivityValues
          .take(5)
          .map((value) => (value - averageSensitivity).abs())
          .toList(growable: false),
    )!;
    return GalvanometerSensitivityResult(
      rows: rowsWithDeviation,
      complete: true,
      averageCurrent: averageCurrent.format(),
      averageConstant: averageConstant.format(),
      averageSensitivity: averageSensitivity.format(),
      averageAbsoluteDeviation: error.format(),
    );
  }

  static PhysicsDecimal? _average(List<PhysicsDecimal> values) {
    if (values.isEmpty) return null;
    final total = values.reduce((left, right) => left + right);
    return total.divide(PhysicsDecimal.fromInt(values.length));
  }
}
