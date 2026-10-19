// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class SoundSpeedState {
  const SoundSpeedState({
    required this.frequency,
    required this.frequencyUncertainty,
    required this.temperature,
    required this.standing,
    required this.phase,
  });

  static const measurementCount = 10;
  static const differenceCount = 5;
  static const defaultFrequencyUncertainty = '0.0001';

  final String frequency;
  final String frequencyUncertainty;
  final String temperature;
  final List<String> standing;
  final List<String> phase;

  factory SoundSpeedState.initial() {
    return SoundSpeedState(
      frequency: '',
      frequencyUncertainty: defaultFrequencyUncertainty,
      temperature: '',
      standing: List<String>.filled(measurementCount, ''),
      phase: List<String>.filled(measurementCount, ''),
    );
  }

  factory SoundSpeedState.fromJson(Object? value) {
    final map = _soundMap(value);
    final fallback = SoundSpeedState.initial();
    return SoundSpeedState(
      frequency: _soundText(map['frequency'] ?? map['f']),
      frequencyUncertainty: _soundText(
        map['sigmaFrequency'] ?? map['sigmaF'],
        fallback.frequencyUncertainty,
      ),
      temperature: _soundText(map['temperature']),
      standing: _soundList(map['standing']),
      phase: _soundList(map['phase']),
    );
  }

  SoundSpeedState copyWith({
    String? frequency,
    String? frequencyUncertainty,
    String? temperature,
    List<String>? standing,
    List<String>? phase,
  }) {
    return SoundSpeedState(
      frequency: frequency ?? this.frequency,
      frequencyUncertainty: frequencyUncertainty ?? this.frequencyUncertainty,
      temperature: temperature ?? this.temperature,
      standing: List<String>.unmodifiable(standing ?? this.standing),
      phase: List<String>.unmodifiable(phase ?? this.phase),
    );
  }

  SoundSpeedState updateGlobal(String field, String value) {
    return switch (field) {
      'frequency' => copyWith(frequency: value),
      'frequencyUncertainty' => copyWith(frequencyUncertainty: value),
      'temperature' => copyWith(temperature: value),
      _ => this,
    };
  }

  SoundSpeedState updateMeasurement(String method, int index, String value) {
    if (index < 0 || index >= measurementCount) return this;
    final values = switch (method) {
      'standing' => List<String>.of(standing),
      'phase' => List<String>.of(phase),
      _ => null,
    };
    if (values == null || values[index] == value) return this;
    values[index] = value;
    return method == 'standing'
        ? copyWith(standing: values)
        : copyWith(phase: values);
  }

  Map<String, Object> toJson() => {
    'frequency': frequency,
    'sigmaFrequency': frequencyUncertainty,
    'temperature': temperature,
    'standing': standing,
    'phase': phase,
  };
}

class SoundSpeedMethodCalculation {
  const SoundSpeedMethodCalculation({
    required this.differences,
    required this.average,
    required this.sigmaDifference,
    required this.speed,
    required this.sigmaSpeed,
    required this.relativeError,
    this.message = '',
  });

  final List<double> differences;
  final double? average;
  final double? sigmaDifference;
  final double? speed;
  final double? sigmaSpeed;
  final double? relativeError;
  final String message;

  bool get complete => message.isEmpty;

  Map<String, Object?> toJson() => {
    'differences': differences,
    'average': average,
    'sigmaDifference': sigmaDifference,
    'speed': speed,
    'sigmaSpeed': sigmaSpeed,
    'relativeError': relativeError,
    'message': message,
  };
}

class SoundSpeedCalculation {
  const SoundSpeedCalculation({
    required this.theorySpeed,
    required this.standing,
    required this.phase,
    required this.error,
  });

  final double? theorySpeed;
  final SoundSpeedMethodCalculation standing;
  final SoundSpeedMethodCalculation phase;
  final String error;

  Map<String, Object?> toJson() => {
    'theorySpeed': theorySpeed,
    'error': error,
    'standing': standing.toJson(),
    'phase': phase.toJson(),
  };
}

Map<String, Object?> _soundMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _soundText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}

List<String> _soundList(Object? value) {
  if (value is! List) {
    return List<String>.filled(SoundSpeedState.measurementCount, '');
  }
  return List<String>.generate(
    SoundSpeedState.measurementCount,
    (index) => index < value.length ? _soundText(value[index]) : '',
    growable: false,
  );
}
