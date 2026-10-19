// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class EnamelWireResistivityState {
  const EnamelWireResistivityState({
    required this.diameters,
    required this.resistances,
    required this.mass,
    required this.massError,
    required this.density,
  });

  static const diameterCount = 3;
  static const resistanceCount = 5;
  static const defaultMassError = '0.05';
  static const defaultDensity = '8.96e6';

  final List<String> diameters;
  final List<String> resistances;
  final String mass;
  final String massError;
  final String density;

  factory EnamelWireResistivityState.initial() {
    return EnamelWireResistivityState(
      diameters: List<String>.filled(diameterCount, '', growable: false),
      resistances: List<String>.filled(resistanceCount, '', growable: false),
      mass: '',
      massError: defaultMassError,
      density: defaultDensity,
    );
  }

  factory EnamelWireResistivityState.fromJson(Object? value) {
    final source = _enamelMap(value);
    final fallback = EnamelWireResistivityState.initial();
    return EnamelWireResistivityState(
      diameters: _enamelList(source['diameters'], diameterCount),
      resistances: _enamelList(source['resistances'], resistanceCount),
      mass: _enamelText(source['mass']),
      massError: _enamelText(source['massError'], fallback: fallback.massError),
      density: _enamelText(source['density'], fallback: fallback.density),
    );
  }

  EnamelWireResistivityState copyWith({
    List<String>? diameters,
    List<String>? resistances,
    String? mass,
    String? massError,
    String? density,
  }) {
    return EnamelWireResistivityState(
      diameters: List<String>.unmodifiable(diameters ?? this.diameters),
      resistances: List<String>.unmodifiable(resistances ?? this.resistances),
      mass: mass ?? this.mass,
      massError: massError ?? this.massError,
      density: density ?? this.density,
    );
  }

  EnamelWireResistivityState updateDiameter(int index, String value) {
    if (index < 0 || index >= diameters.length) return this;
    final next = List<String>.of(diameters);
    next[index] = value;
    return copyWith(diameters: next);
  }

  EnamelWireResistivityState updateResistance(int index, String value) {
    if (index < 0 || index >= resistances.length) return this;
    final next = List<String>.of(resistances);
    next[index] = value;
    return copyWith(resistances: next);
  }

  EnamelWireResistivityState updateParameter(String field, String value) {
    return switch (field) {
      'mass' => copyWith(mass: value),
      'massError' => copyWith(massError: value),
      'density' => copyWith(density: value),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {
    'diameters': diameters,
    'resistances': resistances,
    'mass': mass,
    'massError': massError,
    'density': density,
  };
}

class EnamelWireResistivityCalculation {
  const EnamelWireResistivityCalculation({
    required this.diameters,
    required this.diameterSquaredDifferences,
    required this.diameterMean,
    required this.diameterStandardError,
    required this.resistances,
    required this.resistanceSquaredDifferences,
    required this.resistanceMean,
    required this.resistanceStandardError,
    required this.mass,
    required this.massError,
    required this.density,
    required this.resistivity,
    required this.relativeError,
    required this.absoluteError,
  });

  final List<double?> diameters;
  final List<double?> diameterSquaredDifferences;
  final double? diameterMean;
  final double? diameterStandardError;
  final List<double?> resistances;
  final List<double?> resistanceSquaredDifferences;
  final double? resistanceMean;
  final double? resistanceStandardError;
  final double? mass;
  final double? massError;
  final double? density;
  final double? resistivity;
  final double? relativeError;
  final double? absoluteError;

  Map<String, Object?> toJson() => {
    'diameters': diameters,
    'diameterSquaredDifferences': diameterSquaredDifferences,
    'diameterMean': diameterMean,
    'diameterStandardError': diameterStandardError,
    'resistances': resistances,
    'resistanceSquaredDifferences': resistanceSquaredDifferences,
    'resistanceMean': resistanceMean,
    'resistanceStandardError': resistanceStandardError,
    'mass': mass,
    'massError': massError,
    'density': density,
    'resistivity': resistivity,
    'relativeError': relativeError,
    'absoluteError': absoluteError,
  };
}

Map<String, Object?> _enamelMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

List<String> _enamelList(Object? value, int count) {
  return List<String>.generate(
    count,
    (index) =>
        value is List && index < value.length ? _enamelText(value[index]) : '',
    growable: false,
  );
}

String _enamelText(Object? value, {String fallback = ''}) {
  return value == null ? fallback : value.toString();
}
