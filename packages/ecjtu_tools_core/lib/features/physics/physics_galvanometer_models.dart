// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class GalvanometerCriticalInput {
  const GalvanometerCriticalInput({
    this.rc = '620',
    this.ra = '10000',
    this.rb = '1',
    this.dm = '40',
  });

  final String rc;
  final String ra;
  final String rb;
  final String dm;

  factory GalvanometerCriticalInput.initial() =>
      const GalvanometerCriticalInput();

  factory GalvanometerCriticalInput.fromJson(Object? value) {
    final map = _map(value);
    return GalvanometerCriticalInput(
      rc: _text(map['rc'], '620'),
      ra: _text(map['ra'], '10000'),
      rb: _text(map['rb'], '1'),
      dm: _text(map['dm'], '40'),
    );
  }

  GalvanometerCriticalInput copyWith({
    String? rc,
    String? ra,
    String? rb,
    String? dm,
  }) {
    return GalvanometerCriticalInput(
      rc: rc ?? this.rc,
      ra: ra ?? this.ra,
      rb: rb ?? this.rb,
      dm: dm ?? this.dm,
    );
  }

  Map<String, String> toJson() => {'rc': rc, 'ra': ra, 'rb': rb, 'dm': dm};
}

class GalvanometerResistanceInput {
  const GalvanometerResistanceInput({
    this.uLow = '',
    this.rLow = '',
    this.uHigh = '',
    this.rHigh = '',
  });

  final String uLow;
  final String rLow;
  final String uHigh;
  final String rHigh;

  factory GalvanometerResistanceInput.fromJson(Object? value) {
    final map = _map(value);
    return GalvanometerResistanceInput(
      uLow: _text(map['uLow']),
      rLow: _text(map['rLow']),
      uHigh: _text(map['uHigh']),
      rHigh: _text(map['rHigh']),
    );
  }

  GalvanometerResistanceInput copyWith({
    String? uLow,
    String? rLow,
    String? uHigh,
    String? rHigh,
  }) {
    return GalvanometerResistanceInput(
      uLow: uLow ?? this.uLow,
      rLow: rLow ?? this.rLow,
      uHigh: uHigh ?? this.uHigh,
      rHigh: rHigh ?? this.rHigh,
    );
  }

  Map<String, String> toJson() => {
    'uLow': uLow,
    'rLow': rLow,
    'uHigh': uHigh,
    'rHigh': rHigh,
  };
}

class GalvanometerSensitivityInput {
  const GalvanometerSensitivityInput({this.u = '', this.d = ''});

  final String u;
  final String d;

  factory GalvanometerSensitivityInput.fromJson(Object? value) {
    final map = _map(value);
    return GalvanometerSensitivityInput(u: _text(map['u']), d: _text(map['d']));
  }

  GalvanometerSensitivityInput copyWith({String? u, String? d}) {
    return GalvanometerSensitivityInput(u: u ?? this.u, d: d ?? this.d);
  }

  Map<String, String> toJson() => {'u': u, 'd': d};
}

class GalvanometerState {
  const GalvanometerState({
    required this.critical,
    required this.resistance,
    required this.sensitivity,
  });

  static const resistanceCount = 5;
  static const sensitivityCount = 6;

  final GalvanometerCriticalInput critical;
  final List<GalvanometerResistanceInput> resistance;
  final List<GalvanometerSensitivityInput> sensitivity;

  factory GalvanometerState.initial() {
    return GalvanometerState(
      critical: GalvanometerCriticalInput.initial(),
      resistance: List<GalvanometerResistanceInput>.generate(
        resistanceCount,
        (_) => const GalvanometerResistanceInput(),
        growable: false,
      ),
      sensitivity: List<GalvanometerSensitivityInput>.generate(
        sensitivityCount,
        (_) => const GalvanometerSensitivityInput(),
        growable: false,
      ),
    );
  }

  factory GalvanometerState.fromJson(Object? value) {
    final map = _map(value);
    final initial = GalvanometerState.initial();
    final resistanceSource = map['resistance'];
    final sensitivitySource = map['sensitivity'];
    return GalvanometerState(
      critical: GalvanometerCriticalInput.fromJson(map['critical']),
      resistance: List<GalvanometerResistanceInput>.generate(
        resistanceCount,
        (index) => GalvanometerResistanceInput.fromJson(
          resistanceSource is List && index < resistanceSource.length
              ? resistanceSource[index]
              : initial.resistance[index],
        ),
        growable: false,
      ),
      sensitivity: List<GalvanometerSensitivityInput>.generate(
        sensitivityCount,
        (index) => GalvanometerSensitivityInput.fromJson(
          sensitivitySource is List && index < sensitivitySource.length
              ? sensitivitySource[index]
              : initial.sensitivity[index],
        ),
        growable: false,
      ),
    );
  }

  GalvanometerState copyWith({
    GalvanometerCriticalInput? critical,
    List<GalvanometerResistanceInput>? resistance,
    List<GalvanometerSensitivityInput>? sensitivity,
  }) {
    return GalvanometerState(
      critical: critical ?? this.critical,
      resistance: List<GalvanometerResistanceInput>.unmodifiable(
        resistance ?? this.resistance,
      ),
      sensitivity: List<GalvanometerSensitivityInput>.unmodifiable(
        sensitivity ?? this.sensitivity,
      ),
    );
  }

  GalvanometerState updateCritical(String field, String value) {
    final next = switch (field) {
      'rc' => critical.copyWith(rc: value),
      'ra' => critical.copyWith(ra: value),
      'rb' => critical.copyWith(rb: value),
      'dm' => critical.copyWith(dm: value),
      _ => critical,
    };
    return next == critical ? this : copyWith(critical: next);
  }

  GalvanometerState updateResistance(int index, String field, String value) {
    if (index < 0 || index >= resistance.length) return this;
    final current = resistance[index];
    final next = switch (field) {
      'uLow' => current.copyWith(uLow: value),
      'rLow' => current.copyWith(rLow: value),
      'uHigh' => current.copyWith(uHigh: value),
      'rHigh' => current.copyWith(rHigh: value),
      _ => current,
    };
    if (next == current) return this;
    final values = List<GalvanometerResistanceInput>.of(resistance);
    values[index] = next;
    return copyWith(resistance: values);
  }

  GalvanometerState updateSensitivity(int index, String field, String value) {
    if (index < 0 || index >= sensitivity.length) return this;
    final current = sensitivity[index];
    final next = switch (field) {
      'u' => current.copyWith(u: value),
      'd' => current.copyWith(d: value),
      _ => current,
    };
    if (next == current) return this;
    final values = List<GalvanometerSensitivityInput>.of(sensitivity);
    values[index] = next;
    return copyWith(sensitivity: values);
  }

  Map<String, Object> toJson() => {
    'critical': critical.toJson(),
    'resistance': resistance.map((row) => row.toJson()).toList(growable: false),
    'sensitivity': sensitivity
        .map((row) => row.toJson())
        .toList(growable: false),
  };
}

class GalvanometerResistanceRowResult {
  const GalvanometerResistanceRowResult({
    required this.index,
    required this.uLow,
    required this.rLow,
    required this.uHigh,
    required this.rHigh,
    required this.complete,
    this.rg,
    this.partiallyFilled = false,
    this.error,
  });

  final int index;
  final String uLow;
  final String rLow;
  final String uHigh;
  final String rHigh;
  final String? rg;
  final bool complete;
  final bool partiallyFilled;
  final String? error;

  Map<String, Object?> toJson() => {
    'index': index,
    'uLow': uLow.isEmpty ? null : uLow,
    'rLow': rLow.isEmpty ? null : rLow,
    'uHigh': uHigh.isEmpty ? null : uHigh,
    'rHigh': rHigh.isEmpty ? null : rHigh,
    'rg': rg,
  };
}

class GalvanometerResistanceResult {
  const GalvanometerResistanceResult({
    required this.rows,
    required this.complete,
    this.average,
    this.averageAbsoluteDeviation,
    this.message,
  });

  final List<GalvanometerResistanceRowResult> rows;
  final bool complete;
  final String? average;
  final String? averageAbsoluteDeviation;
  final String? message;

  Map<String, Object?> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'average': average,
    'error': averageAbsoluteDeviation,
    'message': message ?? '',
  };
}

class GalvanometerSensitivityRowResult {
  const GalvanometerSensitivityRowResult({
    required this.index,
    required this.u,
    required this.d,
    required this.complete,
    this.currentMicroAmp,
    this.constant,
    this.sensitivity,
    this.deviation,
    this.partiallyFilled = false,
  });

  final int index;
  final String u;
  final String d;
  final String? currentMicroAmp;
  final String? constant;
  final String? sensitivity;
  final String? deviation;
  final bool complete;
  final bool partiallyFilled;

  GalvanometerSensitivityRowResult copyWith({String? deviation}) {
    return GalvanometerSensitivityRowResult(
      index: index,
      u: u,
      d: d,
      complete: complete,
      currentMicroAmp: currentMicroAmp,
      constant: constant,
      sensitivity: sensitivity,
      deviation: deviation ?? this.deviation,
      partiallyFilled: partiallyFilled,
    );
  }

  Map<String, Object?> toJson() => {
    'index': index,
    'u': u.isEmpty ? null : u,
    'd': d.isEmpty ? null : d,
    'currentMicroAmp': currentMicroAmp,
    'sensitivity': constant,
    'scale': sensitivity,
    'deviation': deviation,
  };
}

class GalvanometerSensitivityResult {
  const GalvanometerSensitivityResult({
    required this.rows,
    required this.complete,
    this.averageCurrent,
    this.averageConstant,
    this.averageSensitivity,
    this.averageAbsoluteDeviation,
    this.message,
  });

  final List<GalvanometerSensitivityRowResult> rows;
  final bool complete;
  final String? averageCurrent;
  final String? averageConstant;
  final String? averageSensitivity;
  final String? averageAbsoluteDeviation;
  final String? message;

  Map<String, Object?> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'averageCurrent': averageCurrent,
    'averageSensitivity': averageConstant,
    'averageScale': averageSensitivity,
    'error': averageAbsoluteDeviation,
    'message': message ?? '',
  };
}

class GalvanometerCalculation {
  const GalvanometerCalculation({
    required this.resistance,
    required this.sensitivity,
  });

  final GalvanometerResistanceResult resistance;
  final GalvanometerSensitivityResult sensitivity;

  Map<String, Object?> toJson() => {
    'resistance': resistance.toJson(),
    'sensitivity': sensitivity.toJson(),
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}
