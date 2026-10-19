// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class SolidDensityRectangularInput {
  const SolidDensityRectangularInput({
    required this.length,
    required this.width,
    required this.height,
    this.mass = '',
    this.massError = '',
  });

  static const measurementCount = 5;

  final List<String> length;
  final List<String> width;
  final List<String> height;
  final String mass;
  final String massError;

  factory SolidDensityRectangularInput.initial() {
    return SolidDensityRectangularInput(
      length: List<String>.filled(measurementCount, '', growable: false),
      width: List<String>.filled(measurementCount, '', growable: false),
      height: List<String>.filled(measurementCount, '', growable: false),
    );
  }

  factory SolidDensityRectangularInput.fromJson(Object? value) {
    final map = _solidMap(value);
    return SolidDensityRectangularInput(
      length: _solidList(map['length']),
      width: _solidList(map['width']),
      height: _solidList(map['height']),
      mass: _solidText(map['mass']),
      massError: _solidText(map['massError']),
    );
  }

  SolidDensityRectangularInput copyWith({
    List<String>? length,
    List<String>? width,
    List<String>? height,
    String? mass,
    String? massError,
  }) {
    return SolidDensityRectangularInput(
      length: List<String>.unmodifiable(length ?? this.length),
      width: List<String>.unmodifiable(width ?? this.width),
      height: List<String>.unmodifiable(height ?? this.height),
      mass: mass ?? this.mass,
      massError: massError ?? this.massError,
    );
  }

  SolidDensityRectangularInput updateMeasurement(
    String field,
    int index,
    String value,
  ) {
    if (index < 0 || index >= measurementCount) return this;
    final values = switch (field) {
      'length' => List<String>.of(length),
      'width' => List<String>.of(width),
      'height' => List<String>.of(height),
      _ => null,
    };
    if (values == null) return this;
    values[index] = value;
    return switch (field) {
      'length' => copyWith(length: values),
      'width' => copyWith(width: values),
      'height' => copyWith(height: values),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {
    'length': length,
    'width': width,
    'height': height,
    'mass': mass,
    'massError': massError,
  };
}

class SolidDensityDisplacementInput {
  const SolidDensityDisplacementInput({
    this.m1 = '',
    this.m2 = '',
    this.m3 = '',
    this.waterDensity = defaultWaterDensity,
    this.waterDensityError = '',
    this.massError = '',
  });

  static const defaultWaterDensity = '1.000';

  final String m1;
  final String m2;
  final String m3;
  final String waterDensity;
  final String waterDensityError;
  final String massError;

  factory SolidDensityDisplacementInput.fromJson(Object? value) {
    final map = _solidMap(value);
    return SolidDensityDisplacementInput(
      m1: _solidText(map['m1']),
      m2: _solidText(map['m2']),
      m3: _solidText(map['m3']),
      waterDensity: _solidText(map['waterDensity'], defaultWaterDensity),
      waterDensityError: _solidText(map['waterDensityError']),
      massError: _solidText(map['massError']),
    );
  }

  SolidDensityDisplacementInput copyWith({
    String? m1,
    String? m2,
    String? m3,
    String? waterDensity,
    String? waterDensityError,
    String? massError,
  }) {
    return SolidDensityDisplacementInput(
      m1: m1 ?? this.m1,
      m2: m2 ?? this.m2,
      m3: m3 ?? this.m3,
      waterDensity: waterDensity ?? this.waterDensity,
      waterDensityError: waterDensityError ?? this.waterDensityError,
      massError: massError ?? this.massError,
    );
  }

  Map<String, String> toJson() => {
    'm1': m1,
    'm2': m2,
    'm3': m3,
    'waterDensity': waterDensity,
    'waterDensityError': waterDensityError,
    'massError': massError,
  };
}

class SolidDensityState {
  const SolidDensityState({
    required this.rectangular,
    required this.displacement,
  });

  final SolidDensityRectangularInput rectangular;
  final SolidDensityDisplacementInput displacement;

  factory SolidDensityState.initial() {
    return SolidDensityState(
      rectangular: SolidDensityRectangularInput.initial(),
      displacement: const SolidDensityDisplacementInput(),
    );
  }

  factory SolidDensityState.fromJson(Object? value) {
    final map = _solidMap(value);
    return SolidDensityState(
      rectangular: SolidDensityRectangularInput.fromJson(map['rectangular']),
      displacement: SolidDensityDisplacementInput.fromJson(map['displacement']),
    );
  }

  SolidDensityState copyWith({
    SolidDensityRectangularInput? rectangular,
    SolidDensityDisplacementInput? displacement,
  }) {
    return SolidDensityState(
      rectangular: rectangular ?? this.rectangular,
      displacement: displacement ?? this.displacement,
    );
  }

  SolidDensityState updateRectangularMeasurement(
    int index,
    String field,
    String value,
  ) {
    return copyWith(
      rectangular: rectangular.updateMeasurement(field, index, value),
    );
  }

  SolidDensityState updateRectangularField(String field, String value) {
    return switch (field) {
      'mass' => copyWith(rectangular: rectangular.copyWith(mass: value)),
      'massError' => copyWith(
        rectangular: rectangular.copyWith(massError: value),
      ),
      _ => this,
    };
  }

  SolidDensityState updateDisplacementField(String field, String value) {
    return switch (field) {
      'm1' => copyWith(displacement: displacement.copyWith(m1: value)),
      'm2' => copyWith(displacement: displacement.copyWith(m2: value)),
      'm3' => copyWith(displacement: displacement.copyWith(m3: value)),
      'waterDensity' => copyWith(
        displacement: displacement.copyWith(waterDensity: value),
      ),
      'waterDensityError' => copyWith(
        displacement: displacement.copyWith(waterDensityError: value),
      ),
      'massError' => copyWith(
        displacement: displacement.copyWith(massError: value),
      ),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {
    'rectangular': rectangular.toJson(),
    'displacement': displacement.toJson(),
  };
}

class SolidDensityStatistics {
  const SolidDensityStatistics({
    required this.average,
    required this.standardDeviation,
  });

  final double? average;
  final double? standardDeviation;

  Map<String, Object?> toJson() => {
    'average': average,
    'standardDeviation': standardDeviation,
  };
}

class SolidDensityRectangularCalculation {
  const SolidDensityRectangularCalculation({
    required this.length,
    required this.width,
    required this.height,
    required this.mass,
    required this.volume,
    required this.density,
    required this.relativeUncertainty,
    required this.absoluteUncertainty,
  });

  final SolidDensityStatistics length;
  final SolidDensityStatistics width;
  final SolidDensityStatistics height;
  final double? mass;
  final double? volume;
  final double? density;
  final double? relativeUncertainty;
  final double? absoluteUncertainty;

  Map<String, Object?> toJson() => {
    'length': length.toJson(),
    'width': width.toJson(),
    'height': height.toJson(),
    'mass': mass,
    'volume': volume,
    'density': density,
    'relativeUncertainty': relativeUncertainty,
    'absoluteUncertainty': absoluteUncertainty,
  };
}

class SolidDensityDisplacementCalculation {
  const SolidDensityDisplacementCalculation({
    required this.objectMass,
    required this.waterMass,
    required this.waterDensity,
    required this.density,
    required this.relativeUncertainty,
    required this.absoluteUncertainty,
  });

  final double? objectMass;
  final double? waterMass;
  final double? waterDensity;
  final double? density;
  final double? relativeUncertainty;
  final double? absoluteUncertainty;

  Map<String, Object?> toJson() => {
    'objectMass': objectMass,
    'waterMass': waterMass,
    'waterDensity': waterDensity,
    'density': density,
    'relativeUncertainty': relativeUncertainty,
    'absoluteUncertainty': absoluteUncertainty,
  };
}

class SolidDensityCalculation {
  const SolidDensityCalculation({
    required this.rectangular,
    required this.displacement,
  });

  final SolidDensityRectangularCalculation rectangular;
  final SolidDensityDisplacementCalculation displacement;

  Map<String, Object?> toJson() => {
    'rectangular': rectangular.toJson(),
    'displacement': displacement.toJson(),
  };
}

Map<String, Object?> _solidMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _solidText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}

List<String> _solidList(Object? value) {
  if (value is! List) {
    return List<String>.filled(
      SolidDensityRectangularInput.measurementCount,
      '',
      growable: false,
    );
  }
  return List<String>.generate(
    SolidDensityRectangularInput.measurementCount,
    (index) => index < value.length ? _solidText(value[index]) : '',
    growable: false,
  );
}
