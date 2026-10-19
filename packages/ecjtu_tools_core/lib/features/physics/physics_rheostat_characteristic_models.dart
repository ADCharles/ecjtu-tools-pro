// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class RheostatMeasurementInput {
  const RheostatMeasurementInput({
    required this.voltage,
    required this.current,
  });

  final String voltage;
  final String current;

  factory RheostatMeasurementInput.empty() {
    return const RheostatMeasurementInput(voltage: '', current: '');
  }

  factory RheostatMeasurementInput.fromJson(Object? value) {
    final source = _rheostatMap(value);
    return RheostatMeasurementInput(
      voltage: _rheostatText(source['voltage']),
      current: _rheostatText(source['current']),
    );
  }

  RheostatMeasurementInput copyWith({String? voltage, String? current}) {
    return RheostatMeasurementInput(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
    );
  }

  RheostatMeasurementInput update(String field, String value) {
    return switch (field) {
      'voltage' => copyWith(voltage: value),
      'current' => copyWith(current: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {'voltage': voltage, 'current': current};
}

class RheostatState {
  const RheostatState({
    required this.rows,
    required this.rangeResistance,
    required this.testVoltage,
    required this.voltageUncertainty,
    required this.currentUncertainty,
  });

  static const rowCount = 6;
  static const defaultRangeResistance = '1500';
  static const defaultTestVoltage = '1';
  static const defaultVoltageUncertainty = '0.015';
  static const defaultCurrentUncertainty = '0.00075';

  final List<RheostatMeasurementInput> rows;
  final String rangeResistance;
  final String testVoltage;
  final String voltageUncertainty;
  final String currentUncertainty;

  factory RheostatState.initial() {
    return RheostatState(
      rows: List<RheostatMeasurementInput>.generate(
        rowCount,
        (_) => RheostatMeasurementInput.empty(),
        growable: false,
      ),
      rangeResistance: defaultRangeResistance,
      testVoltage: defaultTestVoltage,
      voltageUncertainty: defaultVoltageUncertainty,
      currentUncertainty: defaultCurrentUncertainty,
    );
  }

  factory RheostatState.fromJson(Object? value) {
    final source = _rheostatMap(value);
    final fallback = RheostatState.initial();
    final rawRows = source['rows'];
    return RheostatState(
      rows: List<RheostatMeasurementInput>.generate(
        rowCount,
        (index) => RheostatMeasurementInput.fromJson(
          rawRows is List && index < rawRows.length
              ? rawRows[index]
              : fallback.rows[index],
        ),
        growable: false,
      ),
      rangeResistance: _rheostatText(
        source['range'],
        fallback: fallback.rangeResistance,
      ),
      testVoltage: _rheostatText(
        source['testVoltage'],
        fallback: fallback.testVoltage,
      ),
      voltageUncertainty: _rheostatText(
        source['voltageUncertainty'],
        fallback: fallback.voltageUncertainty,
      ),
      currentUncertainty: _rheostatText(
        source['currentUncertainty'],
        fallback: fallback.currentUncertainty,
      ),
    );
  }

  RheostatState copyWith({
    List<RheostatMeasurementInput>? rows,
    String? rangeResistance,
    String? testVoltage,
    String? voltageUncertainty,
    String? currentUncertainty,
  }) {
    return RheostatState(
      rows: List<RheostatMeasurementInput>.unmodifiable(rows ?? this.rows),
      rangeResistance: rangeResistance ?? this.rangeResistance,
      testVoltage: testVoltage ?? this.testVoltage,
      voltageUncertainty: voltageUncertainty ?? this.voltageUncertainty,
      currentUncertainty: currentUncertainty ?? this.currentUncertainty,
    );
  }

  RheostatState updateRow(int index, String field, String value) {
    if (index < 0 || index >= rows.length) return this;
    final next = List<RheostatMeasurementInput>.of(rows);
    next[index] = next[index].update(field, value);
    return copyWith(rows: next);
  }

  RheostatState updateParameter(String field, String value) {
    return switch (field) {
      'range' => copyWith(rangeResistance: value),
      'testVoltage' => copyWith(testVoltage: value),
      'voltageUncertainty' => copyWith(voltageUncertainty: value),
      'currentUncertainty' => copyWith(currentUncertainty: value),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'range': rangeResistance,
    'testVoltage': testVoltage,
    'voltageUncertainty': voltageUncertainty,
    'currentUncertainty': currentUncertainty,
  };
}

class RheostatRowCalculation {
  const RheostatRowCalculation({
    required this.voltageMillivolt,
    required this.currentMilliampere,
    required this.voltage,
    required this.current,
    required this.directResistance,
    required this.correctedResistance,
  });

  final double? voltageMillivolt;
  final double? currentMilliampere;
  final double? voltage;
  final double? current;
  final double? directResistance;
  final double? correctedResistance;

  Map<String, Object?> toJson() => {
    'voltageMillivolt': voltageMillivolt,
    'currentMilliampere': currentMilliampere,
    'voltage': voltage,
    'current': current,
    'directResistance': directResistance,
    'correctedResistance': correctedResistance,
  };
}

class RheostatCalculation {
  const RheostatCalculation({
    required this.rangeResistance,
    required this.rows,
    required this.directMean,
    required this.correctedMean,
    required this.squaredDifferences,
    required this.aUncertainty,
    required this.testVoltage,
    required this.testCurrentMilliampere,
    required this.testCurrentAmpere,
    required this.voltageDerivative,
    required this.currentDerivative,
    required this.voltageUncertaintyVolt,
    required this.currentUncertaintyAmpere,
    required this.bUncertainty,
    required this.totalUncertainty,
    required this.relativeError,
  });

  final double? rangeResistance;
  final List<RheostatRowCalculation> rows;
  final double? directMean;
  final double? correctedMean;
  final List<double?> squaredDifferences;
  final double? aUncertainty;
  final double? testVoltage;
  final double? testCurrentMilliampere;
  final double? testCurrentAmpere;
  final double? voltageDerivative;
  final double? currentDerivative;
  final double? voltageUncertaintyVolt;
  final double? currentUncertaintyAmpere;
  final double? bUncertainty;
  final double? totalUncertainty;
  final double? relativeError;

  Map<String, Object?> toJson() => {
    'rangeResistance': rangeResistance,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'directMean': directMean,
    'correctedMean': correctedMean,
    'squaredDifferences': squaredDifferences,
    'aUncertainty': aUncertainty,
    'testVoltage': testVoltage,
    'testCurrentMilliampere': testCurrentMilliampere,
    'testCurrentAmpere': testCurrentAmpere,
    'voltageDerivative': voltageDerivative,
    'currentDerivative': currentDerivative,
    'voltageUncertaintyVolt': voltageUncertaintyVolt,
    'currentUncertaintyAmpere': currentUncertaintyAmpere,
    'bUncertainty': bUncertainty,
    'totalUncertainty': totalUncertainty,
    'relativeError': relativeError,
  };
}

Map<String, Object?> _rheostatMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _rheostatText(Object? value, {String fallback = ''}) {
  return value == null ? fallback : value.toString();
}
