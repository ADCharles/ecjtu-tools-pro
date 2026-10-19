// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class VoltageCurrentPointInput {
  const VoltageCurrentPointInput({this.voltage = '', this.current = ''});

  final String voltage;
  final String current;

  factory VoltageCurrentPointInput.fromJson(Object? value) {
    final map = _map(value);
    return VoltageCurrentPointInput(
      voltage: _text(map['voltage']),
      current: _text(map['current']),
    );
  }

  VoltageCurrentPointInput copyWith({String? voltage, String? current}) {
    return VoltageCurrentPointInput(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
    );
  }

  Map<String, String> toJson() => {'voltage': voltage, 'current': current};
}

class VoltageCurrentBlockInput {
  const VoltageCurrentBlockInput({
    required this.id,
    required this.resistance,
    required this.connection,
    required this.voltageRange,
    required this.currentRange,
    required this.meterResistance,
    required this.points,
  });

  static const pointCount = 4;

  final String id;
  final String resistance;
  final String connection;
  final String voltageRange;
  final String currentRange;
  final String meterResistance;
  final List<VoltageCurrentPointInput> points;

  factory VoltageCurrentBlockInput.initial({
    required String id,
    required String resistance,
    required String connection,
    required String voltageRange,
    required String currentRange,
    required String meterResistance,
  }) {
    return VoltageCurrentBlockInput(
      id: id,
      resistance: resistance,
      connection: connection,
      voltageRange: voltageRange,
      currentRange: currentRange,
      meterResistance: meterResistance,
      points: List<VoltageCurrentPointInput>.generate(
        pointCount,
        (_) => const VoltageCurrentPointInput(),
        growable: false,
      ),
    );
  }

  factory VoltageCurrentBlockInput.fromJson(
    Object? value,
    VoltageCurrentBlockInput fallback,
  ) {
    final map = _map(value);
    final source = map['points'];
    return VoltageCurrentBlockInput(
      id: fallback.id,
      resistance: fallback.resistance,
      connection: fallback.connection,
      voltageRange: _text(map['voltageRange'], fallback.voltageRange),
      currentRange: _text(map['currentRange'], fallback.currentRange),
      meterResistance: _text(map['meterResistance'], fallback.meterResistance),
      points: List<VoltageCurrentPointInput>.generate(
        pointCount,
        (index) => VoltageCurrentPointInput.fromJson(
          source is List && index < source.length
              ? source[index]
              : fallback.points[index],
        ),
        growable: false,
      ),
    );
  }

  VoltageCurrentBlockInput copyWith({
    String? voltageRange,
    String? currentRange,
    String? meterResistance,
    List<VoltageCurrentPointInput>? points,
  }) {
    return VoltageCurrentBlockInput(
      id: id,
      resistance: resistance,
      connection: connection,
      voltageRange: voltageRange ?? this.voltageRange,
      currentRange: currentRange ?? this.currentRange,
      meterResistance: meterResistance ?? this.meterResistance,
      points: List<VoltageCurrentPointInput>.unmodifiable(
        points ?? this.points,
      ),
    );
  }

  VoltageCurrentBlockInput updatePoint(int index, String field, String value) {
    if (index < 0 || index >= points.length) return this;
    final point = points[index];
    final next = switch (field) {
      'voltage' => point.copyWith(voltage: value),
      'current' => point.copyWith(current: value),
      _ => point,
    };
    if (next == point) return this;
    final nextPoints = List<VoltageCurrentPointInput>.of(points);
    nextPoints[index] = next;
    return copyWith(points: nextPoints);
  }

  Map<String, Object> toJson() => {
    'id': id,
    'voltageRange': voltageRange,
    'currentRange': currentRange,
    'meterResistance': meterResistance,
    'points': points.map((point) => point.toJson()).toList(growable: false),
  };
}

class VoltageCurrentInstrumentInput {
  const VoltageCurrentInstrumentInput({
    this.voltageGrade = '1.5',
    this.currentGrade = '1.5',
  });

  final String voltageGrade;
  final String currentGrade;

  factory VoltageCurrentInstrumentInput.fromJson(Object? value) {
    final map = _map(value);
    return VoltageCurrentInstrumentInput(
      voltageGrade: _text(map['voltageGrade'], '1.5'),
      currentGrade: _text(map['currentGrade'], '1.5'),
    );
  }

  VoltageCurrentInstrumentInput copyWith({
    String? voltageGrade,
    String? currentGrade,
  }) {
    return VoltageCurrentInstrumentInput(
      voltageGrade: voltageGrade ?? this.voltageGrade,
      currentGrade: currentGrade ?? this.currentGrade,
    );
  }

  Map<String, String> toJson() => {
    'voltageGrade': voltageGrade,
    'currentGrade': currentGrade,
  };
}

class VoltageCurrentState {
  const VoltageCurrentState({
    required this.instrument,
    required this.blocks,
    required this.diode,
  });

  static const diodeInitialCount = 7;

  final VoltageCurrentInstrumentInput instrument;
  final List<VoltageCurrentBlockInput> blocks;
  final List<VoltageCurrentPointInput> diode;

  factory VoltageCurrentState.initial() {
    return VoltageCurrentState(
      instrument: const VoltageCurrentInstrumentInput(),
      blocks: [
        VoltageCurrentBlockInput.initial(
          id: '10-inner',
          resistance: '10',
          connection: '内接',
          voltageRange: '2',
          currentRange: '200',
          meterResistance: '1',
        ),
        VoltageCurrentBlockInput.initial(
          id: '10-outer',
          resistance: '10',
          connection: '外接',
          voltageRange: '2',
          currentRange: '200',
          meterResistance: '1000000',
        ),
        VoltageCurrentBlockInput.initial(
          id: '10000-inner',
          resistance: '10000',
          connection: '内接',
          voltageRange: '20',
          currentRange: '2',
          meterResistance: '100',
        ),
        VoltageCurrentBlockInput.initial(
          id: '10000-outer',
          resistance: '10000',
          connection: '外接',
          voltageRange: '20',
          currentRange: '2',
          meterResistance: '10000000',
        ),
      ],
      diode: List<VoltageCurrentPointInput>.generate(
        diodeInitialCount,
        (_) => const VoltageCurrentPointInput(),
        growable: false,
      ),
    );
  }

  factory VoltageCurrentState.fromJson(Object? value) {
    final map = _map(value);
    final fallback = VoltageCurrentState.initial();
    final blocks = map['blocks'];
    final diode = map['diode'];
    return VoltageCurrentState(
      instrument: VoltageCurrentInstrumentInput.fromJson(map['instrument']),
      blocks: List<VoltageCurrentBlockInput>.generate(
        fallback.blocks.length,
        (index) => VoltageCurrentBlockInput.fromJson(
          blocks is List && index < blocks.length ? blocks[index] : null,
          fallback.blocks[index],
        ),
        growable: false,
      ),
      diode: diode is List && diode.length >= 2
          ? diode.map(VoltageCurrentPointInput.fromJson).toList(growable: false)
          : fallback.diode,
    );
  }

  VoltageCurrentState copyWith({
    VoltageCurrentInstrumentInput? instrument,
    List<VoltageCurrentBlockInput>? blocks,
    List<VoltageCurrentPointInput>? diode,
  }) {
    return VoltageCurrentState(
      instrument: instrument ?? this.instrument,
      blocks: List<VoltageCurrentBlockInput>.unmodifiable(
        blocks ?? this.blocks,
      ),
      diode: List<VoltageCurrentPointInput>.unmodifiable(diode ?? this.diode),
    );
  }

  VoltageCurrentState updateInstrument(String field, String value) {
    final next = switch (field) {
      'voltageGrade' => instrument.copyWith(voltageGrade: value),
      'currentGrade' => instrument.copyWith(currentGrade: value),
      _ => instrument,
    };
    return next == instrument ? this : copyWith(instrument: next);
  }

  VoltageCurrentState updateBlockParameter(
    int index,
    String field,
    String value,
  ) {
    if (index < 0 || index >= blocks.length) return this;
    final block = blocks[index];
    final next = switch (field) {
      'voltageRange' => block.copyWith(voltageRange: value),
      'currentRange' => block.copyWith(currentRange: value),
      'meterResistance' => block.copyWith(meterResistance: value),
      _ => block,
    };
    if (next == block) return this;
    final nextBlocks = List<VoltageCurrentBlockInput>.of(blocks);
    nextBlocks[index] = next;
    return copyWith(blocks: nextBlocks);
  }

  VoltageCurrentState updatePoint(
    int blockIndex,
    int pointIndex,
    String field,
    String value,
  ) {
    if (blockIndex < 0 || blockIndex >= blocks.length) return this;
    final nextBlock = blocks[blockIndex].updatePoint(pointIndex, field, value);
    if (nextBlock == blocks[blockIndex]) return this;
    final nextBlocks = List<VoltageCurrentBlockInput>.of(blocks);
    nextBlocks[blockIndex] = nextBlock;
    return copyWith(blocks: nextBlocks);
  }

  VoltageCurrentState updateDiode(int index, String field, String value) {
    if (index < 0 || index >= diode.length) return this;
    final point = diode[index];
    final next = switch (field) {
      'voltage' => point.copyWith(voltage: value),
      'current' => point.copyWith(current: value),
      _ => point,
    };
    if (next == point) return this;
    final nextDiode = List<VoltageCurrentPointInput>.of(diode);
    nextDiode[index] = next;
    return copyWith(diode: nextDiode);
  }

  Map<String, Object> toJson() => {
    'instrument': instrument.toJson(),
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
    'diode': diode.map((point) => point.toJson()).toList(growable: false),
  };
}

class VoltageCurrentPointResult {
  const VoltageCurrentPointResult({
    required this.index,
    required this.voltage,
    required this.currentMilliAmp,
    required this.currentAmp,
    required this.rawResistance,
    required this.correctedResistance,
    required this.complete,
  });

  final int index;
  final double? voltage;
  final double? currentMilliAmp;
  final double? currentAmp;
  final double? rawResistance;
  final double? correctedResistance;
  final bool complete;

  Map<String, Object?> toJson() => {
    'index': index,
    'voltage': voltage,
    'currentMilliAmp': currentMilliAmp,
    'rawResistance': rawResistance,
    'correctedResistance': correctedResistance,
  };
}

class VoltageCurrentBlockResult {
  const VoltageCurrentBlockResult({
    required this.id,
    required this.resistance,
    required this.connection,
    required this.points,
    required this.rawAverage,
    required this.correctedAverage,
    required this.deltaVoltage,
    required this.deltaCurrentMilliAmp,
    required this.relativeInstrumentError,
    required this.correctionRatio,
    required this.correctionDifference,
    required this.complete,
  });

  final String id;
  final String resistance;
  final String connection;
  final List<VoltageCurrentPointResult> points;
  final double? rawAverage;
  final double? correctedAverage;
  final double? deltaVoltage;
  final double? deltaCurrentMilliAmp;
  final double? relativeInstrumentError;
  final double? correctionRatio;
  final double? correctionDifference;
  final bool complete;

  Map<String, Object?> toJson() => {
    'id': id,
    'resistance': resistance,
    'connection': connection,
    'points': points.map((point) => point.toJson()).toList(growable: false),
    'rawAverage': rawAverage,
    'correctedAverage': correctedAverage,
    'deltaVoltage': deltaVoltage,
    'deltaCurrentMilliAmp': deltaCurrentMilliAmp,
    'relativeInstrumentError': relativeInstrumentError,
    'correctionRatio': correctionRatio,
    'correctionDifference': correctionDifference,
  };
}

class VoltageCurrentDiodeResult {
  const VoltageCurrentDiodeResult({
    required this.index,
    required this.voltage,
    required this.currentMilliAmp,
    required this.complete,
  });

  final int index;
  final double? voltage;
  final double? currentMilliAmp;
  final bool complete;

  Map<String, Object?> toJson() => {
    'index': index,
    'voltage': voltage,
    'currentMilliAmp': currentMilliAmp,
  };
}

class VoltageCurrentCalculation {
  const VoltageCurrentCalculation({required this.blocks, required this.diode});

  final List<VoltageCurrentBlockResult> blocks;
  final List<VoltageCurrentDiodeResult> diode;

  bool get hasAnyChart =>
      blocks.any((block) => block.points.any((point) => point.complete)) ||
      diode.any((point) => point.complete);

  Map<String, Object?> toJson() => {
    'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
    'diode': diode.map((point) => point.toJson()).toList(growable: false),
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
