// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';

class FranckHertzPointInput {
  const FranckHertzPointInput({required this.voltage, required this.current});

  final String voltage;
  final String current;

  factory FranckHertzPointInput.empty() {
    return const FranckHertzPointInput(voltage: '', current: '');
  }

  factory FranckHertzPointInput.fromJson(Object? value) {
    final map = _map(value);
    return FranckHertzPointInput(
      voltage: _text(map['voltage']),
      current: _text(map['current']),
    );
  }

  FranckHertzPointInput copyWith({String? voltage, String? current}) {
    return FranckHertzPointInput(
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
    );
  }

  FranckHertzPointInput update(String field, String value) {
    return switch (field) {
      'voltage' => copyWith(voltage: value),
      'current' => copyWith(current: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {'voltage': voltage, 'current': current};
}

class FranckHertzState {
  const FranckHertzState({
    required this.rows,
    required this.peaks,
    required this.theory,
  });

  static const initialRowCount = 133;
  static const peakCount = 6;

  final List<FranckHertzPointInput> rows;
  final List<String> peaks;
  final String theory;

  factory FranckHertzState.initial() {
    return FranckHertzState(
      rows: List<FranckHertzPointInput>.generate(
        initialRowCount,
        (_) => FranckHertzPointInput.empty(),
        growable: false,
      ),
      peaks: List<String>.filled(peakCount, '', growable: false),
      theory: '11.8',
    );
  }

  factory FranckHertzState.fromJson(Object? value) {
    final map = _map(value);
    final sourceRows = map['rows'];
    final rowCount = sourceRows is List && sourceRows.length > initialRowCount
        ? sourceRows.length
        : initialRowCount;
    final sourcePeaks = map['peaks'];
    return FranckHertzState(
      rows: List<FranckHertzPointInput>.generate(
        rowCount,
        (index) => FranckHertzPointInput.fromJson(
          sourceRows is List && index < sourceRows.length
              ? sourceRows[index]
              : null,
        ),
        growable: false,
      ),
      peaks: List<String>.generate(
        peakCount,
        (index) => sourcePeaks is List && index < sourcePeaks.length
            ? _text(sourcePeaks[index])
            : '',
        growable: false,
      ),
      theory: _text(map['theory'], '11.8'),
    );
  }

  FranckHertzState copyWith({
    List<FranckHertzPointInput>? rows,
    List<String>? peaks,
    String? theory,
  }) {
    return FranckHertzState(
      rows: List<FranckHertzPointInput>.unmodifiable(rows ?? this.rows),
      peaks: List<String>.unmodifiable(peaks ?? this.peaks),
      theory: theory ?? this.theory,
    );
  }

  FranckHertzState updatePeak(int index, String value) {
    if (index < 0 || index >= peaks.length) return this;
    final next = List<String>.of(peaks);
    next[index] = value;
    return copyWith(peaks: next);
  }

  FranckHertzState updateRow(int index, String field, String value) {
    if (index < 0 || index >= rows.length) return this;
    final next = List<FranckHertzPointInput>.of(rows);
    next[index] = next[index].update(field, value);
    return copyWith(rows: next);
  }

  FranckHertzState addRow() {
    return copyWith(rows: [...rows, FranckHertzPointInput.empty()]);
  }

  Map<String, Object> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'peaks': peaks.toList(growable: false),
    'theory': theory,
  };
}

class FranckHertzPointResult {
  const FranckHertzPointResult({required this.voltage, required this.current});

  final PhysicsDecimal? voltage;
  final PhysicsDecimal? current;

  bool get complete => voltage != null && current != null;

  Map<String, Object?> toJson() => {
    'voltage': voltage?.toDouble(),
    'current': current?.toDouble(),
  };
}

class FranckHertzCalculation {
  const FranckHertzCalculation({
    required this.rows,
    required this.peaks,
    required this.differences,
    required this.excitations,
    required this.excitationAverage,
    required this.standardDeviation,
    required this.standardError,
    required this.theory,
    required this.relativeError,
  });

  final List<FranckHertzPointResult> rows;
  final List<PhysicsDecimal?> peaks;
  final List<PhysicsDecimal?> differences;
  final List<PhysicsDecimal?> excitations;
  final PhysicsDecimal? excitationAverage;
  final double? standardDeviation;
  final double? standardError;
  final PhysicsDecimal? theory;
  final double? relativeError;

  bool get hasChart => rows.any((row) => row.complete);

  Map<String, Object?> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'peaks': peaks.map((value) => value?.toDouble()).toList(growable: false),
    'differences': differences
        .map((value) => value?.toDouble())
        .toList(growable: false),
    'excitations': excitations
        .map((value) => value?.toDouble())
        .toList(growable: false),
    'excitationAverage': excitationAverage?.toDouble(),
    'standardDeviation': standardDeviation,
    'standardError': standardError,
    'theory': theory?.toDouble(),
    'relativeError': relativeError,
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
