// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';
import 'physics_electron_charge_models.dart';

class ElectronChargeCalculator {
  const ElectronChargeCalculator._();

  static final _pi = PhysicsDecimal.parse(
    '3.14159265358979323846264338327950288419716939937510',
  )!;

  static ElectronChargeCalculation calculate(ElectronChargeState state) {
    return ElectronChargeCalculation(
      electric: List<ElectronChargeDeflectionResult>.generate(
        ElectronChargeDefinitions.electric.length,
        (index) => _deflection(
          ElectronChargeDefinitions.electric[index],
          state.electric.length > index ? state.electric[index] : null,
        ),
        growable: false,
      ),
      electroFocus: _electroFocus(state.electroFocus),
      magnetic: List<ElectronChargeDeflectionResult>.generate(
        ElectronChargeDefinitions.magnetic.length,
        (index) => _deflection(
          ElectronChargeDefinitions.magnetic[index],
          state.magnetic.length > index ? state.magnetic[index] : null,
        ),
        growable: false,
      ),
      magneticFocus: List<ElectronChargeMagneticFocusResult>.generate(
        ElectronChargeState.magneticFocusCount,
        (index) => _magneticFocus(
          state.magneticFocus.length > index
              ? state.magneticFocus[index]
              : ElectronChargeMagneticFocusInput.initial(index),
          index,
        ),
        growable: false,
      ),
    );
  }

  static ElectronChargeDeflectionResult _deflection(
    ElectronChargeSeriesDefinition definition,
    ElectronChargeSeriesInput? source,
  ) {
    final points = List<ElectronChargePointResult>.generate(
      definition.xDefaults.length,
      (index) {
        final input = source != null && index < source.points.length
            ? source.points[index]
            : const ElectronChargePointInput();
        final x = PhysicsDecimal.parse(input.x);
        final y = PhysicsDecimal.parse(input.y);
        return ElectronChargePointResult(
          index: index,
          x: x,
          y: y,
          ratio: x != null && y != null && !x.isZero ? y.divide(x) : null,
        );
      },
      growable: false,
    );
    final valid = points
        .where((point) => point.complete)
        .toList(growable: false);
    final nonZero = valid
        .where((point) => !point.x!.isZero)
        .toList(growable: false);
    final ratios = nonZero.map((point) => point.ratio!).toList(growable: false);
    final averageX = _average(nonZero.map((point) => point.x!));
    final averageY = _average(nonZero.map((point) => point.y!));
    final summary = ElectronChargeSummary(
      valid: nonZero,
      complete: averageX != null && averageY != null,
      averageX: averageX,
      averageY: averageY,
      ratio: _average(ratios),
      ratioOfAverages: averageX != null && averageY != null
          ? averageY.divide(averageX)
          : null,
    );
    return ElectronChargeDeflectionResult(
      definition: definition,
      points: points,
      fit: _linearFit(points),
      summary: summary,
      averageX: _average(valid.map((point) => point.x!)),
      averageY: _average(valid.map((point) => point.y!)),
    );
  }

  static ElectronChargeFit _linearFit(List<ElectronChargePointResult> points) {
    final valid = points
        .where((point) => point.complete)
        .toList(growable: false);
    if (valid.length < 2) {
      return ElectronChargeFit(
        valid: valid,
        complete: false,
        error: '至少填写两组完整数据后生成趋势线。',
      );
    }
    final count = PhysicsDecimal.fromInt(valid.length);
    final sumX = _sum(valid.map((point) => point.x!));
    final sumY = _sum(valid.map((point) => point.y!));
    final sumXY = _sum(valid.map((point) => point.x! * point.y!));
    final sumX2 = _sum(valid.map((point) => point.x! * point.x!));
    final denominator = count * sumX2 - sumX * sumX;
    if (denominator.isZero) {
      return ElectronChargeFit(
        valid: valid,
        complete: false,
        error: '横坐标不能全部相同。',
      );
    }
    final slope = (count * sumXY - sumX * sumY).divide(denominator);
    final intercept = (sumY - slope * sumX).divide(count);
    return ElectronChargeFit(
      valid: valid,
      complete: true,
      slope: slope,
      intercept: intercept,
    );
  }

  static ElectronChargeFocusResult _electroFocus(
    List<ElectronChargeFocusInput> rows,
  ) {
    final computed = List<ElectronChargeFocusRowResult>.generate(
      ElectronChargeState.focusRowCount,
      (index) {
        final source = rows.length > index
            ? rows[index]
            : ElectronChargeFocusInput(
                u2: ElectronChargeDefinitions.focusU2[index],
              );
        final u2 = PhysicsDecimal.parse(source.u2);
        final u1 = PhysicsDecimal.parse(source.u1);
        return ElectronChargeFocusRowResult(
          index: index,
          u2: u2,
          u1: u1,
          ratio: u2 != null && u1 != null && !u1.isZero ? u2.divide(u1) : null,
        );
      },
      growable: false,
    );
    final valid = computed.where((row) => row.complete).toList(growable: false);
    final sumU2 = valid.isEmpty ? null : _sum(valid.map((row) => row.u2!));
    final sumU1 = valid.isEmpty ? null : _sum(valid.map((row) => row.u1!));
    return ElectronChargeFocusResult(
      rows: computed,
      sumU2: sumU2,
      sumU1: sumU1,
      averageU2: valid.isEmpty ? null : _average(valid.map((row) => row.u2!)),
      averageU1: valid.isEmpty ? null : _average(valid.map((row) => row.u1!)),
      averageRatio: valid.isEmpty
          ? null
          : _average(valid.map((row) => row.ratio!)),
      totalRatio: sumU2 != null && sumU1 != null && !sumU1.isZero
          ? sumU2.divide(sumU1)
          : null,
    );
  }

  static ElectronChargeMagneticFocusResult _magneticFocus(
    ElectronChargeMagneticFocusInput source,
    int index,
  ) {
    final u2 = PhysicsDecimal.parse(source.u2);
    final forward = PhysicsDecimal.parse(source.forward);
    final reverse = PhysicsDecimal.parse(source.reverse);
    final length = PhysicsDecimal.parse(source.length);
    final diameter = PhysicsDecimal.parse(source.diameter);
    final pitch = PhysicsDecimal.parse(source.pitch);
    final turns = PhysicsDecimal.parse(source.turns);
    final mu0 = PhysicsDecimal.parse(source.mu0);
    final standard = PhysicsDecimal.parse(source.standard);
    final averageCurrent = forward != null && reverse != null
        ? (forward + reverse).divide(PhysicsDecimal.fromInt(2))
        : null;
    final lengthSquare = length == null ? null : length * length;
    final diameterSquare = diameter == null ? null : diameter * diameter;
    final pitchSquare = pitch == null ? null : pitch * pitch;
    final turnsSquare = turns == null ? null : turns * turns;
    final mu0Square = mu0 == null ? null : mu0 * mu0;
    final missing = _missing([
      ('u2', u2),
      ('forward', forward),
      ('reverse', reverse),
      ('L', length),
      ('D', diameter),
      ('h', pitch),
      ('N', turns),
      ('mu0', mu0),
      ('standard', standard),
    ]);
    final complete =
        missing == null &&
        averageCurrent != null &&
        !averageCurrent.isZero &&
        !mu0!.isZero &&
        !turns!.isZero &&
        !pitch!.isZero &&
        !standard!.isZero;
    if (!complete) {
      return ElectronChargeMagneticFocusResult(
        index: index,
        u2: u2,
        forward: forward,
        reverse: reverse,
        length: length,
        diameter: diameter,
        pitch: pitch,
        turns: turns,
        mu0: mu0,
        standard: standard,
        averageCurrent: averageCurrent,
        lengthSquare: lengthSquare,
        diameterSquare: diameterSquare,
        pitchSquare: pitchSquare,
        turnsSquare: turnsSquare,
        mu0Square: mu0Square,
        chargeMass: null,
        relativeError: null,
        complete: false,
        error: missing == null ? '平均电流或常量不能为零。' : '缺少 $missing 数据。',
      );
    }
    final numerator =
        PhysicsDecimal.fromInt(8) *
        (_pi * _pi) *
        u2! *
        (lengthSquare! + diameterSquare!);
    final denominator =
        mu0Square! *
        turnsSquare! *
        (averageCurrent * averageCurrent) *
        pitchSquare!;
    final chargeMass = numerator.divide(denominator);
    final relativeError = (chargeMass - standard).abs().divide(standard);
    return ElectronChargeMagneticFocusResult(
      index: index,
      u2: u2,
      forward: forward,
      reverse: reverse,
      length: length,
      diameter: diameter,
      pitch: pitch,
      turns: turns,
      mu0: mu0,
      standard: standard,
      averageCurrent: averageCurrent,
      lengthSquare: lengthSquare,
      diameterSquare: diameterSquare,
      pitchSquare: pitchSquare,
      turnsSquare: turnsSquare,
      mu0Square: mu0Square,
      chargeMass: chargeMass,
      relativeError: relativeError,
      complete: true,
    );
  }

  static PhysicsDecimal _sum(Iterable<PhysicsDecimal> values) {
    return values.fold(
      PhysicsDecimal.fromInt(0),
      (total, value) => total + value,
    );
  }

  static PhysicsDecimal? _average(Iterable<PhysicsDecimal> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return null;
    return _sum(list).divide(PhysicsDecimal.fromInt(list.length));
  }

  static String? _missing(List<(String key, PhysicsDecimal? value)> values) {
    for (final item in values) {
      if (item.$2 == null) return item.$1;
    }
    return null;
  }
}
