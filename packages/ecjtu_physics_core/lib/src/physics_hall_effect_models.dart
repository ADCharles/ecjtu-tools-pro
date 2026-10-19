// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';

class HallEffectReading {
  const HallEffectReading({
    required this.pp,
    required this.nn,
    required this.pn,
    required this.np,
  });

  final String pp;
  final String nn;
  final String pn;
  final String np;

  factory HallEffectReading.empty() {
    return const HallEffectReading(pp: '', nn: '', pn: '', np: '');
  }

  factory HallEffectReading.fromJson(Object? value) {
    final map = _map(value);
    return HallEffectReading(
      pp: _text(map['pp']),
      nn: _text(map['nn']),
      pn: _text(map['pn']),
      np: _text(map['np']),
    );
  }

  HallEffectReading copyWith({String? pp, String? nn, String? pn, String? np}) {
    return HallEffectReading(
      pp: pp ?? this.pp,
      nn: nn ?? this.nn,
      pn: pn ?? this.pn,
      np: np ?? this.np,
    );
  }

  HallEffectReading update(String field, String value) {
    return switch (field) {
      'pp' => copyWith(pp: value),
      'nn' => copyWith(nn: value),
      'pn' => copyWith(pn: value),
      'np' => copyWith(np: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {'pp': pp, 'nn': nn, 'pn': pn, 'np': np};
}

class HallEffectPositionRow {
  const HallEffectPositionRow({required this.x, required this.reading});

  final String x;
  final HallEffectReading reading;

  factory HallEffectPositionRow.empty() {
    return HallEffectPositionRow(x: '', reading: HallEffectReading.empty());
  }

  factory HallEffectPositionRow.fromJson(Object? value) {
    final map = _map(value);
    return HallEffectPositionRow(
      x: _text(map['x']),
      reading: HallEffectReading.fromJson(map),
    );
  }

  HallEffectPositionRow copyWith({String? x, HallEffectReading? reading}) {
    return HallEffectPositionRow(
      x: x ?? this.x,
      reading: reading ?? this.reading,
    );
  }

  HallEffectPositionRow update(String field, String value) {
    if (field == 'x') return copyWith(x: value);
    return copyWith(reading: reading.update(field, value));
  }

  Map<String, Object> toJson() => {'x': x, ...reading.toJson()};
}

class HallEffectCoilRow {
  const HallEffectCoilRow({
    required this.x,
    required this.a,
    required this.b,
    required this.combined,
  });

  final String x;
  final HallEffectReading a;
  final HallEffectReading b;
  final HallEffectReading combined;

  factory HallEffectCoilRow.empty() {
    return HallEffectCoilRow(
      x: '',
      a: HallEffectReading.empty(),
      b: HallEffectReading.empty(),
      combined: HallEffectReading.empty(),
    );
  }

  factory HallEffectCoilRow.fromJson(Object? value) {
    final map = _map(value);
    return HallEffectCoilRow(
      x: _text(map['x']),
      a: HallEffectReading.fromJson(map['a']),
      b: HallEffectReading.fromJson(map['b']),
      combined: HallEffectReading.fromJson(map['combined']),
    );
  }

  HallEffectCoilRow copyWith({
    String? x,
    HallEffectReading? a,
    HallEffectReading? b,
    HallEffectReading? combined,
  }) {
    return HallEffectCoilRow(
      x: x ?? this.x,
      a: a ?? this.a,
      b: b ?? this.b,
      combined: combined ?? this.combined,
    );
  }

  HallEffectCoilRow update(String group, String field, String value) {
    if (field == 'x') return copyWith(x: value);
    return switch (group) {
      'a' => copyWith(a: a.update(field, value)),
      'b' => copyWith(b: b.update(field, value)),
      'combined' => copyWith(combined: combined.update(field, value)),
      _ => this,
    };
  }

  Map<String, Object> toJson() => {
    'x': x,
    'a': a.toJson(),
    'b': b.toJson(),
    'combined': combined.toJson(),
  };
}

class HallEffectSolenoidInput {
  const HallEffectSolenoidInput({required this.current, required this.rows});

  static const rowCount = 10;

  final String current;
  final List<HallEffectPositionRow> rows;

  factory HallEffectSolenoidInput.initial() {
    return HallEffectSolenoidInput(
      current: '8',
      rows: List<HallEffectPositionRow>.generate(
        rowCount,
        (_) => HallEffectPositionRow.empty(),
        growable: false,
      ),
    );
  }

  factory HallEffectSolenoidInput.fromJson(Object? value) {
    final map = _map(value);
    final source = map['rows'];
    return HallEffectSolenoidInput(
      current: _text(map['current'], '8'),
      rows: List<HallEffectPositionRow>.generate(
        rowCount,
        (index) => HallEffectPositionRow.fromJson(
          source is List && index < source.length ? source[index] : null,
        ),
        growable: false,
      ),
    );
  }

  HallEffectSolenoidInput copyWith({
    String? current,
    List<HallEffectPositionRow>? rows,
  }) {
    return HallEffectSolenoidInput(
      current: current ?? this.current,
      rows: List<HallEffectPositionRow>.unmodifiable(rows ?? this.rows),
    );
  }

  HallEffectSolenoidInput updateParameter(String field, String value) {
    return field == 'current' ? copyWith(current: value) : this;
  }

  HallEffectSolenoidInput updateRow(int index, String field, String value) {
    if (index < 0 || index >= rows.length) return this;
    final next = List<HallEffectPositionRow>.of(rows);
    next[index] = next[index].update(field, value);
    return copyWith(rows: next);
  }

  Map<String, Object> toJson() => {
    'current': current,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
  };
}

class HallEffectCoilCurrents {
  const HallEffectCoilCurrents({
    required this.a,
    required this.b,
    required this.combined,
  });

  final String a;
  final String b;
  final String combined;

  factory HallEffectCoilCurrents.initial() {
    return const HallEffectCoilCurrents(a: '8', b: '8', combined: '8');
  }

  factory HallEffectCoilCurrents.fromJson(Object? value) {
    final map = _map(value);
    return HallEffectCoilCurrents(
      a: _text(map['a'], '8'),
      b: _text(map['b'], '8'),
      combined: _text(map['combined'], '8'),
    );
  }

  HallEffectCoilCurrents copyWith({String? a, String? b, String? combined}) {
    return HallEffectCoilCurrents(
      a: a ?? this.a,
      b: b ?? this.b,
      combined: combined ?? this.combined,
    );
  }

  HallEffectCoilCurrents update(String field, String value) {
    return switch (field) {
      'a' => copyWith(a: value),
      'b' => copyWith(b: value),
      'combined' => copyWith(combined: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {'a': a, 'b': b, 'combined': combined};
}

class HallEffectCoilInput {
  const HallEffectCoilInput({
    required this.radius,
    required this.currents,
    required this.rows,
  });

  static const rowCount = 10;
  static const defaultRadii = ['7', '5', '3'];

  final String radius;
  final HallEffectCoilCurrents currents;
  final List<HallEffectCoilRow> rows;

  factory HallEffectCoilInput.initial(int index) {
    return HallEffectCoilInput(
      radius: defaultRadii[index],
      currents: HallEffectCoilCurrents.initial(),
      rows: List<HallEffectCoilRow>.generate(
        rowCount,
        (_) => HallEffectCoilRow.empty(),
        growable: false,
      ),
    );
  }

  factory HallEffectCoilInput.fromJson(Object? value, int index) {
    final map = _map(value);
    final source = map['rows'];
    return HallEffectCoilInput(
      radius: _text(map['radius'], defaultRadii[index]),
      currents: HallEffectCoilCurrents.fromJson(map['currents']),
      rows: List<HallEffectCoilRow>.generate(
        rowCount,
        (row) => HallEffectCoilRow.fromJson(
          source is List && row < source.length ? source[row] : null,
        ),
        growable: false,
      ),
    );
  }

  HallEffectCoilInput copyWith({
    String? radius,
    HallEffectCoilCurrents? currents,
    List<HallEffectCoilRow>? rows,
  }) {
    return HallEffectCoilInput(
      radius: radius ?? this.radius,
      currents: currents ?? this.currents,
      rows: List<HallEffectCoilRow>.unmodifiable(rows ?? this.rows),
    );
  }

  HallEffectCoilInput updateParameter(String field, String value) {
    if (field == 'radius') return copyWith(radius: value);
    return switch (field) {
      'currentA' => copyWith(currents: currents.update('a', value)),
      'currentB' => copyWith(currents: currents.update('b', value)),
      'currentCombined' => copyWith(
        currents: currents.update('combined', value),
      ),
      _ => this,
    };
  }

  HallEffectCoilInput updateRow(
    int index,
    String group,
    String field,
    String value,
  ) {
    if (index < 0 || index >= rows.length) return this;
    final next = List<HallEffectCoilRow>.of(rows);
    next[index] = next[index].update(group, field, value);
    return copyWith(rows: next);
  }

  Map<String, Object> toJson() => {
    'radius': radius,
    'currents': currents.toJson(),
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
  };
}

class HallEffectState {
  const HallEffectState({required this.solenoid, required this.coils});

  static const coilCount = 3;

  final HallEffectSolenoidInput solenoid;
  final List<HallEffectCoilInput> coils;

  factory HallEffectState.initial() {
    return HallEffectState(
      solenoid: HallEffectSolenoidInput.initial(),
      coils: List<HallEffectCoilInput>.generate(
        coilCount,
        HallEffectCoilInput.initial,
        growable: false,
      ),
    );
  }

  factory HallEffectState.fromJson(Object? value) {
    final map = _map(value);
    final source = map['coils'];
    return HallEffectState(
      solenoid: HallEffectSolenoidInput.fromJson(map['solenoid']),
      coils: List<HallEffectCoilInput>.generate(
        coilCount,
        (index) => HallEffectCoilInput.fromJson(
          source is List && index < source.length ? source[index] : null,
          index,
        ),
        growable: false,
      ),
    );
  }

  HallEffectState copyWith({
    HallEffectSolenoidInput? solenoid,
    List<HallEffectCoilInput>? coils,
  }) {
    return HallEffectState(
      solenoid: solenoid ?? this.solenoid,
      coils: List<HallEffectCoilInput>.unmodifiable(coils ?? this.coils),
    );
  }

  HallEffectState updateSolenoidParameter(String field, String value) {
    return copyWith(solenoid: solenoid.updateParameter(field, value));
  }

  HallEffectState updateSolenoidRow(int index, String field, String value) {
    return copyWith(solenoid: solenoid.updateRow(index, field, value));
  }

  HallEffectState updateCoilParameter(
    int coilIndex,
    String field,
    String value,
  ) {
    if (coilIndex < 0 || coilIndex >= coils.length) return this;
    final next = List<HallEffectCoilInput>.of(coils);
    next[coilIndex] = next[coilIndex].updateParameter(field, value);
    return copyWith(coils: next);
  }

  HallEffectState updateCoilRow(
    int coilIndex,
    int rowIndex,
    String group,
    String field,
    String value,
  ) {
    if (coilIndex < 0 || coilIndex >= coils.length) return this;
    final next = List<HallEffectCoilInput>.of(coils);
    next[coilIndex] = next[coilIndex].updateRow(rowIndex, group, field, value);
    return copyWith(coils: next);
  }

  Map<String, Object> toJson() => {
    'solenoid': solenoid.toJson(),
    'coils': coils.map((coil) => coil.toJson()).toList(growable: false),
  };
}

class HallEffectPointResult {
  const HallEffectPointResult({
    required this.x,
    required this.hallVoltage,
    required this.field,
  });

  final PhysicsDecimal? x;
  final PhysicsDecimal? hallVoltage;
  final PhysicsDecimal? field;

  bool get complete => field != null;

  Map<String, Object?> toJson() => {
    'x': _decimalToDouble(x),
    'hallVoltage': _decimalToDouble(hallVoltage),
    'field': _decimalToDouble(field),
  };
}

class HallEffectCoilRowResult {
  const HallEffectCoilRowResult({
    required this.x,
    required this.a,
    required this.b,
    required this.combined,
    required this.sum,
    required this.difference,
  });

  final PhysicsDecimal? x;
  final HallEffectPointResult a;
  final HallEffectPointResult b;
  final HallEffectPointResult combined;
  final PhysicsDecimal? sum;
  final PhysicsDecimal? difference;

  Map<String, Object?> toJson() => {
    'x': _decimalToDouble(x),
    'a': a.toJson(),
    'b': b.toJson(),
    'combined': combined.toJson(),
    'sum': _decimalToDouble(sum),
    'difference': _decimalToDouble(difference),
  };
}

class HallEffectCalculation {
  const HallEffectCalculation({required this.solenoid, required this.coils});

  final List<HallEffectPointResult> solenoid;
  final List<List<HallEffectCoilRowResult>> coils;

  Map<String, Object?> toJson() => {
    'solenoid': solenoid.map((row) => row.toJson()).toList(growable: false),
    'coils': coils
        .map((rows) => rows.map((row) => row.toJson()).toList(growable: false))
        .toList(growable: false),
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

double? _decimalToDouble(PhysicsDecimal? value) => value?.toDouble();
