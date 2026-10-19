// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_franck_hertz_models.dart';

class FranckHertzCalculator {
  const FranckHertzCalculator._();

  static final _three = PhysicsDecimal.fromInt(3);

  static FranckHertzCalculation calculate(FranckHertzState state) {
    final peaks = state.peaks.map(_parse).toList(growable: false);
    final differences = List<PhysicsDecimal?>.generate(
      3,
      (index) => peaks[index] != null && peaks[index + 3] != null
          ? peaks[index + 3]! - peaks[index]!
          : null,
      growable: false,
    );
    final excitations = differences
        .map((value) => value?.divide(_three))
        .toList(growable: false);
    final excitationAverage = _average(excitations);
    final standardDeviation = _sampleStandardDeviation(excitations);
    final standardError = standardDeviation == null
        ? null
        : standardDeviation / math.sqrt(3);
    final theory = _parse(state.theory);
    final relativeError =
        excitationAverage != null && theory != null && !theory.isZero
        ? (excitationAverage.toDouble() - theory.toDouble()).abs() /
              theory.toDouble().abs()
        : null;
    final rows = state.rows
        .map(
          (row) => FranckHertzPointResult(
            voltage: _parse(row.voltage),
            current: _parse(row.current),
          ),
        )
        .toList(growable: false);
    return FranckHertzCalculation(
      rows: rows,
      peaks: peaks,
      differences: differences,
      excitations: excitations,
      excitationAverage: excitationAverage,
      standardDeviation: standardDeviation,
      standardError: standardError,
      theory: theory,
      relativeError: relativeError,
    );
  }

  static PhysicsDecimal? _parse(Object? value) => PhysicsDecimal.parse(value);

  static PhysicsDecimal? _average(Iterable<PhysicsDecimal?> values) {
    final usable = values.whereType<PhysicsDecimal>().toList(growable: false);
    if (usable.isEmpty) return null;
    final total = usable.reduce((left, right) => left + right);
    return total.divide(PhysicsDecimal.fromInt(usable.length));
  }

  static double? _sampleStandardDeviation(Iterable<PhysicsDecimal?> values) {
    final usable = values
        .whereType<PhysicsDecimal>()
        .map((value) => value.toDouble())
        .toList(growable: false);
    if (usable.length < 2) return null;
    final mean = usable.reduce((left, right) => left + right) / usable.length;
    final variance =
        usable
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((left, right) => left + right) /
        (usable.length - 1);
    return math.sqrt(variance);
  }

  static String format(PhysicsDecimal? value, {int digits = 6}) {
    if (value == null) return '—';
    return formatDouble(value.toDouble(), digits: digits);
  }

  static String formatDouble(double? value, {int digits = 6}) {
    if (value == null || !value.isFinite) return '—';
    if (value == 0) return '0';
    final absolute = value.abs();
    if (absolute >= 1e6 || absolute < 1e-4) {
      var result = value.toStringAsExponential(math.max(1, digits));
      result = result.replaceFirst(RegExp(r'(\.\d*?[1-9])0+e'), r'$1e');
      result = result.replaceFirst(RegExp(r'\.0+e'), 'e');
      return result;
    }
    final result = value.toStringAsFixed(digits);
    final trimmed = result
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
