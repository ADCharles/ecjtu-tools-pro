// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_liquid_refraction_models.dart';

class LiquidRefractionCalculator {
  const LiquidRefractionCalculator._();

  static LiquidRefractionCalculation calculate(LiquidRefractionState state) {
    final hasAnyInput = _hasAnyInput(state);
    final calibrationAngles = [
      _parseAngle(state.calibration.minimum1),
      _parseAngle(state.calibration.minimum2),
      _parseAngle(state.calibration.reference1),
      _parseAngle(state.calibration.reference2),
    ];
    if (calibrationAngles.any((value) => value == null)) {
      return _result(hasAnyInput: hasAnyInput, error: '请填写有效的棱镜标定角度');
    }
    final validCalibration = calibrationAngles.whereType<double>().toList(
      growable: false,
    );

    final minimum1 = validCalibration[0];
    final minimum2 = validCalibration[1];
    final reference1 = validCalibration[2];
    final reference2 = validCalibration[3];
    final minimumDeviation =
        ((minimum2 - reference2).abs() + (minimum1 - reference1).abs()) / 2;
    final prismIndex =
        2 * math.sin(_degreesToRadians((60 + minimumDeviation) / 2));
    if (!_isFinitePositive(prismIndex)) {
      return _result(
        hasAnyInput: hasAnyInput,
        calibrationDegrees: validCalibration,
        minimumDeviation: minimumDeviation,
        error: '棱镜折射率计算失败，请检查角度数据',
      );
    }

    final rows = <LiquidRefractionRowCalculation>[];
    for (var index = 0; index < state.trials.length; index++) {
      final trial = state.trials[index];
      final values = [
        _parseAngle(trial.limit1),
        _parseAngle(trial.limit2),
        _parseAngle(trial.normal1),
        _parseAngle(trial.normal2),
      ];
      if (values.any((value) => value == null)) {
        return _result(
          hasAnyInput: hasAnyInput,
          calibrationDegrees: validCalibration,
          minimumDeviation: minimumDeviation,
          prismIndex: prismIndex,
          error: '第 ${index + 1} 组角度输入有误，请填写 0—59 分的完整角度',
        );
      }

      final limit1 = values[0]!;
      final limit2 = values[1]!;
      final normal1 = values[2]!;
      final normal2 = values[3]!;
      final limitAngle =
          ((normal2 - limit2).abs() + (normal1 - limit1).abs()) / 2;
      final sine = math.sin(_degreesToRadians(limitAngle.abs()));
      final radicand = prismIndex * prismIndex - sine * sine;
      if (!_isFiniteNonNegative(radicand)) {
        return _result(
          hasAnyInput: hasAnyInput,
          calibrationDegrees: validCalibration,
          minimumDeviation: minimumDeviation,
          prismIndex: prismIndex,
          error: '第 ${index + 1} 组角度无法计算液体折射率，请检查输入',
        );
      }
      final liquidIndex = math.sqrt(3) / 2 * math.sqrt(radicand) - 0.5 * sine;
      if (!_isFinitePositive(liquidIndex)) {
        return _result(
          hasAnyInput: hasAnyInput,
          calibrationDegrees: validCalibration,
          minimumDeviation: minimumDeviation,
          prismIndex: prismIndex,
          error: '第 ${index + 1} 组角度无法计算液体折射率，请检查输入',
        );
      }
      rows.add(
        LiquidRefractionRowCalculation(
          index: index,
          limit1: limit1,
          limit2: limit2,
          normal1: normal1,
          normal2: normal2,
          limitAngle: limitAngle,
          liquidIndex: liquidIndex,
        ),
      );
    }

    final average =
        rows
            .map((row) => row.liquidIndex)
            .reduce((left, right) => left + right) /
        rows.length;
    final variance =
        rows
            .map((row) => math.pow(row.liquidIndex - average, 2).toDouble())
            .reduce((left, right) => left + right) /
        (rows.length - 1);
    final standardDeviation = math.sqrt(variance);
    return _result(
      hasAnyInput: hasAnyInput,
      calibrationDegrees: validCalibration,
      minimumDeviation: minimumDeviation,
      prismIndex: prismIndex,
      rows: rows,
      average: average,
      standardDeviation: standardDeviation,
    );
  }

  static String format(double? value, {int digits = 15}) {
    if (value == null || !value.isFinite) return '—';
    final fixed = value.toStringAsFixed(digits);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }

  static LiquidRefractionCalculation _result({
    required bool hasAnyInput,
    String error = '',
    List<double>? calibrationDegrees,
    double? minimumDeviation,
    double? prismIndex,
    List<LiquidRefractionRowCalculation> rows = const [],
    double? average,
    double? standardDeviation,
  }) {
    return LiquidRefractionCalculation(
      hasAnyInput: hasAnyInput,
      calibrationDegrees: calibrationDegrees,
      minimumDeviation: minimumDeviation,
      prismIndex: prismIndex,
      rows: rows,
      average: average,
      standardDeviation: standardDeviation,
      error: error,
    );
  }

  static double? _parseAngle(LiquidRefractionAngleInput input) {
    final degree = PhysicsDecimal.parse(input.degree);
    final minute = PhysicsDecimal.parse(
      input.minute.trim().isEmpty ? '0' : input.minute,
    );
    if (degree == null || minute == null) return null;
    if (degree.coefficient < BigInt.zero || minute.coefficient < BigInt.zero) {
      return null;
    }
    final degreeValue = degree.toDouble();
    final minuteValue = minute.toDouble();
    if (!degreeValue.isFinite || !minuteValue.isFinite || minuteValue >= 60) {
      return null;
    }
    final angle = degreeValue + minuteValue / 60;
    return angle.isFinite && angle <= 360 ? angle : null;
  }

  static bool _hasAnyInput(LiquidRefractionState state) {
    bool hasAngle(LiquidRefractionAngleInput input) =>
        input.degree.trim().isNotEmpty || input.minute.trim().isNotEmpty;

    return [
      state.calibration.minimum1,
      state.calibration.minimum2,
      state.calibration.reference1,
      state.calibration.reference2,
      ...state.trials.expand(
        (trial) => [trial.limit1, trial.limit2, trial.normal1, trial.normal2],
      ),
    ].any(hasAngle);
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  static bool _isFinitePositive(double value) => value.isFinite && value > 0;

  static bool _isFiniteNonNegative(double value) =>
      value.isFinite && value >= 0;
}
