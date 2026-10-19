// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class SingleArmBridgeState {
  const SingleArmBridgeState({
    required this.r1,
    required this.r2,
    required this.parallel,
  });

  static const measurementCount = 3;

  final List<String> r1;
  final List<String> r2;
  final List<String> parallel;

  factory SingleArmBridgeState.initial() {
    return SingleArmBridgeState(
      r1: List<String>.filled(measurementCount, '', growable: false),
      r2: List<String>.filled(measurementCount, '', growable: false),
      parallel: List<String>.filled(measurementCount, '', growable: false),
    );
  }

  factory SingleArmBridgeState.fromJson(Object? value) {
    final map = _bridgeMap(value);
    return SingleArmBridgeState(
      r1: _bridgeList(map['r1']),
      r2: _bridgeList(map['r2']),
      parallel: _bridgeList(map['parallel']),
    );
  }

  SingleArmBridgeState copyWith({
    List<String>? r1,
    List<String>? r2,
    List<String>? parallel,
  }) {
    return SingleArmBridgeState(
      r1: List<String>.unmodifiable(r1 ?? this.r1),
      r2: List<String>.unmodifiable(r2 ?? this.r2),
      parallel: List<String>.unmodifiable(parallel ?? this.parallel),
    );
  }

  SingleArmBridgeState update(String field, int index, String value) {
    if (index < 0 || index >= measurementCount) return this;
    final values = switch (field) {
      'r1' => List<String>.of(r1),
      'r2' => List<String>.of(r2),
      'parallel' => List<String>.of(parallel),
      _ => null,
    };
    if (values == null || values[index] == value) return this;
    values[index] = value;
    return switch (field) {
      'r1' => copyWith(r1: values),
      'r2' => copyWith(r2: values),
      'parallel' => copyWith(parallel: values),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {'r1': r1, 'r2': r2, 'parallel': parallel};
}

class SingleArmBridgeStatistics {
  const SingleArmBridgeStatistics({
    required this.values,
    required this.average,
    required this.standardDeviation,
  });

  final List<double?> values;
  final double? average;
  final double? standardDeviation;

  Map<String, Object?> toJson() => {
    'values': values,
    'average': average,
    'standardDeviation': standardDeviation,
  };
}

class SingleArmBridgeCalculation {
  const SingleArmBridgeCalculation({
    required this.r1,
    required this.r2,
    required this.parallel,
  });

  final SingleArmBridgeStatistics r1;
  final SingleArmBridgeStatistics r2;
  final SingleArmBridgeStatistics parallel;

  Map<String, Object?> toJson() => {
    'r1': r1.toJson(),
    'r2': r2.toJson(),
    'parallel': parallel.toJson(),
  };
}

Map<String, Object?> _bridgeMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

List<String> _bridgeList(Object? value) {
  if (value is! List) {
    return List<String>.filled(
      SingleArmBridgeState.measurementCount,
      '',
      growable: false,
    );
  }
  return List<String>.generate(
    SingleArmBridgeState.measurementCount,
    (index) => index < value.length ? value[index]?.toString() ?? '' : '',
    growable: false,
  );
}
