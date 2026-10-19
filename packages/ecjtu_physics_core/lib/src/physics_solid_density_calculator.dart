// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_solid_density_models.dart';

class SolidDensityCalculator {
  const SolidDensityCalculator._();

  static SolidDensityCalculation calculate(SolidDensityState state) {
    final rectangular = _calculateRectangular(state.rectangular);
    final displacement = _calculateDisplacement(state.displacement);
    return SolidDensityCalculation(
      rectangular: rectangular,
      displacement: displacement,
    );
  }

  static SolidDensityRectangularCalculation _calculateRectangular(
    SolidDensityRectangularInput input,
  ) {
    final length = _statistics(input.length);
    final width = _statistics(input.width);
    final height = _statistics(input.height);
    final mass = parse(input.mass);
    final volume =
        length.average != null &&
            width.average != null &&
            height.average != null
        ? length.average! * width.average! * height.average!
        : null;
    final density = mass != null && volume != null && volume > 0
        ? mass / volume
        : null;
    final massError = parse(input.massError) ?? 0;
    final relativeUncertainty =
        density != null &&
            mass != null &&
            mass > 0 &&
            length.average != null &&
            length.average! > 0 &&
            width.average != null &&
            width.average! > 0 &&
            height.average != null &&
            height.average! > 0 &&
            length.standardDeviation != null &&
            width.standardDeviation != null &&
            height.standardDeviation != null
        ? math.sqrt(
            math.pow(massError / mass, 2).toDouble() +
                math
                    .pow(length.standardDeviation! / length.average!, 2)
                    .toDouble() +
                math
                    .pow(width.standardDeviation! / width.average!, 2)
                    .toDouble() +
                math
                    .pow(height.standardDeviation! / height.average!, 2)
                    .toDouble(),
          )
        : null;
    final absoluteUncertainty = density != null && relativeUncertainty != null
        ? density * relativeUncertainty
        : null;
    return SolidDensityRectangularCalculation(
      length: length,
      width: width,
      height: height,
      mass: mass,
      volume: volume,
      density: density,
      relativeUncertainty: relativeUncertainty,
      absoluteUncertainty: absoluteUncertainty,
    );
  }

  static SolidDensityDisplacementCalculation _calculateDisplacement(
    SolidDensityDisplacementInput input,
  ) {
    final m1 = parse(input.m1);
    final m2 = parse(input.m2);
    final m3 = parse(input.m3);
    final objectMass = m1 != null && m2 != null ? m2 - m1 : null;
    final waterMass = m2 != null && m3 != null ? m3 - m2 : null;
    final waterDensity = parse(input.waterDensity);
    final density =
        objectMass != null &&
            waterMass != null &&
            waterDensity != null &&
            waterMass > 0
        ? objectMass * waterDensity / waterMass
        : null;
    final massError = parse(input.massError) ?? 0;
    final waterDensityError = parse(input.waterDensityError) ?? 0;
    final relativeUncertainty =
        density != null &&
            objectMass != null &&
            objectMass > 0 &&
            waterMass != null &&
            waterMass > 0 &&
            waterDensity != null &&
            waterDensity > 0
        ? math.sqrt(
            math.pow(massError / objectMass, 2).toDouble() +
                math.pow(massError / waterMass, 2).toDouble() +
                math.pow(waterDensityError / waterDensity, 2).toDouble(),
          )
        : null;
    final absoluteUncertainty = density != null && relativeUncertainty != null
        ? density * relativeUncertainty
        : null;
    return SolidDensityDisplacementCalculation(
      objectMass: objectMass,
      waterMass: waterMass,
      waterDensity: waterDensity,
      density: density,
      relativeUncertainty: relativeUncertainty,
      absoluteUncertainty: absoluteUncertainty,
    );
  }

  static SolidDensityStatistics _statistics(List<String> values) {
    final parsed = values
        .map(parse)
        .whereType<double>()
        .toList(growable: false);
    if (parsed.isEmpty) {
      return const SolidDensityStatistics(
        average: null,
        standardDeviation: null,
      );
    }
    final average =
        parsed.reduce((left, right) => left + right) / parsed.length;
    if (parsed.length < 2) {
      return SolidDensityStatistics(average: average, standardDeviation: null);
    }
    final variance =
        parsed
            .map((value) => math.pow(value - average, 2).toDouble())
            .reduce((left, right) => left + right) /
        (parsed.length - 1);
    return SolidDensityStatistics(
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

  static String percent(double? value, {int digits = 4}) {
    final formatted = format(
      value == null ? null : value * 100,
      digits: digits,
    );
    return formatted == '—' ? formatted : '$formatted%';
  }
}
