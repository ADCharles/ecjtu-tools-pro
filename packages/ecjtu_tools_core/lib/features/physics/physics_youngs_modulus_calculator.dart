// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';
import 'physics_youngs_modulus_models.dart';

class YoungsModulusCalculator {
  const YoungsModulusCalculator._();

  static YoungsModulusCalculation calculate(YoungsModulusState state) {
    final zeroError = _number(state.zeroError);
    final diameter = state.diameter
        .asMap()
        .entries
        .map(
          (entry) => _calculateDiameter(
            index: entry.key,
            input: entry.value,
            zeroError: zeroError,
          ),
        )
        .toList(growable: false);
    final diameterValues = diameter
        .map((item) => item.mean)
        .toList(growable: false);
    final diameterAverage = _average(diameterValues);
    final diameterError = _averageAbsoluteDeviation(diameterValues);

    final scale = state.scale
        .asMap()
        .entries
        .map((entry) => _calculateScale(entry.key, entry.value))
        .toList(growable: false);
    final differences = List<YoungsModulusDifferenceResult>.generate(
      YoungsModulusState.scaleCount ~/ 2,
      (index) => _calculateDifference(index, scale[index], scale[index + 4]),
      growable: false,
    );
    final extension = _average(
      differences.map((item) => item.difference).toList(growable: false),
    );
    final extensionError = _averageAbsoluteDeviation(
      differences.map((item) => item.difference).toList(growable: false),
    );

    final dimensions = YoungsModulusNumericDimensions(
      distance: _number(state.dimensions.distance),
      distanceError: _number(state.dimensions.distanceError),
      length: _number(state.dimensions.length),
      lengthError: _number(state.dimensions.lengthError),
      leverArm: _number(state.dimensions.leverArm),
      leverArmError: _number(state.dimensions.leverArmError),
      massIncrement: _number(state.dimensions.massIncrement),
      gravity: _number(state.dimensions.gravity),
    );
    final diameterMeter = diameterAverage == null
        ? null
        : diameterAverage / 1000;
    final diameterErrorMeter = diameterError == null
        ? null
        : diameterError / 1000;
    final extensionMeter = extension == null ? null : extension / 100;
    final extensionErrorMeter = extensionError == null
        ? null
        : extensionError / 100;
    final force = _product(dimensions.massIncrement, dimensions.gravity);
    final distance = dimensions.distance;
    final length = dimensions.length;
    final leverArm = dimensions.leverArm;
    final distanceError = dimensions.distanceError;
    final lengthError = dimensions.lengthError;
    final leverArmError = dimensions.leverArmError;
    double? young;
    double? relativeError;
    if (_allFinite(<double?>[
          diameterMeter,
          distance,
          length,
          leverArm,
          extensionMeter,
          force,
          diameterError,
          distanceError,
          lengthError,
          leverArmError,
          extensionErrorMeter,
        ]) &&
        diameterMeter != null &&
        distance != null &&
        length != null &&
        leverArm != null &&
        extensionMeter != null &&
        force != null &&
        distanceError != null &&
        lengthError != null &&
        leverArmError != null &&
        diameterErrorMeter != null &&
        extensionErrorMeter != null &&
        diameterMeter > 0 &&
        distance > 0 &&
        length > 0 &&
        leverArm > 0 &&
        extensionMeter > 0 &&
        force > 0) {
      young =
          8 *
          force *
          length *
          distance /
          (3.141592653589793 *
              diameterMeter *
              diameterMeter *
              leverArm *
              extensionMeter);
      relativeError =
          distanceError / distance +
          lengthError / length +
          2 * diameterErrorMeter / diameterMeter +
          leverArmError / leverArm +
          extensionErrorMeter / extensionMeter;
    }
    final absoluteError = young != null && relativeError != null
        ? young * relativeError
        : null;

    return YoungsModulusCalculation(
      zeroError: zeroError,
      diameter: diameter,
      diameterAverageMillimeter: diameterAverage,
      diameterErrorMillimeter: diameterError,
      scale: scale,
      differences: differences,
      extensionCentimeter: extension,
      extensionErrorCentimeter: extensionError,
      dimensions: dimensions,
      force: force,
      young: _finiteOrNull(young),
      relativeError: _finiteOrNull(relativeError),
      absoluteError: _finiteOrNull(absoluteError),
    );
  }

  static YoungsModulusDiameterResult _calculateDiameter({
    required int index,
    required YoungsModulusDiameterInput input,
    required double? zeroError,
  }) {
    final initial = _number(input.initial);
    final fullLoad = _number(input.fullLoad);
    final mean = initial != null && fullLoad != null && zeroError != null
        ? (initial + zeroError + fullLoad + zeroError) / 2
        : null;
    return YoungsModulusDiameterResult(
      index: index,
      initial: initial,
      fullLoad: fullLoad,
      mean: _finiteOrNull(mean),
      complete: _finiteOrNull(mean) != null,
    );
  }

  static YoungsModulusScaleResult _calculateScale(
    int index,
    YoungsModulusScaleInput input,
  ) {
    final add = _number(input.add);
    final remove = _number(input.remove);
    final mean = add != null && remove != null ? (add + remove) / 2 : null;
    return YoungsModulusScaleResult(
      index: index,
      add: add,
      remove: remove,
      mean: _finiteOrNull(mean),
      complete: _finiteOrNull(mean) != null,
    );
  }

  static YoungsModulusDifferenceResult _calculateDifference(
    int index,
    YoungsModulusScaleResult lower,
    YoungsModulusScaleResult upper,
  ) {
    final difference = lower.mean != null && upper.mean != null
        ? (upper.mean! - lower.mean!).abs()
        : null;
    return YoungsModulusDifferenceResult(
      index: index,
      lower: lower.mean,
      upper: upper.mean,
      difference: _finiteOrNull(difference),
      complete: _finiteOrNull(difference) != null,
    );
  }

  static double? _number(Object? value) {
    final parsed = PhysicsDecimal.parse(value);
    if (parsed == null) return null;
    return _finiteOrNull(parsed.toDouble());
  }

  static double? _product(double? left, double? right) {
    if (left == null || right == null) return null;
    return _finiteOrNull(left * right);
  }

  static double? _average(List<double?> values) {
    if (values.isEmpty ||
        values.any((value) => value == null || !value.isFinite)) {
      return null;
    }
    final valid = values.cast<double>();
    return _finiteOrNull(
      valid.reduce((left, right) => left + right) / valid.length,
    );
  }

  static double? _averageAbsoluteDeviation(List<double?> values) {
    final mean = _average(values);
    if (mean == null) return null;
    return _average(
      values.map((value) => (value! - mean).abs()).toList(growable: false),
    );
  }

  static bool _allFinite(Iterable<double?> values) {
    return values.every((value) => value != null && value.isFinite);
  }

  static double? _finiteOrNull(double? value) {
    return value != null && value.isFinite ? value : null;
  }

  static String format(double? value, {int digits = 8}) {
    if (value == null || !value.isFinite) return '—';
    final fixed = value.toStringAsFixed(digits);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
