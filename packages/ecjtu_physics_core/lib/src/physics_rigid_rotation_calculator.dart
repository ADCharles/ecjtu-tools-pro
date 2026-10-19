// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_rigid_rotation_models.dart';

class RigidRotationCalculator {
  const RigidRotationCalculator._();

  static RigidRotationCalculation calculate(RigidRotationState state) {
    final height = parse(state.height);
    final gravity = parse(state.gravity);
    final diameters = state.diameters.map(parse).toList(growable: false);
    final massRuns = state.massRuns
        .map(
          (input) => RigidRotationMassCalculation(
            mass: parse(input.mass),
            run: _run(input.times),
          ),
        )
        .toList(growable: false);
    final firstFit = _regression(
      massRuns.map(
        (run) => run.mass != null && run.run.inverseSquare != null
            ? RigidRotationRegressionPoint(
                x: run.run.inverseSquare!,
                y: run.mass!,
              )
            : null,
      ),
    );
    final d5 = diameters.isEmpty ? null : diameters.last;
    final firstInertia = _finiteOrNull(
      height != null &&
              gravity != null &&
              d5 != null &&
              firstFit.slope != null &&
              height != 0
          ? gravity *
                firstFit.slope! *
                math.pow(d5, 2).toDouble() /
                (8 * height)
          : null,
    );

    final secondMass = parse(state.secondMass);
    final secondRuns = state.secondRuns
        .asMap()
        .entries
        .map(
          (entry) => RigidRotationSecondCalculation(
            radius: entry.key < diameters.length && diameters[entry.key] != null
                ? diameters[entry.key]! / 2
                : null,
            run: _run(entry.value.times),
          ),
        )
        .toList(growable: false);
    final secondFit = _regression(
      secondRuns.map(
        (run) => run.radius != null && run.run.inverseSquare != 0
            ? run.run.inverseTime == null
                  ? null
                  : RigidRotationRegressionPoint(
                      x: run.run.inverseTime!,
                      y: run.radius!,
                    )
            : null,
      ),
    );
    final secondInertia = _finiteOrNull(
      secondMass != null &&
              gravity != null &&
              height != null &&
              secondFit.slope != null &&
              height != 0
          ? secondMass *
                gravity *
                math.pow(secondFit.slope!, 2).toDouble() /
                (2 * height)
          : null,
    );
    final inertia = _finiteOrNull(
      firstInertia != null && secondInertia != null
          ? (firstInertia + secondInertia) / 2
          : null,
    );

    return RigidRotationCalculation(
      height: height,
      gravity: gravity,
      diameters: diameters,
      massRuns: massRuns,
      firstFit: firstFit,
      firstInertia: firstInertia,
      secondMass: secondMass,
      secondRuns: secondRuns,
      secondFit: secondFit,
      secondInertia: secondInertia,
      inertia: inertia,
    );
  }

  static RigidRotationRunCalculation _run(List<String> values) {
    final times = values.map(parse).toList(growable: false);
    final usable = times.whereType<double>().toList(growable: false);
    final mean = usable.isEmpty
        ? null
        : usable.reduce((left, right) => left + right) / usable.length;
    final square = _finiteOrNull(
      mean == null ? null : math.pow(mean, 2).toDouble(),
    );
    final inverseSquare = _finiteOrNull(
      mean != null && mean != 0 ? 1 / math.pow(mean, 2).toDouble() : null,
    );
    final inverseTime = _finiteOrNull(
      mean != null && mean != 0 ? 1 / mean : null,
    );
    return RigidRotationRunCalculation(
      times: times,
      mean: _finiteOrNull(mean),
      square: square,
      inverseSquare: inverseSquare,
      inverseTime: inverseTime,
    );
  }

  static RigidRotationRegression _regression(
    Iterable<RigidRotationRegressionPoint?> points,
  ) {
    final usable = points
        .whereType<RigidRotationRegressionPoint>()
        .where((point) => point.x.isFinite && point.y.isFinite)
        .toList(growable: false);
    if (usable.length < 2) {
      return RigidRotationRegression(
        valid: usable,
        slope: null,
        intercept: null,
        r2: null,
      );
    }
    final meanX = _average(usable.map((point) => point.x));
    final meanY = _average(usable.map((point) => point.y));
    final denominator = usable.fold<double>(
      0,
      (sum, point) => sum + math.pow(point.x - meanX, 2).toDouble(),
    );
    if (denominator == 0) {
      return RigidRotationRegression(
        valid: usable,
        slope: null,
        intercept: null,
        r2: null,
      );
    }
    final slope =
        usable.fold<double>(
          0,
          (sum, point) => sum + (point.x - meanX) * (point.y - meanY),
        ) /
        denominator;
    final intercept = meanY - slope * meanX;
    final total = usable.fold<double>(
      0,
      (sum, point) => sum + math.pow(point.y - meanY, 2).toDouble(),
    );
    final residual = usable.fold<double>(
      0,
      (sum, point) =>
          sum + math.pow(point.y - (slope * point.x + intercept), 2).toDouble(),
    );
    return RigidRotationRegression(
      valid: usable,
      slope: _finiteOrNull(slope),
      intercept: _finiteOrNull(intercept),
      r2: total == 0 ? null : _finiteOrNull(1 - residual / total),
    );
  }

  static double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    return list.reduce((left, right) => left + right) / list.length;
  }

  static double? parse(Object? raw) {
    final source = raw?.toString().trim().replaceAll(',', '') ?? '';
    if (source.isEmpty) return null;
    final value = double.tryParse(source);
    return value != null && value.isFinite ? value : null;
  }

  static double? _finiteOrNull(double? value) {
    return value != null && value.isFinite ? value : null;
  }

  static String format(double? value, {int digits = 6}) {
    return formatDouble(value, digits: digits);
  }

  static String formatDouble(double? value, {int digits = 6}) {
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
