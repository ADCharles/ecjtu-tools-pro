// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_enamel_wire_resistivity_models.dart';

class EnamelWireResistivityCalculator {
  const EnamelWireResistivityCalculator._();

  static EnamelWireResistivityCalculation calculate(
    EnamelWireResistivityState state,
  ) {
    final diameters = state.diameters.map(parse).toList(growable: false);
    final resistances = state.resistances.map(parse).toList(growable: false);
    final diameterMean = _average(diameters);
    final diameterStandardError = _sampleStandardDeviation(diameters);
    final resistanceMean = _average(resistances);
    final resistanceStandardError = _sampleStandardDeviation(resistances);
    final mass = parse(state.mass);
    final massError = parse(state.massError);
    final density = parse(state.density);
    final diameterInMeters = diameterMean == null ? null : diameterMean * 1e-3;
    final resistivity =
        resistanceMean != null &&
            density != null &&
            diameterInMeters != null &&
            mass != null &&
            mass != 0
        ? resistanceMean *
              density *
              math.pi *
              math.pi *
              diameterInMeters *
              diameterInMeters *
              diameterInMeters *
              diameterInMeters /
              (16 * mass)
        : null;
    final relativeError =
        resistivity != null &&
            diameterMean != null &&
            diameterMean != 0 &&
            resistanceMean != null &&
            resistanceMean != 0 &&
            mass != null &&
            mass != 0 &&
            diameterStandardError != null &&
            resistanceStandardError != null
        ? math.sqrt(
            math.pow(4 * diameterStandardError / diameterMean, 2).toDouble() +
                math
                    .pow(resistanceStandardError / resistanceMean, 2)
                    .toDouble() +
                math.pow((massError ?? 0) / mass, 2).toDouble(),
          )
        : null;
    final absoluteError = resistivity != null && relativeError != null
        ? resistivity * relativeError
        : null;
    return EnamelWireResistivityCalculation(
      diameters: diameters,
      diameterSquaredDifferences: _squaredDifferences(diameters, diameterMean),
      diameterMean: diameterMean,
      diameterStandardError: diameterStandardError,
      resistances: resistances,
      resistanceSquaredDifferences: _squaredDifferences(
        resistances,
        resistanceMean,
      ),
      resistanceMean: resistanceMean,
      resistanceStandardError: resistanceStandardError,
      mass: mass,
      massError: massError,
      density: density,
      resistivity: resistivity,
      relativeError: relativeError,
      absoluteError: absoluteError,
    );
  }

  static List<double?> _squaredDifferences(List<double?> values, double? mean) {
    return values
        .map(
          (value) => value != null && mean != null
              ? (value - mean) * (value - mean)
              : null,
        )
        .toList(growable: false);
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
