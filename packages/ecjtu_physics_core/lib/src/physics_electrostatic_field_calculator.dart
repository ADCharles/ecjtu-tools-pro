// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_electrostatic_field_models.dart';

class ElectrostaticFieldCalculator {
  const ElectrostaticFieldCalculator._();

  static ElectrostaticFieldCalculation calculate(
    ElectrostaticFieldState state,
  ) {
    final voltage = _number(state.parameters.voltage);
    final innerRadius = _number(state.parameters.innerRadius);
    final outerRadius = _number(state.parameters.outerRadius);
    final validGeometry =
        voltage != null &&
        innerRadius != null &&
        outerRadius != null &&
        voltage > 0 &&
        innerRadius > 0 &&
        outerRadius > innerRadius;
    final coaxial = List<ElectrostaticCoaxialRowResult>.generate(
      ElectrostaticFieldState.lineCount,
      (index) {
        final source = index < state.coaxial.length
            ? state.coaxial[index]
            : ElectrostaticCoaxialInput.initial(index);
        final radii = source.radii.map(_number).toList(growable: false);
        final averageRadius = _average(radii);
        final theoretical =
            validGeometry &&
                averageRadius != null &&
                averageRadius > innerRadius &&
                averageRadius < outerRadius
            ? voltage *
                  math.log(outerRadius / averageRadius) /
                  math.log(outerRadius / innerRadius)
            : null;
        final measured = _number(source.potential);
        final relativeError =
            theoretical != null && theoretical != 0 && measured != null
            ? (theoretical - measured).abs() / theoretical.abs() * 100
            : null;
        return ElectrostaticCoaxialRowResult(
          index: index,
          potential: source.potential,
          radii: radii,
          averageRadius: averageRadius,
          theoreticalPotential: theoretical,
          relativeError: relativeError,
          complete: averageRadius != null && theoretical != null,
        );
      },
      growable: false,
    );
    final parallel = List<ElectrostaticParallelRowResult>.generate(
      ElectrostaticFieldState.pointCount,
      (index) {
        final r1 = index < state.parallel.r1.length
            ? _number(state.parallel.r1[index])
            : null;
        final r2 = index < state.parallel.r2.length
            ? _number(state.parallel.r2[index])
            : null;
        final ratio = r1 != null && r2 != null && r2 != 0 ? r1 / r2 : null;
        return ElectrostaticParallelRowResult(
          index: index,
          r1: r1,
          r2: r2,
          ratio: ratio,
          complete: ratio != null && ratio.isFinite,
        );
      },
      growable: false,
    );
    final validRatios = parallel
        .where((row) => row.complete)
        .map((row) => row.ratio!)
        .toList(growable: false);
    final ratioAverage =
        validRatios.length == ElectrostaticFieldState.pointCount
        ? _average(validRatios)
        : null;
    final standardDeviation = ratioAverage != null
        ? math.sqrt(
            validRatios
                    .map(
                      (value) => math.pow(value - ratioAverage, 2).toDouble(),
                    )
                    .reduce((left, right) => left + right) /
                (ElectrostaticFieldState.pointCount - 1),
          )
        : null;
    return ElectrostaticFieldCalculation(
      geometryError: validGeometry ? null : '请填写有效的电源电压、内电极半径和外电极半径。',
      coaxial: coaxial,
      parallel: parallel,
      ratioAverage: ratioAverage,
      standardDeviation: standardDeviation,
    );
  }

  static double? _number(Object? raw) {
    final parsed = PhysicsDecimal.parse(raw);
    if (parsed == null) return null;
    final value = parsed.toDouble();
    return value.isFinite ? value : null;
  }

  static double? _average(Iterable<double?> values) {
    final valid = values
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList(growable: false);
    if (valid.length != values.length || valid.isEmpty) return null;
    return valid.reduce((left, right) => left + right) / valid.length;
  }

  static String format(double? value, {int digits = 6}) {
    if (value == null || !value.isFinite) return '—';
    final formatted = value.toStringAsFixed(digits);
    final trimmed = formatted
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
