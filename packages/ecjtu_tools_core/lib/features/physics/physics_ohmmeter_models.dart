// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class OhmmeterCalibrationRow {
  const OhmmeterCalibrationRow({
    required this.resistance,
    required this.measured,
  });

  final String resistance;
  final String measured;

  OhmmeterCalibrationRow copyWith({String? resistance, String? measured}) {
    return OhmmeterCalibrationRow(
      resistance: resistance ?? this.resistance,
      measured: measured ?? this.measured,
    );
  }

  factory OhmmeterCalibrationRow.fromJson(Object? value) {
    final source = _ohmmeterMap(value);
    return OhmmeterCalibrationRow(
      resistance: _ohmmeterText(source['resistance']),
      measured: _ohmmeterText(source['measured']),
    );
  }

  Map<String, Object> toJson() => {
    'resistance': resistance,
    'measured': measured,
  };
}

class OhmmeterState {
  const OhmmeterState({
    required this.shuntResistance,
    required this.limitingResistance,
    required this.batteryResistance,
    required this.startResistance,
    required this.endResistance,
    required this.resistanceStep,
    required this.calibration,
    required this.measuredResistance,
    required this.trueResistance,
    this.calibrationError = '',
  });

  final String shuntResistance;
  final String limitingResistance;
  final String batteryResistance;
  final String startResistance;
  final String endResistance;
  final String resistanceStep;
  final List<OhmmeterCalibrationRow> calibration;
  final String measuredResistance;
  final String trueResistance;
  final String calibrationError;

  factory OhmmeterState.initial() {
    return OhmmeterState(
      shuntResistance: '',
      limitingResistance: '',
      batteryResistance: '0',
      startResistance: '500',
      endResistance: '3100',
      resistanceStep: '20',
      calibration:
          OhmmeterSequence.generate('500', '3100', '20') ??
          const <OhmmeterCalibrationRow>[],
      measuredResistance: '',
      trueResistance: '',
    );
  }

  factory OhmmeterState.fromJson(Object? value) {
    final wrapper = _ohmmeterMap(value);
    final source = _ohmmeterMap(wrapper['inputs'] ?? value);
    final fallback = OhmmeterState.initial();
    final parameters = _ohmmeterMap(source['parameters']);
    final settings = _ohmmeterMap(source['calibrationSettings']);
    final start = _ohmmeterText(
      settings['start'],
      fallback: fallback.startResistance,
    );
    final end = _ohmmeterText(
      settings['end'],
      fallback: fallback.endResistance,
    );
    final step = _ohmmeterText(
      settings['step'],
      fallback: fallback.resistanceStep,
    );
    final rawRows = source['calibration'];
    final sourceRows = rawRows is List
        ? rawRows.map(OhmmeterCalibrationRow.fromJson).toList(growable: false)
        : const <OhmmeterCalibrationRow>[];
    final measuredByResistance = <String, String>{
      for (final row in sourceRows) row.resistance: row.measured,
    };
    final generated = OhmmeterSequence.generate(start, end, step);
    final calibration = generated == null
        ? sourceRows
        : generated
              .map(
                (row) => row.copyWith(
                  measured: measuredByResistance[row.resistance] ?? '',
                ),
              )
              .toList(growable: false);
    final verification = _ohmmeterMap(source['verification']);
    return OhmmeterState(
      shuntResistance: _ohmmeterText(parameters['shuntResistance']),
      limitingResistance: _ohmmeterText(parameters['limitingResistance']),
      batteryResistance: _ohmmeterText(
        parameters['batteryResistance'],
        fallback: fallback.batteryResistance,
      ),
      startResistance: start,
      endResistance: end,
      resistanceStep: step,
      calibration: calibration,
      measuredResistance: _ohmmeterText(verification['measuredResistance']),
      trueResistance: _ohmmeterText(verification['trueResistance']),
    );
  }

  OhmmeterState copyWith({
    String? shuntResistance,
    String? limitingResistance,
    String? batteryResistance,
    String? startResistance,
    String? endResistance,
    String? resistanceStep,
    List<OhmmeterCalibrationRow>? calibration,
    String? measuredResistance,
    String? trueResistance,
    String? calibrationError,
  }) {
    return OhmmeterState(
      shuntResistance: shuntResistance ?? this.shuntResistance,
      limitingResistance: limitingResistance ?? this.limitingResistance,
      batteryResistance: batteryResistance ?? this.batteryResistance,
      startResistance: startResistance ?? this.startResistance,
      endResistance: endResistance ?? this.endResistance,
      resistanceStep: resistanceStep ?? this.resistanceStep,
      calibration: List<OhmmeterCalibrationRow>.unmodifiable(
        calibration ?? this.calibration,
      ),
      measuredResistance: measuredResistance ?? this.measuredResistance,
      trueResistance: trueResistance ?? this.trueResistance,
      calibrationError: calibrationError ?? this.calibrationError,
    );
  }

  OhmmeterState updateParameter(String field, String value) {
    return switch (field) {
      'shuntResistance' => copyWith(shuntResistance: value),
      'limitingResistance' => copyWith(limitingResistance: value),
      'batteryResistance' => copyWith(batteryResistance: value),
      _ => this,
    };
  }

  OhmmeterState updateSetting(String field, String value) {
    return switch (field) {
      'start' => copyWith(startResistance: value),
      'end' => copyWith(endResistance: value),
      'step' => copyWith(resistanceStep: value),
      _ => this,
    };
  }

  OhmmeterState updateMeasured(int index, String value) {
    if (index < 0 || index >= calibration.length) return this;
    final next = List<OhmmeterCalibrationRow>.of(calibration);
    next[index] = next[index].copyWith(measured: value);
    return copyWith(calibration: next);
  }

  OhmmeterState updateVerification(String field, String value) {
    return switch (field) {
      'measuredResistance' => copyWith(measuredResistance: value),
      'trueResistance' => copyWith(trueResistance: value),
      _ => this,
    };
  }

  OhmmeterState regenerateCalibration() {
    final generated = OhmmeterSequence.generate(
      startResistance,
      endResistance,
      resistanceStep,
    );
    if (generated == null) {
      return copyWith(calibrationError: '请填写有效的起始电阻、结束电阻和递增值');
    }
    final measuredByResistance = <String, String>{
      for (final row in calibration) row.resistance: row.measured,
    };
    return copyWith(
      calibration: generated
          .map(
            (row) => row.copyWith(
              measured: measuredByResistance[row.resistance] ?? '',
            ),
          )
          .toList(growable: false),
      calibrationError: '',
    );
  }

  Map<String, Object> toJson() => {
    'parameters': {
      'shuntResistance': shuntResistance,
      'limitingResistance': limitingResistance,
      'batteryResistance': batteryResistance,
    },
    'calibrationSettings': {
      'start': startResistance,
      'end': endResistance,
      'step': resistanceStep,
    },
    'calibration': calibration
        .map((row) => row.toJson())
        .toList(growable: false),
    'verification': {
      'measuredResistance': measuredResistance,
      'trueResistance': trueResistance,
    },
  };
}

class OhmmeterSequence {
  const OhmmeterSequence._();

  static const maxRows = 1000;

  static List<OhmmeterCalibrationRow>? generate(
    String startRaw,
    String endRaw,
    String stepRaw,
  ) {
    final start = _ohmmeterParse(startRaw);
    final end = _ohmmeterParse(endRaw);
    final step = _ohmmeterParse(stepRaw);
    if (start == null || end == null || step == null || step <= 0) {
      return null;
    }
    final distance = (end - start).abs();
    final count = (distance / step + 1e-9).floor() + 1;
    if (count < 1 || count > maxRows) return null;
    final direction = end >= start ? 1 : -1;
    return List<OhmmeterCalibrationRow>.generate(
      count,
      (index) => OhmmeterCalibrationRow(
        resistance: _ohmmeterFormat(start + direction * step * index),
        measured: '',
      ),
      growable: false,
    );
  }
}

Map<String, Object?> _ohmmeterMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _ohmmeterText(Object? value, {String fallback = ''}) {
  return value == null ? fallback : value.toString();
}

double? _ohmmeterParse(Object? value) {
  final text = value?.toString().trim().replaceAll(',', '') ?? '';
  if (text.isEmpty) return null;
  final parsed = double.tryParse(text);
  return parsed != null && parsed.isFinite ? parsed : null;
}

String _ohmmeterFormat(double value) {
  final rounded = double.parse(value.toStringAsFixed(12));
  if (rounded == 0) return '0';
  return rounded.toString();
}
