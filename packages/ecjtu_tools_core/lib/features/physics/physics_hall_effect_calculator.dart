// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_hall_effect_models.dart';

class HallEffectCalculator {
  const HallEffectCalculator._();

  static final _four = PhysicsDecimal.fromInt(4);
  static final _factor = PhysicsDecimal.fromInt(170);

  static HallEffectCalculation calculate(HallEffectState state) {
    final solenoid = state.solenoid.rows
        .map((row) => point(row.x, row.reading, state.solenoid.current))
        .toList(growable: false);
    final coils = state.coils
        .map(
          (coil) => coil.rows
              .map((row) {
                final a = point(row.x, row.a, coil.currents.a);
                final b = point(row.x, row.b, coil.currents.b);
                final combined = point(
                  row.x,
                  row.combined,
                  coil.currents.combined,
                );
                final sum = a.field != null && b.field != null
                    ? a.field! + b.field!
                    : null;
                final difference = combined.field != null && sum != null
                    ? combined.field! - sum
                    : null;
                return HallEffectCoilRowResult(
                  x: _parse(row.x),
                  a: a,
                  b: b,
                  combined: combined,
                  sum: sum,
                  difference: difference,
                );
              })
              .toList(growable: false),
        )
        .toList(growable: false);
    return HallEffectCalculation(solenoid: solenoid, coils: coils);
  }

  static HallEffectPointResult point(
    String x,
    HallEffectReading reading,
    String current,
  ) {
    final values = [
      _parse(reading.pp),
      _parse(reading.nn),
      _parse(reading.pn),
      _parse(reading.np),
    ];
    final hallVoltage = values.every(_valid)
        ? (values[0]! + values[1]! - values[2]! - values[3]!).divide(_four)
        : null;
    final currentValue = _parse(current);
    final field = hallVoltage != null && currentValue != null
        ? currentValue.isZero
              ? null
              : hallVoltage.divide(_factor * currentValue)
        : null;
    return HallEffectPointResult(
      x: _parse(x),
      hallVoltage: hallVoltage,
      field: field,
    );
  }

  static PhysicsDecimal? _parse(Object? value) => PhysicsDecimal.parse(value);

  static bool _valid(PhysicsDecimal? value) => value != null;

  static String format(PhysicsDecimal? value, {int digits = 6}) {
    if (value == null) return '—';
    final number = value.toDouble();
    if (!number.isFinite) return '—';
    if (number == 0) return '0';
    final absolute = number.abs();
    if (absolute >= 1e6 || absolute < 1e-4) {
      var result = number.toStringAsExponential(math.max(1, digits));
      result = result.replaceFirst(RegExp(r'(\.\d*?[1-9])0+e'), r'$1e');
      result = result.replaceFirst(RegExp(r'\.0+e'), 'e');
      return result;
    }
    final result = number.toStringAsFixed(digits);
    final trimmed = result
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
