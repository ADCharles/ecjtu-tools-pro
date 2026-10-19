// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class LiquidRefractionAngleInput {
  const LiquidRefractionAngleInput({this.degree = '', this.minute = ''});

  final String degree;
  final String minute;

  LiquidRefractionAngleInput copyWith({String? degree, String? minute}) {
    return LiquidRefractionAngleInput(
      degree: degree ?? this.degree,
      minute: minute ?? this.minute,
    );
  }

  factory LiquidRefractionAngleInput.fromJson(Object? value) {
    final map = _liquidMap(value);
    return LiquidRefractionAngleInput(
      degree: _liquidText(map['degree']),
      minute: _liquidText(map['minute']),
    );
  }

  Map<String, String> toJson() => {'degree': degree, 'minute': minute};
}

class LiquidRefractionTrialInput {
  const LiquidRefractionTrialInput({
    this.limit1 = const LiquidRefractionAngleInput(),
    this.limit2 = const LiquidRefractionAngleInput(),
    this.normal1 = const LiquidRefractionAngleInput(),
    this.normal2 = const LiquidRefractionAngleInput(),
  });

  final LiquidRefractionAngleInput limit1;
  final LiquidRefractionAngleInput limit2;
  final LiquidRefractionAngleInput normal1;
  final LiquidRefractionAngleInput normal2;

  LiquidRefractionTrialInput copyWith({
    LiquidRefractionAngleInput? limit1,
    LiquidRefractionAngleInput? limit2,
    LiquidRefractionAngleInput? normal1,
    LiquidRefractionAngleInput? normal2,
  }) {
    return LiquidRefractionTrialInput(
      limit1: limit1 ?? this.limit1,
      limit2: limit2 ?? this.limit2,
      normal1: normal1 ?? this.normal1,
      normal2: normal2 ?? this.normal2,
    );
  }

  factory LiquidRefractionTrialInput.fromJson(Object? value) {
    final map = _liquidMap(value);
    return LiquidRefractionTrialInput(
      limit1: LiquidRefractionAngleInput.fromJson(map['limit1']),
      limit2: LiquidRefractionAngleInput.fromJson(map['limit2']),
      normal1: LiquidRefractionAngleInput.fromJson(map['normal1']),
      normal2: LiquidRefractionAngleInput.fromJson(map['normal2']),
    );
  }

  Map<String, Object> toJson() => {
    'limit1': limit1.toJson(),
    'limit2': limit2.toJson(),
    'normal1': normal1.toJson(),
    'normal2': normal2.toJson(),
  };
}

class LiquidRefractionState {
  const LiquidRefractionState({
    required this.calibration,
    required this.trials,
  });

  static const trialCount = 3;

  final LiquidRefractionCalibration calibration;
  final List<LiquidRefractionTrialInput> trials;

  factory LiquidRefractionState.initial() {
    return LiquidRefractionState(
      calibration: const LiquidRefractionCalibration(),
      trials: List<LiquidRefractionTrialInput>.filled(
        trialCount,
        const LiquidRefractionTrialInput(),
        growable: false,
      ),
    );
  }

  factory LiquidRefractionState.fromJson(Object? value) {
    final map = _liquidMap(value);
    final source = map['trials'];
    return LiquidRefractionState(
      calibration: LiquidRefractionCalibration.fromJson(map['calibration']),
      trials: List<LiquidRefractionTrialInput>.generate(trialCount, (index) {
        if (source is List && index < source.length) {
          return LiquidRefractionTrialInput.fromJson(source[index]);
        }
        return const LiquidRefractionTrialInput();
      }, growable: false),
    );
  }

  LiquidRefractionState copyWith({
    LiquidRefractionCalibration? calibration,
    List<LiquidRefractionTrialInput>? trials,
  }) {
    return LiquidRefractionState(
      calibration: calibration ?? this.calibration,
      trials: List<LiquidRefractionTrialInput>.unmodifiable(
        trials ?? this.trials,
      ),
    );
  }

  LiquidRefractionState updateCalibration(
    String field,
    String part,
    String value,
  ) {
    final current = calibration.valueFor(field);
    if (current == null) return this;
    final next = current.copyWith(
      degree: part == 'degree' ? value : null,
      minute: part == 'minute' ? value : null,
    );
    return copyWith(calibration: calibration.update(field, next));
  }

  LiquidRefractionState updateTrial(
    int index,
    String field,
    String part,
    String value,
  ) {
    if (index < 0 || index >= trials.length) return this;
    final current = trials[index].valueFor(field);
    if (current == null) return this;
    final next = current.copyWith(
      degree: part == 'degree' ? value : null,
      minute: part == 'minute' ? value : null,
    );
    final nextTrial = trials[index].update(field, next);
    final nextTrials = List<LiquidRefractionTrialInput>.of(trials);
    nextTrials[index] = nextTrial;
    return copyWith(trials: nextTrials);
  }

  Map<String, Object> toJson() => {
    'calibration': calibration.toJson(),
    'trials': trials.map((trial) => trial.toJson()).toList(growable: false),
  };
}

class LiquidRefractionCalibration {
  const LiquidRefractionCalibration({
    this.minimum1 = const LiquidRefractionAngleInput(),
    this.minimum2 = const LiquidRefractionAngleInput(),
    this.reference1 = const LiquidRefractionAngleInput(),
    this.reference2 = const LiquidRefractionAngleInput(),
  });

  final LiquidRefractionAngleInput minimum1;
  final LiquidRefractionAngleInput minimum2;
  final LiquidRefractionAngleInput reference1;
  final LiquidRefractionAngleInput reference2;

  factory LiquidRefractionCalibration.fromJson(Object? value) {
    final map = _liquidMap(value);
    return LiquidRefractionCalibration(
      minimum1: LiquidRefractionAngleInput.fromJson(map['minimum1']),
      minimum2: LiquidRefractionAngleInput.fromJson(map['minimum2']),
      reference1: LiquidRefractionAngleInput.fromJson(map['reference1']),
      reference2: LiquidRefractionAngleInput.fromJson(map['reference2']),
    );
  }

  LiquidRefractionAngleInput? valueFor(String field) => switch (field) {
    'minimum1' => minimum1,
    'minimum2' => minimum2,
    'reference1' => reference1,
    'reference2' => reference2,
    _ => null,
  };

  LiquidRefractionCalibration update(
    String field,
    LiquidRefractionAngleInput value,
  ) => switch (field) {
    'minimum1' => copyWith(minimum1: value),
    'minimum2' => copyWith(minimum2: value),
    'reference1' => copyWith(reference1: value),
    'reference2' => copyWith(reference2: value),
    _ => this,
  };

  LiquidRefractionCalibration copyWith({
    LiquidRefractionAngleInput? minimum1,
    LiquidRefractionAngleInput? minimum2,
    LiquidRefractionAngleInput? reference1,
    LiquidRefractionAngleInput? reference2,
  }) {
    return LiquidRefractionCalibration(
      minimum1: minimum1 ?? this.minimum1,
      minimum2: minimum2 ?? this.minimum2,
      reference1: reference1 ?? this.reference1,
      reference2: reference2 ?? this.reference2,
    );
  }

  Map<String, Object> toJson() => {
    'minimum1': minimum1.toJson(),
    'minimum2': minimum2.toJson(),
    'reference1': reference1.toJson(),
    'reference2': reference2.toJson(),
  };
}

extension on LiquidRefractionTrialInput {
  LiquidRefractionAngleInput? valueFor(String field) => switch (field) {
    'limit1' => limit1,
    'limit2' => limit2,
    'normal1' => normal1,
    'normal2' => normal2,
    _ => null,
  };

  LiquidRefractionTrialInput update(
    String field,
    LiquidRefractionAngleInput value,
  ) => switch (field) {
    'limit1' => copyWith(limit1: value),
    'limit2' => copyWith(limit2: value),
    'normal1' => copyWith(normal1: value),
    'normal2' => copyWith(normal2: value),
    _ => this,
  };
}

class LiquidRefractionRowCalculation {
  const LiquidRefractionRowCalculation({
    required this.index,
    required this.limit1,
    required this.limit2,
    required this.normal1,
    required this.normal2,
    required this.limitAngle,
    required this.liquidIndex,
  });

  final int index;
  final double limit1;
  final double limit2;
  final double normal1;
  final double normal2;
  final double limitAngle;
  final double liquidIndex;

  Map<String, Object> toJson() => {
    'index': index + 1,
    'limit1': limit1,
    'limit2': limit2,
    'normal1': normal1,
    'normal2': normal2,
    'limitAngle': limitAngle,
    'liquidIndex': liquidIndex,
  };
}

class LiquidRefractionCalculation {
  const LiquidRefractionCalculation({
    required this.hasAnyInput,
    required this.calibrationDegrees,
    required this.minimumDeviation,
    required this.prismIndex,
    required this.rows,
    required this.average,
    required this.standardDeviation,
    required this.error,
  });

  final bool hasAnyInput;
  final List<double>? calibrationDegrees;
  final double? minimumDeviation;
  final double? prismIndex;
  final List<LiquidRefractionRowCalculation> rows;
  final double? average;
  final double? standardDeviation;
  final String error;

  Map<String, Object?> toJson() => {
    'calibrationDegrees': calibrationDegrees,
    'minimumDeviation': minimumDeviation,
    'prismIndex': prismIndex,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'average': average,
    'standardDeviation': standardDeviation,
    'error': error,
  };
}

Map<String, Object?> _liquidMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _liquidText(Object? value) => value == null ? '' : value.toString();
