// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_photoelectric_planck_models.dart';

class PhotoelectricPlanckCalculator {
  const PhotoelectricPlanckCalculator._();

  static const speedOfLight = 299792458.0;

  static PhotoelectricPlanckCalculation calculate(
    PhotoelectricPlanckState state,
  ) {
    final groups = List<PhotoelectricGroupCalculation>.generate(
      PhotoelectricPlanckState.wavelengths.length,
      (index) => _group(
        state.groups.length > index
            ? state.groups[index]
            : PhotoelectricGroupInput.initial(
                PhotoelectricPlanckState.wavelengths[index],
              ),
      ),
      growable: false,
    );
    final fit = _regression(
      groups.map(
        (group) => group.cutoff == null
            ? null
            : PhotoelectricRegressionPoint(
                x: group.frequency,
                y: group.cutoff!,
              ),
      ),
    );
    final electronCharge = parse(state.electronCharge);
    final h = fit.slope != null && electronCharge != null
        ? electronCharge * fit.slope!
        : null;
    final knownH = parse(state.knownH);
    final relativeError = h != null && knownH != null && knownH != 0
        ? (h - knownH).abs() / knownH.abs()
        : null;
    return PhotoelectricPlanckCalculation(
      groups: groups,
      fit: fit,
      electronCharge: electronCharge,
      h: h,
      knownH: knownH,
      relativeError: relativeError,
    );
  }

  static PhotoelectricGroupCalculation _group(PhotoelectricGroupInput input) {
    final points = input.points
        .map(
          (point) => PhotoelectricPointResult(
            voltage: parse(point.voltage),
            current: parse(point.current),
          ),
        )
        .toList(growable: false);
    final regression = _regression(
      points
          .where((point) => point.complete)
          .map(
            (point) => PhotoelectricRegressionPoint(
              x: point.voltage!,
              y: point.current!,
            ),
          ),
    );
    final derivedCutoff =
        regression.slope != null &&
            regression.intercept != null &&
            regression.slope != 0
        ? -regression.intercept! / regression.slope!
        : null;
    final enteredCutoff = parse(input.cutoff);
    final cutoff = enteredCutoff ?? derivedCutoff;
    final frequency = speedOfLight / (input.wavelength * 1e-9);
    return PhotoelectricGroupCalculation(
      wavelength: input.wavelength,
      points: points,
      regression: regression,
      frequency: frequency,
      derivedCutoff: derivedCutoff,
      cutoff: cutoff,
    );
  }

  static PhotoelectricRegression _regression(
    Iterable<PhotoelectricRegressionPoint?> points,
  ) {
    final usable = points.whereType<PhotoelectricRegressionPoint>().toList(
      growable: false,
    );
    if (usable.length < 2) {
      return PhotoelectricRegression(
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
      return PhotoelectricRegression(
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
    return PhotoelectricRegression(
      valid: usable,
      slope: slope,
      intercept: intercept,
      r2: total == 0 ? null : 1 - residual / total,
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

  static String format(double? value, {int digits = 6}) {
    if (value == null) return '—';
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
