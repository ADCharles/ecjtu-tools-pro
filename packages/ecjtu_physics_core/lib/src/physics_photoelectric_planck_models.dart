// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class PhotoelectricPointInput {
  const PhotoelectricPointInput({this.voltage = '', this.current = ''});

  final String voltage;
  final String current;

  factory PhotoelectricPointInput.fromJson(Object? value) {
    final map = _photoelectricMap(value);
    return PhotoelectricPointInput(
      voltage: _photoelectricText(map['voltage']),
      current: _photoelectricText(map['current']),
    );
  }

  PhotoelectricPointInput copyWith({String? voltage, String? current}) {
    return PhotoelectricPointInput(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
    );
  }

  Map<String, String> toJson() => {'voltage': voltage, 'current': current};
}

class PhotoelectricGroupInput {
  const PhotoelectricGroupInput({
    required this.wavelength,
    required this.cutoff,
    required this.points,
  });

  static const pointCount = 11;

  final int wavelength;
  final String cutoff;
  final List<PhotoelectricPointInput> points;

  factory PhotoelectricGroupInput.initial(int wavelength) {
    return PhotoelectricGroupInput(
      wavelength: wavelength,
      cutoff: '',
      points: List<PhotoelectricPointInput>.generate(
        pointCount,
        (_) => const PhotoelectricPointInput(),
        growable: false,
      ),
    );
  }

  factory PhotoelectricGroupInput.fromJson(
    Object? value,
    PhotoelectricGroupInput fallback,
  ) {
    final map = _photoelectricMap(value);
    final source = map['points'];
    return PhotoelectricGroupInput(
      wavelength: fallback.wavelength,
      cutoff: _photoelectricText(map['cutoff']),
      points: List<PhotoelectricPointInput>.generate(
        pointCount,
        (index) => PhotoelectricPointInput.fromJson(
          source is List && index < source.length
              ? source[index]
              : fallback.points[index],
        ),
        growable: false,
      ),
    );
  }

  PhotoelectricGroupInput copyWith({
    String? cutoff,
    List<PhotoelectricPointInput>? points,
  }) {
    return PhotoelectricGroupInput(
      wavelength: wavelength,
      cutoff: cutoff ?? this.cutoff,
      points: List<PhotoelectricPointInput>.unmodifiable(points ?? this.points),
    );
  }

  PhotoelectricGroupInput updatePoint(int index, String field, String value) {
    if (index < 0 || index >= points.length) return this;
    final point = points[index];
    final next = switch (field) {
      'voltage' => point.copyWith(voltage: value),
      'current' => point.copyWith(current: value),
      _ => point,
    };
    if (next.voltage == point.voltage && next.current == point.current) {
      return this;
    }
    final nextPoints = List<PhotoelectricPointInput>.of(points);
    nextPoints[index] = next;
    return copyWith(points: nextPoints);
  }

  Map<String, Object> toJson() => {
    'wavelength': wavelength,
    'cutoff': cutoff,
    'points': points.map((point) => point.toJson()).toList(growable: false),
  };
}

class PhotoelectricPlanckState {
  const PhotoelectricPlanckState({
    required this.groups,
    required this.electronCharge,
    required this.knownH,
  });

  static const wavelengths = <int>[365, 405, 436, 546, 577];

  final List<PhotoelectricGroupInput> groups;
  final String electronCharge;
  final String knownH;

  factory PhotoelectricPlanckState.initial() {
    return PhotoelectricPlanckState(
      groups: wavelengths
          .map(PhotoelectricGroupInput.initial)
          .toList(growable: false),
      electronCharge: '1.602e-19',
      knownH: '6.63e-34',
    );
  }

  factory PhotoelectricPlanckState.fromJson(Object? value) {
    final map = _photoelectricMap(value);
    final fallback = PhotoelectricPlanckState.initial();
    final sourceGroups = map['groups'];
    return PhotoelectricPlanckState(
      groups: List<PhotoelectricGroupInput>.generate(
        fallback.groups.length,
        (index) => PhotoelectricGroupInput.fromJson(
          sourceGroups is List && index < sourceGroups.length
              ? sourceGroups[index]
              : null,
          fallback.groups[index],
        ),
        growable: false,
      ),
      electronCharge: _photoelectricText(
        map['electronCharge'],
        fallback.electronCharge,
      ),
      knownH: _photoelectricText(map['knownH'], fallback.knownH),
    );
  }

  PhotoelectricPlanckState copyWith({
    List<PhotoelectricGroupInput>? groups,
    String? electronCharge,
    String? knownH,
  }) {
    return PhotoelectricPlanckState(
      groups: List<PhotoelectricGroupInput>.unmodifiable(groups ?? this.groups),
      electronCharge: electronCharge ?? this.electronCharge,
      knownH: knownH ?? this.knownH,
    );
  }

  PhotoelectricPlanckState updateGlobal(String field, String value) {
    return switch (field) {
      'electronCharge' => copyWith(electronCharge: value),
      'knownH' => copyWith(knownH: value),
      _ => this,
    };
  }

  PhotoelectricPlanckState updateCutoff(int index, String value) {
    if (index < 0 || index >= groups.length) return this;
    final nextGroups = List<PhotoelectricGroupInput>.of(groups);
    nextGroups[index] = nextGroups[index].copyWith(cutoff: value);
    return copyWith(groups: nextGroups);
  }

  PhotoelectricPlanckState updatePoint(
    int groupIndex,
    int pointIndex,
    String field,
    String value,
  ) {
    if (groupIndex < 0 || groupIndex >= groups.length) return this;
    final nextGroups = List<PhotoelectricGroupInput>.of(groups);
    nextGroups[groupIndex] = nextGroups[groupIndex].updatePoint(
      pointIndex,
      field,
      value,
    );
    return copyWith(groups: nextGroups);
  }

  Map<String, Object> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'electronCharge': electronCharge,
    'knownH': knownH,
  };
}

class PhotoelectricRegressionPoint {
  const PhotoelectricRegressionPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};
}

class PhotoelectricRegression {
  const PhotoelectricRegression({
    required this.valid,
    required this.slope,
    required this.intercept,
    required this.r2,
  });

  final List<PhotoelectricRegressionPoint> valid;
  final double? slope;
  final double? intercept;
  final double? r2;

  bool get complete => slope != null && intercept != null;

  Map<String, Object?> toJson() => {
    'valid': valid.map((point) => point.toJson()).toList(growable: false),
    'slope': slope,
    'intercept': intercept,
    'r2': r2,
  };
}

class PhotoelectricPointResult {
  const PhotoelectricPointResult({
    required this.voltage,
    required this.current,
  });

  final double? voltage;
  final double? current;

  bool get complete => voltage != null && current != null;

  Map<String, Object?> toJson() => {'voltage': voltage, 'current': current};
}

class PhotoelectricGroupCalculation {
  const PhotoelectricGroupCalculation({
    required this.wavelength,
    required this.points,
    required this.regression,
    required this.frequency,
    required this.derivedCutoff,
    required this.cutoff,
  });

  final int wavelength;
  final List<PhotoelectricPointResult> points;
  final PhotoelectricRegression regression;
  final double frequency;
  final double? derivedCutoff;
  final double? cutoff;

  Map<String, Object?> toJson() => {
    'wavelength': wavelength,
    'points': points.map((point) => point.toJson()).toList(growable: false),
    'regression': regression.toJson(),
    'frequency': frequency,
    'derivedCutoff': derivedCutoff,
    'cutoff': cutoff,
  };
}

class PhotoelectricPlanckCalculation {
  const PhotoelectricPlanckCalculation({
    required this.groups,
    required this.fit,
    required this.electronCharge,
    required this.h,
    required this.knownH,
    required this.relativeError,
  });

  final List<PhotoelectricGroupCalculation> groups;
  final PhotoelectricRegression fit;
  final double? electronCharge;
  final double? h;
  final double? knownH;
  final double? relativeError;

  Map<String, Object?> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'fit': fit.toJson(),
    'electronCharge': electronCharge,
    'h': h,
    'knownH': knownH,
    'relativeError': relativeError,
  };
}

Map<String, Object?> _photoelectricMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _photoelectricText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}
