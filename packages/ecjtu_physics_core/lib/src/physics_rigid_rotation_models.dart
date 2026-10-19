// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class RigidRotationTimeInput {
  const RigidRotationTimeInput({required this.times});

  static const measurementCount = 3;

  final List<String> times;

  factory RigidRotationTimeInput.empty() {
    return RigidRotationTimeInput(
      times: List<String>.filled(measurementCount, '', growable: false),
    );
  }

  factory RigidRotationTimeInput.fromJson(Object? value) {
    final source = value is Map ? value['times'] : value;
    return RigidRotationTimeInput(
      times: List<String>.generate(
        measurementCount,
        (index) =>
            source is List && index < source.length ? _text(source[index]) : '',
        growable: false,
      ),
    );
  }

  RigidRotationTimeInput copyWith({List<String>? times}) {
    return RigidRotationTimeInput(
      times: List<String>.unmodifiable(times ?? this.times),
    );
  }

  RigidRotationTimeInput updateTime(int index, String value) {
    if (index < 0 || index >= times.length) return this;
    final next = List<String>.of(times);
    next[index] = value;
    return copyWith(times: next);
  }

  Map<String, Object> toJson() => {'times': times.toList(growable: false)};
}

class RigidRotationMassInput {
  const RigidRotationMassInput({required this.mass, required this.times});

  final String mass;
  final List<String> times;

  factory RigidRotationMassInput.empty() {
    return RigidRotationMassInput(
      mass: '',
      times: List<String>.filled(
        RigidRotationTimeInput.measurementCount,
        '',
        growable: false,
      ),
    );
  }

  factory RigidRotationMassInput.fromJson(Object? value) {
    final source = _map(value);
    final fallback = RigidRotationMassInput.empty();
    final rawTimes = source['times'];
    return RigidRotationMassInput(
      mass: _text(source['mass']),
      times: List<String>.generate(
        RigidRotationTimeInput.measurementCount,
        (index) => rawTimes is List && index < rawTimes.length
            ? _text(rawTimes[index])
            : fallback.times[index],
        growable: false,
      ),
    );
  }

  RigidRotationMassInput copyWith({String? mass, List<String>? times}) {
    return RigidRotationMassInput(
      mass: mass ?? this.mass,
      times: List<String>.unmodifiable(times ?? this.times),
    );
  }

  RigidRotationMassInput update(String field, int timeIndex, String value) {
    if (field == 'mass') return copyWith(mass: value);
    if (field != 'time' || timeIndex < 0 || timeIndex >= times.length) {
      return this;
    }
    final next = List<String>.of(times);
    next[timeIndex] = value;
    return copyWith(times: next);
  }

  Map<String, Object> toJson() => {
    'mass': mass,
    'times': times.toList(growable: false),
  };
}

class RigidRotationState {
  const RigidRotationState({
    required this.height,
    required this.gravity,
    required this.diameters,
    required this.massRuns,
    required this.secondMass,
    required this.secondRuns,
  });

  static const diameterCount = 5;
  static const massRunCount = 5;

  final String height;
  final String gravity;
  final List<String> diameters;
  final List<RigidRotationMassInput> massRuns;
  final String secondMass;
  final List<RigidRotationTimeInput> secondRuns;

  factory RigidRotationState.initial() {
    return RigidRotationState(
      height: '',
      gravity: '9.8',
      diameters: List<String>.filled(diameterCount, '', growable: false),
      massRuns: List<RigidRotationMassInput>.generate(
        massRunCount,
        (_) => RigidRotationMassInput.empty(),
        growable: false,
      ),
      secondMass: '',
      secondRuns: List<RigidRotationTimeInput>.generate(
        massRunCount,
        (_) => RigidRotationTimeInput.empty(),
        growable: false,
      ),
    );
  }

  factory RigidRotationState.fromJson(Object? value) {
    final source = _map(value);
    final fallback = RigidRotationState.initial();
    final basic = _map(source['basic']);
    final rawDiameters = basic['diameters'];
    final rawMassRuns = source['massRuns'];
    final second = _map(source['second']);
    final rawSecondRuns = second['times'];
    return RigidRotationState(
      height: _text(basic['h']),
      gravity: _text(basic['g'], fallback.gravity),
      diameters: List<String>.generate(
        diameterCount,
        (index) => rawDiameters is List && index < rawDiameters.length
            ? _text(rawDiameters[index])
            : fallback.diameters[index],
        growable: false,
      ),
      massRuns: List<RigidRotationMassInput>.generate(
        massRunCount,
        (index) => RigidRotationMassInput.fromJson(
          rawMassRuns is List && index < rawMassRuns.length
              ? rawMassRuns[index]
              : fallback.massRuns[index],
        ),
        growable: false,
      ),
      secondMass: _text(second['mass']),
      secondRuns: List<RigidRotationTimeInput>.generate(
        massRunCount,
        (index) => RigidRotationTimeInput.fromJson(
          rawSecondRuns is List && index < rawSecondRuns.length
              ? rawSecondRuns[index]
              : fallback.secondRuns[index],
        ),
        growable: false,
      ),
    );
  }

  RigidRotationState copyWith({
    String? height,
    String? gravity,
    List<String>? diameters,
    List<RigidRotationMassInput>? massRuns,
    String? secondMass,
    List<RigidRotationTimeInput>? secondRuns,
  }) {
    return RigidRotationState(
      height: height ?? this.height,
      gravity: gravity ?? this.gravity,
      diameters: List<String>.unmodifiable(diameters ?? this.diameters),
      massRuns: List<RigidRotationMassInput>.unmodifiable(
        massRuns ?? this.massRuns,
      ),
      secondMass: secondMass ?? this.secondMass,
      secondRuns: List<RigidRotationTimeInput>.unmodifiable(
        secondRuns ?? this.secondRuns,
      ),
    );
  }

  RigidRotationState updateBasic(String field, String value) {
    return switch (field) {
      'height' => copyWith(height: value),
      'gravity' => copyWith(gravity: value),
      _ => this,
    };
  }

  RigidRotationState updateDiameter(int index, String value) {
    if (index < 0 || index >= diameters.length) return this;
    final next = List<String>.of(diameters);
    next[index] = value;
    return copyWith(diameters: next);
  }

  RigidRotationState updateMassRun(
    int index,
    String field,
    int timeIndex,
    String value,
  ) {
    if (index < 0 || index >= massRuns.length) return this;
    final next = List<RigidRotationMassInput>.of(massRuns);
    next[index] = next[index].update(field, timeIndex, value);
    return copyWith(massRuns: next);
  }

  RigidRotationState updateSecondMass(String value) {
    return copyWith(secondMass: value);
  }

  RigidRotationState updateSecondTime(
    int runIndex,
    int timeIndex,
    String value,
  ) {
    if (runIndex < 0 || runIndex >= secondRuns.length) return this;
    final next = List<RigidRotationTimeInput>.of(secondRuns);
    next[runIndex] = next[runIndex].updateTime(timeIndex, value);
    return copyWith(secondRuns: next);
  }

  Map<String, Object> toJson() => {
    'basic': {
      'h': height,
      'g': gravity,
      'diameters': diameters.toList(growable: false),
    },
    'massRuns': massRuns.map((run) => run.toJson()).toList(growable: false),
    'second': {
      'mass': secondMass,
      'times': secondRuns
          .map((run) => run.times.toList(growable: false))
          .toList(growable: false),
    },
  };
}

class RigidRotationRegressionPoint {
  const RigidRotationRegressionPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};
}

class RigidRotationRegression {
  const RigidRotationRegression({
    required this.valid,
    required this.slope,
    required this.intercept,
    required this.r2,
  });

  final List<RigidRotationRegressionPoint> valid;
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

class RigidRotationRunCalculation {
  const RigidRotationRunCalculation({
    required this.times,
    required this.mean,
    required this.square,
    required this.inverseSquare,
    required this.inverseTime,
  });

  final List<double?> times;
  final double? mean;
  final double? square;
  final double? inverseSquare;
  final double? inverseTime;

  Map<String, Object?> toJson() => {
    'times': times,
    'mean': mean,
    'square': square,
    'inverseSquare': inverseSquare,
    'inverseTime': inverseTime,
  };
}

class RigidRotationMassCalculation {
  const RigidRotationMassCalculation({required this.mass, required this.run});

  final double? mass;
  final RigidRotationRunCalculation run;

  Map<String, Object?> toJson() => {'mass': mass, ...run.toJson()};
}

class RigidRotationSecondCalculation {
  const RigidRotationSecondCalculation({
    required this.radius,
    required this.run,
  });

  final double? radius;
  final RigidRotationRunCalculation run;

  Map<String, Object?> toJson() => {'radius': radius, ...run.toJson()};
}

class RigidRotationCalculation {
  const RigidRotationCalculation({
    required this.height,
    required this.gravity,
    required this.diameters,
    required this.massRuns,
    required this.firstFit,
    required this.firstInertia,
    required this.secondMass,
    required this.secondRuns,
    required this.secondFit,
    required this.secondInertia,
    required this.inertia,
  });

  final double? height;
  final double? gravity;
  final List<double?> diameters;
  final List<RigidRotationMassCalculation> massRuns;
  final RigidRotationRegression firstFit;
  final double? firstInertia;
  final double? secondMass;
  final List<RigidRotationSecondCalculation> secondRuns;
  final RigidRotationRegression secondFit;
  final double? secondInertia;
  final double? inertia;

  Map<String, Object?> toJson() => {
    'height': height,
    'gravity': gravity,
    'diameters': diameters,
    'massRuns': massRuns.map((run) => run.toJson()).toList(growable: false),
    'firstFit': firstFit.toJson(),
    'firstInertia': firstInertia,
    'secondMass': secondMass,
    'secondRuns': secondRuns.map((run) => run.toJson()).toList(growable: false),
    'secondFit': secondFit.toJson(),
    'secondInertia': secondInertia,
    'inertia': inertia,
  };
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _text(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}
