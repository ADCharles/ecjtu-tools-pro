// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_metal_work_function_models.dart';

class MetalWorkCalculator {
  const MetalWorkCalculator._();

  static MetalWorkCalculation calculate(MetalWorkState state) {
    final groups = state.groups.map(_group).toList(growable: false);
    final fit = _regression(
      groups.map(
        (group) => group.inverseTemperature != null && group.lgIT2 != null
            ? MetalWorkRegressionPoint(
                x: group.inverseTemperature!,
                y: group.lgIT2!,
              )
            : null,
      ),
    );
    final constant = parse(state.constant);
    final work = _finiteOrNull(
      fit.slope != null && constant != null && constant != 0
          ? fit.slope!.abs() / constant
          : null,
    );
    final known = parse(state.known);
    final relativeError = _finiteOrNull(
      work != null && known != null && known != 0
          ? (work - known).abs() / known.abs()
          : null,
    );
    return MetalWorkCalculation(
      groups: groups,
      fit: fit,
      constant: constant,
      work: work,
      known: known,
      relativeError: relativeError,
    );
  }

  static MetalWorkGroupCalculation _group(MetalWorkGroupInput input) {
    final points = input.points
        .map((point) {
          final voltage = parse(point.voltage);
          final current = parse(point.current);
          return MetalWorkPointCalculation(
            voltage: voltage,
            current: current,
            sqrtVoltage: _finiteOrNull(
              voltage != null && voltage >= 0 ? math.sqrt(voltage) : null,
            ),
            lgCurrent: _finiteOrNull(
              current != null && current > 0 ? _log10(current) : null,
            ),
          );
        })
        .toList(growable: false);
    final fit = _regression(
      points
          .where(
            (point) => point.sqrtVoltage != null && point.lgCurrent != null,
          )
          .map(
            (point) => MetalWorkRegressionPoint(
              x: point.sqrtVoltage!,
              y: point.lgCurrent!,
            ),
          ),
    );
    final filamentCurrent = parse(input.filamentCurrent);
    final temperature = parse(input.temperature);
    final lgIT2 = _finiteOrNull(
      fit.intercept != null && temperature != null && temperature > 0
          ? fit.intercept! - 2 * _log10(temperature)
          : null,
    );
    final inverseTemperature = _finiteOrNull(
      temperature != null && temperature > 0 ? 1 / temperature : null,
    );
    return MetalWorkGroupCalculation(
      points: points,
      filamentCurrent: filamentCurrent,
      temperature: temperature,
      fit: fit,
      lgIT2: lgIT2,
      inverseTemperature: inverseTemperature,
    );
  }

  static MetalWorkRegression _regression(
    Iterable<MetalWorkRegressionPoint?> points,
  ) {
    final usable = points
        .whereType<MetalWorkRegressionPoint>()
        .where((point) => point.x.isFinite && point.y.isFinite)
        .toList(growable: false);
    if (usable.length < 2) {
      return MetalWorkRegression(
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
      return MetalWorkRegression(
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
    return MetalWorkRegression(
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

  static double _log10(double value) => math.log(value) / math.ln10;

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
