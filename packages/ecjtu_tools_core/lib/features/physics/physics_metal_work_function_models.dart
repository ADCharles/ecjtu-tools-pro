// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class MetalWorkPointInput {
  const MetalWorkPointInput({required this.voltage, required this.current});

  final String voltage;
  final String current;

  factory MetalWorkPointInput.empty() {
    return const MetalWorkPointInput(voltage: '', current: '');
  }

  factory MetalWorkPointInput.fromJson(Object? value) {
    final source = _metalWorkMap(value);
    return MetalWorkPointInput(
      voltage: _metalWorkText(source['voltage']),
      current: _metalWorkText(source['current']),
    );
  }

  MetalWorkPointInput copyWith({String? voltage, String? current}) {
    return MetalWorkPointInput(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
    );
  }

  MetalWorkPointInput update(String field, String value) {
    return switch (field) {
      'voltage' => copyWith(voltage: value),
      'current' => copyWith(current: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {'voltage': voltage, 'current': current};
}

class MetalWorkGroupInput {
  const MetalWorkGroupInput({
    required this.filamentCurrent,
    required this.temperature,
    required this.points,
  });

  static const pointCount = 8;

  final String filamentCurrent;
  final String temperature;
  final List<MetalWorkPointInput> points;

  factory MetalWorkGroupInput.initial() {
    return MetalWorkGroupInput(
      filamentCurrent: '',
      temperature: '',
      points: List<MetalWorkPointInput>.generate(
        pointCount,
        (_) => MetalWorkPointInput.empty(),
        growable: false,
      ),
    );
  }

  factory MetalWorkGroupInput.fromJson(Object? value) {
    final source = _metalWorkMap(value);
    final fallback = MetalWorkGroupInput.initial();
    final rawPoints = source['points'];
    return MetalWorkGroupInput(
      filamentCurrent: _metalWorkText(source['filamentCurrent']),
      temperature: _metalWorkText(source['temperature']),
      points: List<MetalWorkPointInput>.generate(
        pointCount,
        (index) => MetalWorkPointInput.fromJson(
          rawPoints is List && index < rawPoints.length
              ? rawPoints[index]
              : fallback.points[index],
        ),
        growable: false,
      ),
    );
  }

  MetalWorkGroupInput copyWith({
    String? filamentCurrent,
    String? temperature,
    List<MetalWorkPointInput>? points,
  }) {
    return MetalWorkGroupInput(
      filamentCurrent: filamentCurrent ?? this.filamentCurrent,
      temperature: temperature ?? this.temperature,
      points: List<MetalWorkPointInput>.unmodifiable(points ?? this.points),
    );
  }

  MetalWorkGroupInput updatePoint(int index, String field, String value) {
    if (index < 0 || index >= points.length) return this;
    final next = List<MetalWorkPointInput>.of(points);
    next[index] = next[index].update(field, value);
    return copyWith(points: next);
  }

  Map<String, Object> toJson() => {
    'filamentCurrent': filamentCurrent,
    'temperature': temperature,
    'points': points.map((point) => point.toJson()).toList(growable: false),
  };
}

class MetalWorkState {
  const MetalWorkState({
    required this.groups,
    required this.constant,
    required this.known,
  });

  static const groupCount = 5;

  final List<MetalWorkGroupInput> groups;
  final String constant;
  final String known;

  factory MetalWorkState.initial() {
    return MetalWorkState(
      groups: List<MetalWorkGroupInput>.generate(
        groupCount,
        (_) => MetalWorkGroupInput.initial(),
        growable: false,
      ),
      constant: '5040',
      known: '4.54',
    );
  }

  factory MetalWorkState.fromJson(Object? value) {
    final source = _metalWorkMap(value);
    final fallback = MetalWorkState.initial();
    final rawGroups = source['groups'];
    return MetalWorkState(
      groups: List<MetalWorkGroupInput>.generate(
        groupCount,
        (index) => MetalWorkGroupInput.fromJson(
          rawGroups is List && index < rawGroups.length
              ? rawGroups[index]
              : fallback.groups[index],
        ),
        growable: false,
      ),
      constant: _metalWorkText(source['constant'], fallback.constant),
      known: _metalWorkText(source['known'], fallback.known),
    );
  }

  MetalWorkState copyWith({
    List<MetalWorkGroupInput>? groups,
    String? constant,
    String? known,
  }) {
    return MetalWorkState(
      groups: List<MetalWorkGroupInput>.unmodifiable(groups ?? this.groups),
      constant: constant ?? this.constant,
      known: known ?? this.known,
    );
  }

  MetalWorkState updateGlobal(String field, String value) {
    return switch (field) {
      'constant' => copyWith(constant: value),
      'known' => copyWith(known: value),
      _ => this,
    };
  }

  MetalWorkState updateGroup(
    int index, {
    String? filamentCurrent,
    String? temperature,
  }) {
    if (index < 0 || index >= groups.length) return this;
    final next = List<MetalWorkGroupInput>.of(groups);
    next[index] = next[index].copyWith(
      filamentCurrent: filamentCurrent,
      temperature: temperature,
    );
    return copyWith(groups: next);
  }

  MetalWorkState updatePoint(
    int groupIndex,
    int pointIndex,
    String field,
    String value,
  ) {
    if (groupIndex < 0 || groupIndex >= groups.length) return this;
    final next = List<MetalWorkGroupInput>.of(groups);
    next[groupIndex] = next[groupIndex].updatePoint(pointIndex, field, value);
    return copyWith(groups: next);
  }

  Map<String, Object> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'constant': constant,
    'known': known,
  };
}

class MetalWorkRegressionPoint {
  const MetalWorkRegressionPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};
}

class MetalWorkRegression {
  const MetalWorkRegression({
    required this.valid,
    required this.slope,
    required this.intercept,
    required this.r2,
  });

  final List<MetalWorkRegressionPoint> valid;
  final double? slope;
  final double? intercept;
  final double? r2;

  Map<String, Object?> toJson() => {
    'valid': valid.map((point) => point.toJson()).toList(growable: false),
    'slope': slope,
    'intercept': intercept,
    'r2': r2,
  };
}

class MetalWorkPointCalculation {
  const MetalWorkPointCalculation({
    required this.voltage,
    required this.current,
    required this.sqrtVoltage,
    required this.lgCurrent,
  });

  final double? voltage;
  final double? current;
  final double? sqrtVoltage;
  final double? lgCurrent;

  Map<String, Object?> toJson() => {
    'voltage': voltage,
    'current': current,
    'sqrtVoltage': sqrtVoltage,
    'lgCurrent': lgCurrent,
  };
}

class MetalWorkGroupCalculation {
  const MetalWorkGroupCalculation({
    required this.points,
    required this.filamentCurrent,
    required this.temperature,
    required this.fit,
    required this.lgIT2,
    required this.inverseTemperature,
  });

  final List<MetalWorkPointCalculation> points;
  final double? filamentCurrent;
  final double? temperature;
  final MetalWorkRegression fit;
  final double? lgIT2;
  final double? inverseTemperature;

  Map<String, Object?> toJson() => {
    'points': points.map((point) => point.toJson()).toList(growable: false),
    'filamentCurrent': filamentCurrent,
    'temperature': temperature,
    'fit': fit.toJson(),
    'lgIT2': lgIT2,
    'inverseTemperature': inverseTemperature,
  };
}

class MetalWorkCalculation {
  const MetalWorkCalculation({
    required this.groups,
    required this.fit,
    required this.constant,
    required this.work,
    required this.known,
    required this.relativeError,
  });

  final List<MetalWorkGroupCalculation> groups;
  final MetalWorkRegression fit;
  final double? constant;
  final double? work;
  final double? known;
  final double? relativeError;

  Map<String, Object?> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'fit': fit.toJson(),
    'constant': constant,
    'work': work,
    'known': known,
    'relativeError': relativeError,
  };
}

Map<String, Object?> _metalWorkMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _metalWorkText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}
