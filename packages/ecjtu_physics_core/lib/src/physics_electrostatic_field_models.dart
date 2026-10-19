// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class ElectrostaticParameters {
  const ElectrostaticParameters({
    this.voltage = '12',
    this.innerRadius = '5',
    this.outerRadius = '75',
  });

  final String voltage;
  final String innerRadius;
  final String outerRadius;

  factory ElectrostaticParameters.fromJson(Object? value) {
    final map = _map(value);
    return ElectrostaticParameters(
      voltage: _text(map['voltage'], '12'),
      innerRadius: _text(map['innerRadius'], '5'),
      outerRadius: _text(map['outerRadius'], '75'),
    );
  }

  ElectrostaticParameters copyWith({
    String? voltage,
    String? innerRadius,
    String? outerRadius,
  }) {
    return ElectrostaticParameters(
      voltage: voltage ?? this.voltage,
      innerRadius: innerRadius ?? this.innerRadius,
      outerRadius: outerRadius ?? this.outerRadius,
    );
  }

  Map<String, String> toJson() => {
    'voltage': voltage,
    'innerRadius': innerRadius,
    'outerRadius': outerRadius,
  };
}

class ElectrostaticCoaxialInput {
  const ElectrostaticCoaxialInput({
    required this.potential,
    required this.radii,
  });

  final String potential;
  final List<String> radii;

  factory ElectrostaticCoaxialInput.initial(int index) {
    return ElectrostaticCoaxialInput(
      potential: '${index + 1}',
      radii: List<String>.filled(ElectrostaticFieldState.pointCount, ''),
    );
  }

  factory ElectrostaticCoaxialInput.fromJson(Object? value, int index) {
    final map = _map(value);
    final source = map['radii'];
    return ElectrostaticCoaxialInput(
      potential: '${index + 1}',
      radii: List<String>.generate(
        ElectrostaticFieldState.pointCount,
        (point) =>
            source is List && point < source.length ? _text(source[point]) : '',
        growable: false,
      ),
    );
  }

  ElectrostaticCoaxialInput copyWith({List<String>? radii}) {
    return ElectrostaticCoaxialInput(
      potential: potential,
      radii: List<String>.unmodifiable(radii ?? this.radii),
    );
  }

  Map<String, Object> toJson() => {
    'potential': potential,
    'radii': radii.toList(growable: false),
  };
}

class ElectrostaticParallelInput {
  const ElectrostaticParallelInput({required this.r1, required this.r2});

  final List<String> r1;
  final List<String> r2;

  factory ElectrostaticParallelInput.initial() {
    return ElectrostaticParallelInput(
      r1: List<String>.filled(ElectrostaticFieldState.pointCount, ''),
      r2: List<String>.filled(ElectrostaticFieldState.pointCount, ''),
    );
  }

  factory ElectrostaticParallelInput.fromJson(Object? value) {
    final map = _map(value);
    return ElectrostaticParallelInput(
      r1: _readList(map['r1']),
      r2: _readList(map['r2']),
    );
  }

  ElectrostaticParallelInput copyWith({List<String>? r1, List<String>? r2}) {
    return ElectrostaticParallelInput(
      r1: List<String>.unmodifiable(r1 ?? this.r1),
      r2: List<String>.unmodifiable(r2 ?? this.r2),
    );
  }

  Map<String, Object> toJson() => {
    'r1': r1.toList(growable: false),
    'r2': r2.toList(growable: false),
  };
}

class ElectrostaticFieldState {
  const ElectrostaticFieldState({
    required this.parameters,
    required this.coaxial,
    required this.parallel,
  });

  static const lineCount = 5;
  static const pointCount = 8;

  final ElectrostaticParameters parameters;
  final List<ElectrostaticCoaxialInput> coaxial;
  final ElectrostaticParallelInput parallel;

  factory ElectrostaticFieldState.initial() {
    return ElectrostaticFieldState(
      parameters: const ElectrostaticParameters(),
      coaxial: List<ElectrostaticCoaxialInput>.generate(
        lineCount,
        ElectrostaticCoaxialInput.initial,
        growable: false,
      ),
      parallel: ElectrostaticParallelInput.initial(),
    );
  }

  factory ElectrostaticFieldState.fromJson(Object? value) {
    final map = _map(value);
    final coaxialSource = map['coaxial'];
    return ElectrostaticFieldState(
      parameters: ElectrostaticParameters.fromJson(map['parameters']),
      coaxial: List<ElectrostaticCoaxialInput>.generate(
        lineCount,
        (index) => ElectrostaticCoaxialInput.fromJson(
          coaxialSource is List && index < coaxialSource.length
              ? coaxialSource[index]
              : null,
          index,
        ),
        growable: false,
      ),
      parallel: ElectrostaticParallelInput.fromJson(map['parallel']),
    );
  }

  ElectrostaticFieldState copyWith({
    ElectrostaticParameters? parameters,
    List<ElectrostaticCoaxialInput>? coaxial,
    ElectrostaticParallelInput? parallel,
  }) {
    return ElectrostaticFieldState(
      parameters: parameters ?? this.parameters,
      coaxial: List<ElectrostaticCoaxialInput>.unmodifiable(
        coaxial ?? this.coaxial,
      ),
      parallel: parallel ?? this.parallel,
    );
  }

  ElectrostaticFieldState updateParameter(String field, String value) {
    final next = switch (field) {
      'voltage' => parameters.copyWith(voltage: value),
      'innerRadius' => parameters.copyWith(innerRadius: value),
      'outerRadius' => parameters.copyWith(outerRadius: value),
      _ => parameters,
    };
    return next == parameters ? this : copyWith(parameters: next);
  }

  ElectrostaticFieldState updateCoaxial(int line, int point, String value) {
    if (line < 0 || line >= coaxial.length) return this;
    if (point < 0 || point >= coaxial[line].radii.length) return this;
    final radii = List<String>.of(coaxial[line].radii);
    radii[point] = value;
    final lines = List<ElectrostaticCoaxialInput>.of(coaxial);
    lines[line] = coaxial[line].copyWith(radii: radii);
    return copyWith(coaxial: lines);
  }

  ElectrostaticFieldState updateParallel(
    String field,
    int point,
    String value,
  ) {
    if (point < 0 || point >= pointCount) return this;
    final next = field == 'r1'
        ? _replace(parallel.r1, point, value)
        : field == 'r2'
        ? _replace(parallel.r2, point, value)
        : null;
    if (next == null) return this;
    return copyWith(
      parallel: field == 'r1'
          ? parallel.copyWith(r1: next)
          : parallel.copyWith(r2: next),
    );
  }

  Map<String, Object> toJson() => {
    'parameters': parameters.toJson(),
    'coaxial': coaxial.map((line) => line.toJson()).toList(growable: false),
    'parallel': parallel.toJson(),
  };
}

class ElectrostaticCoaxialRowResult {
  const ElectrostaticCoaxialRowResult({
    required this.index,
    required this.potential,
    required this.radii,
    required this.averageRadius,
    required this.theoreticalPotential,
    required this.relativeError,
    required this.complete,
  });

  final int index;
  final String potential;
  final List<double?> radii;
  final double? averageRadius;
  final double? theoreticalPotential;
  final double? relativeError;
  final bool complete;

  Map<String, Object?> toJson() => {
    'averageRadius': averageRadius,
    'theoreticalPotential': theoreticalPotential,
    'relativeErrorPercent': relativeError,
  };
}

class ElectrostaticParallelRowResult {
  const ElectrostaticParallelRowResult({
    required this.index,
    required this.r1,
    required this.r2,
    required this.ratio,
    required this.complete,
  });

  final int index;
  final double? r1;
  final double? r2;
  final double? ratio;
  final bool complete;
}

class ElectrostaticFieldCalculation {
  const ElectrostaticFieldCalculation({
    required this.geometryError,
    required this.coaxial,
    required this.parallel,
    required this.ratioAverage,
    required this.standardDeviation,
  });

  final String? geometryError;
  final List<ElectrostaticCoaxialRowResult> coaxial;
  final List<ElectrostaticParallelRowResult> parallel;
  final double? ratioAverage;
  final double? standardDeviation;

  bool get hasCoaxialChart => coaxial.any(
    (row) =>
        row.radii.length == ElectrostaticFieldState.pointCount &&
        row.radii.every((value) => value != null && value.isFinite),
  );

  bool get hasParallelChart => parallel.any((row) => row.complete);

  bool get hasAnyChart => hasCoaxialChart || hasParallelChart;

  Map<String, Object?> toJson() => {
    'coaxial': coaxial.map((row) => row.toJson()).toList(growable: false),
    'parallel': {
      'ratios': parallel.map((row) => row.ratio).toList(growable: false),
      'averageRatio': ratioAverage,
      'standardDeviation': standardDeviation,
    },
  };
}

List<String> _readList(Object? value) {
  return List<String>.generate(
    ElectrostaticFieldState.pointCount,
    (index) => value is List && index < value.length ? _text(value[index]) : '',
    growable: false,
  );
}

List<String> _replace(List<String> source, int index, String value) {
  final next = List<String>.of(source);
  next[index] = value;
  return next;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}
