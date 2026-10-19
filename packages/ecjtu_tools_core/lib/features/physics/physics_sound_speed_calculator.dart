// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'physics_decimal.dart';
import 'physics_sound_speed_models.dart';

class SoundSpeedCalculator {
  const SoundSpeedCalculator._();

  static SoundSpeedCalculation calculate(SoundSpeedState state) {
    final frequency = _parse(state.frequency);
    final sigmaFrequency = _parse(state.frequencyUncertainty);
    final temperature = _parse(state.temperature);
    if (frequency == null ||
        frequency <= 0 ||
        sigmaFrequency == null ||
        sigmaFrequency < 0 ||
        temperature == null) {
      return SoundSpeedCalculation(
        theorySpeed: null,
        standing: _emptyMethod(),
        phase: _emptyMethod(),
        error: '请先填写有效的 f、σf 和温度 t',
      );
    }

    final radicand = 1 + temperature / 273.15;
    if (radicand < 0) {
      return SoundSpeedCalculation(
        theorySpeed: null,
        standing: _emptyMethod(),
        phase: _emptyMethod(),
        error: '温度不能低于绝对零度',
      );
    }
    final theorySpeed = 331.45 * math.sqrt(radicand);
    return SoundSpeedCalculation(
      theorySpeed: theorySpeed,
      standing: _calculateMethod(
        state.standing,
        frequency,
        sigmaFrequency,
        theorySpeed,
      ),
      phase: _calculateMethod(
        state.phase,
        frequency,
        sigmaFrequency,
        theorySpeed,
      ),
      error: '',
    );
  }

  static SoundSpeedMethodCalculation _calculateMethod(
    List<String> values,
    double frequency,
    double sigmaFrequency,
    double theorySpeed,
  ) {
    final parsed = values.map(_parse).toList(growable: false);
    if (parsed.any((value) => value == null)) {
      return _emptyMethod();
    }

    final differences = List<double>.generate(
      SoundSpeedState.differenceCount,
      (index) =>
          parsed[index + SoundSpeedState.differenceCount]! - parsed[index]!,
      growable: false,
    );
    final average =
        differences.reduce((left, right) => left + right) /
        SoundSpeedState.differenceCount;
    final varianceSum = differences.fold<double>(
      0,
      (sum, value) => sum + math.pow(value - average, 2).toDouble(),
    );
    final sigmaDifference = math.sqrt(
      varianceSum / (SoundSpeedState.differenceCount - 1),
    );
    final speed = 0.4 * frequency * average;
    final sigmaRatio = average == 0 ? null : sigmaDifference / average.abs();
    final frequencyRatio = frequency == 0
        ? null
        : sigmaFrequency / frequency.abs();
    final relativeUncertainty = sigmaRatio == null || frequencyRatio == null
        ? null
        : math.sqrt(sigmaRatio * sigmaRatio + frequencyRatio * frequencyRatio);
    final sigmaSpeed = relativeUncertainty == null
        ? null
        : speed * relativeUncertainty;
    final relativeError = theorySpeed == 0
        ? null
        : (theorySpeed - speed).abs() / theorySpeed * 100;
    return SoundSpeedMethodCalculation(
      differences: differences,
      average: average,
      sigmaDifference: sigmaDifference,
      speed: speed,
      sigmaSpeed: sigmaSpeed,
      relativeError: relativeError,
    );
  }

  static SoundSpeedMethodCalculation _emptyMethod() {
    return const SoundSpeedMethodCalculation(
      differences: [],
      average: null,
      sigmaDifference: null,
      speed: null,
      sigmaSpeed: null,
      relativeError: null,
      message: '请填写该方法的 x1—x10 全部数据',
    );
  }

  static double? _parse(Object? value) {
    final decimal = PhysicsDecimal.parse(value);
    if (decimal == null) return null;
    final number = decimal.toDouble();
    return number.isFinite ? number : null;
  }

  static String format(double? value, {int digits = 15}) {
    if (value == null || !value.isFinite) return '—';
    final fixed = value.toStringAsFixed(digits);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
