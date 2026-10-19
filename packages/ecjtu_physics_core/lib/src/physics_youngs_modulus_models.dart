// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class YoungsModulusDiameterInput {
  const YoungsModulusDiameterInput({this.initial = '', this.fullLoad = ''});

  final String initial;
  final String fullLoad;

  factory YoungsModulusDiameterInput.fromJson(Object? value) {
    final map = _map(value);
    return YoungsModulusDiameterInput(
      initial: _text(map['initial']),
      fullLoad: _text(map['fullLoad']),
    );
  }

  YoungsModulusDiameterInput copyWith({String? initial, String? fullLoad}) {
    return YoungsModulusDiameterInput(
      initial: initial ?? this.initial,
      fullLoad: fullLoad ?? this.fullLoad,
    );
  }

  Map<String, String> toJson() => {'initial': initial, 'fullLoad': fullLoad};
}

class YoungsModulusScaleInput {
  const YoungsModulusScaleInput({this.add = '', this.remove = ''});

  final String add;
  final String remove;

  factory YoungsModulusScaleInput.fromJson(Object? value) {
    final map = _map(value);
    return YoungsModulusScaleInput(
      add: _text(map['add']),
      remove: _text(map['remove']),
    );
  }

  YoungsModulusScaleInput copyWith({String? add, String? remove}) {
    return YoungsModulusScaleInput(
      add: add ?? this.add,
      remove: remove ?? this.remove,
    );
  }

  Map<String, String> toJson() => {'add': add, 'remove': remove};
}

class YoungsModulusDimensions {
  const YoungsModulusDimensions({
    this.distance = '',
    this.distanceError = '',
    this.length = '',
    this.lengthError = '',
    this.leverArm = '',
    this.leverArmError = '',
    this.massIncrement = '4',
    this.gravity = '9.8',
  });

  final String distance;
  final String distanceError;
  final String length;
  final String lengthError;
  final String leverArm;
  final String leverArmError;
  final String massIncrement;
  final String gravity;

  factory YoungsModulusDimensions.fromJson(Object? value) {
    final map = _map(value);
    const fallback = YoungsModulusDimensions();
    return YoungsModulusDimensions(
      distance: _text(map['distance'], fallback.distance),
      distanceError: _text(map['distanceError'], fallback.distanceError),
      length: _text(map['length'], fallback.length),
      lengthError: _text(map['lengthError'], fallback.lengthError),
      leverArm: _text(map['leverArm'], fallback.leverArm),
      leverArmError: _text(map['leverArmError'], fallback.leverArmError),
      massIncrement: _text(map['massIncrement'], fallback.massIncrement),
      gravity: _text(map['gravity'], fallback.gravity),
    );
  }

  YoungsModulusDimensions copyWith({
    String? distance,
    String? distanceError,
    String? length,
    String? lengthError,
    String? leverArm,
    String? leverArmError,
    String? massIncrement,
    String? gravity,
  }) {
    return YoungsModulusDimensions(
      distance: distance ?? this.distance,
      distanceError: distanceError ?? this.distanceError,
      length: length ?? this.length,
      lengthError: lengthError ?? this.lengthError,
      leverArm: leverArm ?? this.leverArm,
      leverArmError: leverArmError ?? this.leverArmError,
      massIncrement: massIncrement ?? this.massIncrement,
      gravity: gravity ?? this.gravity,
    );
  }

  Map<String, String> toJson() => {
    'distance': distance,
    'distanceError': distanceError,
    'length': length,
    'lengthError': lengthError,
    'leverArm': leverArm,
    'leverArmError': leverArmError,
    'massIncrement': massIncrement,
    'gravity': gravity,
  };
}

class YoungsModulusState {
  const YoungsModulusState({
    required this.zeroError,
    required this.diameter,
    required this.scale,
    required this.dimensions,
  });

  static const diameterCount = 3;
  static const scaleCount = 8;

  final String zeroError;
  final List<YoungsModulusDiameterInput> diameter;
  final List<YoungsModulusScaleInput> scale;
  final YoungsModulusDimensions dimensions;

  factory YoungsModulusState.initial() {
    return YoungsModulusState(
      zeroError: '0',
      diameter: List<YoungsModulusDiameterInput>.generate(
        diameterCount,
        (_) => const YoungsModulusDiameterInput(),
        growable: false,
      ),
      scale: List<YoungsModulusScaleInput>.generate(
        scaleCount,
        (_) => const YoungsModulusScaleInput(),
        growable: false,
      ),
      dimensions: const YoungsModulusDimensions(),
    );
  }

  factory YoungsModulusState.fromJson(Object? value) {
    final map = _map(value);
    final fallback = YoungsModulusState.initial();
    final diameter = map['diameter'];
    final scale = map['scale'];
    return YoungsModulusState(
      zeroError: _text(map['zeroError'], fallback.zeroError),
      diameter: List<YoungsModulusDiameterInput>.generate(
        diameterCount,
        (index) => YoungsModulusDiameterInput.fromJson(
          diameter is List && index < diameter.length
              ? diameter[index]
              : fallback.diameter[index],
        ),
        growable: false,
      ),
      scale: List<YoungsModulusScaleInput>.generate(
        scaleCount,
        (index) => YoungsModulusScaleInput.fromJson(
          scale is List && index < scale.length
              ? scale[index]
              : fallback.scale[index],
        ),
        growable: false,
      ),
      dimensions: YoungsModulusDimensions.fromJson(map['dimensions']),
    );
  }

  YoungsModulusState copyWith({
    String? zeroError,
    List<YoungsModulusDiameterInput>? diameter,
    List<YoungsModulusScaleInput>? scale,
    YoungsModulusDimensions? dimensions,
  }) {
    return YoungsModulusState(
      zeroError: zeroError ?? this.zeroError,
      diameter: List<YoungsModulusDiameterInput>.unmodifiable(
        diameter ?? this.diameter,
      ),
      scale: List<YoungsModulusScaleInput>.unmodifiable(scale ?? this.scale),
      dimensions: dimensions ?? this.dimensions,
    );
  }

  YoungsModulusState updateDiameter(int index, String field, String value) {
    if (index < 0 || index >= diameter.length) return this;
    final input = diameter[index];
    final next = switch (field) {
      'initial' => input.copyWith(initial: value),
      'fullLoad' => input.copyWith(fullLoad: value),
      _ => input,
    };
    if (next == input) return this;
    final nextValues = List<YoungsModulusDiameterInput>.of(diameter);
    nextValues[index] = next;
    return copyWith(diameter: nextValues);
  }

  YoungsModulusState updateScale(int index, String field, String value) {
    if (index < 0 || index >= scale.length) return this;
    final input = scale[index];
    final next = switch (field) {
      'add' => input.copyWith(add: value),
      'remove' => input.copyWith(remove: value),
      _ => input,
    };
    if (next == input) return this;
    final nextValues = List<YoungsModulusScaleInput>.of(scale);
    nextValues[index] = next;
    return copyWith(scale: nextValues);
  }

  YoungsModulusState updateDimension(String field, String value) {
    final next = switch (field) {
      'distance' => dimensions.copyWith(distance: value),
      'distanceError' => dimensions.copyWith(distanceError: value),
      'length' => dimensions.copyWith(length: value),
      'lengthError' => dimensions.copyWith(lengthError: value),
      'leverArm' => dimensions.copyWith(leverArm: value),
      'leverArmError' => dimensions.copyWith(leverArmError: value),
      'massIncrement' => dimensions.copyWith(massIncrement: value),
      'gravity' => dimensions.copyWith(gravity: value),
      _ => dimensions,
    };
    return next == dimensions ? this : copyWith(dimensions: next);
  }

  Map<String, Object?> toJson() => {
    'zeroError': zeroError,
    'diameter': diameter.map((item) => item.toJson()).toList(growable: false),
    'scale': scale.map((item) => item.toJson()).toList(growable: false),
    'dimensions': dimensions.toJson(),
  };
}

class YoungsModulusDiameterResult {
  const YoungsModulusDiameterResult({
    required this.index,
    required this.initial,
    required this.fullLoad,
    required this.mean,
    required this.complete,
  });

  final int index;
  final double? initial;
  final double? fullLoad;
  final double? mean;
  final bool complete;

  Map<String, Object?> toJson() => {
    'index': index,
    'initial': initial,
    'fullLoad': fullLoad,
    'mean': mean,
  };
}

class YoungsModulusScaleResult {
  const YoungsModulusScaleResult({
    required this.index,
    required this.add,
    required this.remove,
    required this.mean,
    required this.complete,
  });

  final int index;
  final double? add;
  final double? remove;
  final double? mean;
  final bool complete;

  Map<String, Object?> toJson() => {
    'index': index,
    'add': add,
    'remove': remove,
    'mean': mean,
  };
}

class YoungsModulusDifferenceResult {
  const YoungsModulusDifferenceResult({
    required this.index,
    required this.lower,
    required this.upper,
    required this.difference,
    required this.complete,
  });

  final int index;
  final double? lower;
  final double? upper;
  final double? difference;
  final bool complete;

  Map<String, Object?> toJson() => {
    'index': index,
    'lower': lower,
    'upper': upper,
    'difference': difference,
  };
}

class YoungsModulusNumericDimensions {
  const YoungsModulusNumericDimensions({
    required this.distance,
    required this.distanceError,
    required this.length,
    required this.lengthError,
    required this.leverArm,
    required this.leverArmError,
    required this.massIncrement,
    required this.gravity,
  });

  final double? distance;
  final double? distanceError;
  final double? length;
  final double? lengthError;
  final double? leverArm;
  final double? leverArmError;
  final double? massIncrement;
  final double? gravity;

  Map<String, Object?> toJson() => {
    'distance': distance,
    'distanceError': distanceError,
    'length': length,
    'lengthError': lengthError,
    'leverArm': leverArm,
    'leverArmError': leverArmError,
    'massIncrement': massIncrement,
    'gravity': gravity,
  };
}

class YoungsModulusCalculation {
  const YoungsModulusCalculation({
    required this.zeroError,
    required this.diameter,
    required this.diameterAverageMillimeter,
    required this.diameterErrorMillimeter,
    required this.scale,
    required this.differences,
    required this.extensionCentimeter,
    required this.extensionErrorCentimeter,
    required this.dimensions,
    required this.force,
    required this.young,
    required this.relativeError,
    required this.absoluteError,
  });

  final double? zeroError;
  final List<YoungsModulusDiameterResult> diameter;
  final double? diameterAverageMillimeter;
  final double? diameterErrorMillimeter;
  final List<YoungsModulusScaleResult> scale;
  final List<YoungsModulusDifferenceResult> differences;
  final double? extensionCentimeter;
  final double? extensionErrorCentimeter;
  final YoungsModulusNumericDimensions dimensions;
  final double? force;
  final double? young;
  final double? relativeError;
  final double? absoluteError;

  Map<String, Object?> toJson() => {
    'zeroError': zeroError,
    'diameter': diameter.map((item) => item.toJson()).toList(growable: false),
    'diameterAverageMillimeter': diameterAverageMillimeter,
    'diameterErrorMillimeter': diameterErrorMillimeter,
    'scale': scale.map((item) => item.toJson()).toList(growable: false),
    'differences': differences
        .map((item) => item.toJson())
        .toList(growable: false),
    'extensionCentimeter': extensionCentimeter,
    'extensionErrorCentimeter': extensionErrorCentimeter,
    'dimensions': dimensions.toJson(),
    'force': force,
    'young': young,
    'relativeError': relativeError,
    'absoluteError': absoluteError,
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
