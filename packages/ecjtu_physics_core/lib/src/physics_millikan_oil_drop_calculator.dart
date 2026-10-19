// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_millikan_oil_drop_models.dart';

class MillikanCalculator {
  const MillikanCalculator._();

  static MillikanCalculation calculate(MillikanState state) {
    final constants = _constants(state.constants);
    final groups = state.groups
        .map((group) => _group(group, constants))
        .toList(growable: false);
    return MillikanCalculation(
      groups: groups,
      electronCharge: constants.electronCharge,
    );
  }

  static _MillikanParsedConstants _constants(MillikanConstants input) {
    return _MillikanParsedConstants(
      g: parse(input.g),
      eta: parse(input.eta),
      rho: parse(input.rho),
      pressure: parse(input.pressure),
      d: parse(input.d),
      l: parse(input.l),
      b: parse(input.b),
      electronCharge: parse(input.electronCharge),
    );
  }

  static MillikanGroupCalculation _group(
    MillikanGroupInput input,
    _MillikanParsedConstants constants,
  ) {
    final voltage = parse(input.voltage);
    final times = input.times.map(parse).toList(growable: false);
    final timeMean = _average(times);
    final radius = _finiteOrNull(
      constants.eta != null &&
              constants.l != null &&
              constants.g != null &&
              constants.rho != null &&
              timeMean != null &&
              constants.g! > 0 &&
              constants.rho! > 0 &&
              timeMean > 0
          ? math.sqrt(
              9 *
                  constants.eta! *
                  constants.l! /
                  (2 * constants.g! * constants.rho! * timeMean),
            )
          : null,
    );
    final correctedTimeFactor = _finiteOrNull(
      constants.eta != null &&
              constants.l != null &&
              constants.b != null &&
              constants.pressure != null &&
              radius != null &&
              timeMean != null &&
              constants.pressure! > 0 &&
              radius > 0 &&
              timeMean > 0
          ? constants.eta! *
                constants.l! /
                (timeMean * (1 + constants.b! / (constants.pressure! * radius)))
          : null,
    );
    final charge = _finiteOrNull(
      constants.rho != null &&
              constants.g != null &&
              correctedTimeFactor != null &&
              constants.d != null &&
              voltage != null &&
              constants.g! > 0 &&
              constants.rho! > 0 &&
              voltage != 0
          ? (18 *
                    math.pi *
                    constants.d! /
                    (math.sqrt(2 * constants.rho! * constants.g!) * voltage)) *
                math.pow(correctedTimeFactor, 1.5).toDouble()
          : null,
    );
    final chargeNumber = _finiteOrNull(
      charge != null &&
              constants.electronCharge != null &&
              constants.electronCharge != 0
          ? charge / constants.electronCharge!
          : null,
    );
    return MillikanGroupCalculation(
      voltage: voltage,
      times: times,
      timeMean: timeMean,
      radius: radius,
      correctedTimeFactor: correctedTimeFactor,
      charge: charge,
      chargeNumber: chargeNumber,
      nearestChargeNumber: chargeNumber?.round(),
    );
  }

  static double? _average(Iterable<double?> values) {
    final usable = values.whereType<double>().toList(growable: false);
    if (usable.isEmpty) return null;
    return usable.reduce((left, right) => left + right) / usable.length;
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

class _MillikanParsedConstants {
  const _MillikanParsedConstants({
    required this.g,
    required this.eta,
    required this.rho,
    required this.pressure,
    required this.d,
    required this.l,
    required this.b,
    required this.electronCharge,
  });

  final double? g;
  final double? eta;
  final double? rho;
  final double? pressure;
  final double? d;
  final double? l;
  final double? b;
  final double? electronCharge;
}
