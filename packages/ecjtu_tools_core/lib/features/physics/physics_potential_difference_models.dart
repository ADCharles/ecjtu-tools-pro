// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';

class PotentialDifferenceInputRow {
  const PotentialDifferenceInputRow({
    this.standard = '',
    this.ux1 = '',
    this.ux2 = '',
  });

  final String standard;
  final String ux1;
  final String ux2;

  PotentialDifferenceInputRow copyWith({
    String? standard,
    String? ux1,
    String? ux2,
  }) {
    return PotentialDifferenceInputRow(
      standard: standard ?? this.standard,
      ux1: ux1 ?? this.ux1,
      ux2: ux2 ?? this.ux2,
    );
  }

  factory PotentialDifferenceInputRow.fromJson(Object? value) {
    final map = _potentialMap(value);
    return PotentialDifferenceInputRow(
      standard: _potentialText(map['is']),
      ux1: _potentialText(map['ux1']),
      ux2: _potentialText(map['ux2']),
    );
  }

  Map<String, String> toJson() => {'is': standard, 'ux1': ux1, 'ux2': ux2};
}

class PotentialDifferenceState {
  const PotentialDifferenceState({
    required this.resistance,
    required this.uncertainty,
    required this.rows,
  });

  static const rowCount = 8;

  final String resistance;
  final String uncertainty;
  final List<PotentialDifferenceInputRow> rows;

  factory PotentialDifferenceState.initial() {
    return PotentialDifferenceState(
      resistance: '1',
      uncertainty: '',
      rows: List<PotentialDifferenceInputRow>.generate(
        rowCount,
        (_) => const PotentialDifferenceInputRow(),
        growable: false,
      ),
    );
  }

  factory PotentialDifferenceState.fromJson(Object? value) {
    final map = _potentialMap(value);
    final source = map['rows'];
    final fallback = PotentialDifferenceState.initial();
    return PotentialDifferenceState(
      resistance: _potentialText(map['resistance'], fallback.resistance),
      uncertainty: _potentialText(map['uncertainty']),
      rows: List<PotentialDifferenceInputRow>.generate(
        rowCount,
        (index) => PotentialDifferenceInputRow.fromJson(
          source is List && index < source.length ? source[index] : null,
        ),
        growable: false,
      ),
    );
  }

  PotentialDifferenceState copyWith({
    String? resistance,
    String? uncertainty,
    List<PotentialDifferenceInputRow>? rows,
  }) {
    return PotentialDifferenceState(
      resistance: resistance ?? this.resistance,
      uncertainty: uncertainty ?? this.uncertainty,
      rows: List<PotentialDifferenceInputRow>.unmodifiable(rows ?? this.rows),
    );
  }

  PotentialDifferenceState updateRow(int index, String field, String value) {
    if (index < 0 || index >= rows.length) return this;
    final row = rows[index];
    final next = switch (field) {
      'standard' => row.copyWith(standard: value),
      'ux1' => row.copyWith(ux1: value),
      'ux2' => row.copyWith(ux2: value),
      _ => row,
    };
    if (next.standard == row.standard &&
        next.ux1 == row.ux1 &&
        next.ux2 == row.ux2) {
      return this;
    }
    final nextRows = List<PotentialDifferenceInputRow>.of(rows);
    nextRows[index] = next;
    return copyWith(rows: nextRows);
  }

  Map<String, Object> toJson() => {
    'resistance': resistance,
    'uncertainty': uncertainty,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
  };
}

class PotentialDifferenceResultRow {
  const PotentialDifferenceResultRow({
    required this.index,
    required this.standard,
    required this.ux1,
    required this.ux2,
    required this.ix1,
    required this.ix2,
    required this.ix,
    required this.delta,
    required this.invalid,
  });

  final int index;
  final double? standard;
  final double? ux1;
  final double? ux2;
  final double? ix1;
  final double? ix2;
  final double? ix;
  final double? delta;
  final bool invalid;

  Map<String, Object?> toJson() => {
    'index': index,
    'standard': standard,
    'ux1': ux1,
    'ux2': ux2,
    'ix1': ix1,
    'ix2': ix2,
    'ix': ix,
    'delta': delta,
    'invalid': invalid,
  };
}

class PotentialDifferenceRecommendedRow {
  const PotentialDifferenceRecommendedRow({
    required this.ix,
    required this.delta,
  });

  final String? ix;
  final String? delta;
}

class PotentialDifferenceCalculation {
  const PotentialDifferenceCalculation({
    required this.rows,
    required this.k,
    required this.maxDelta,
    required this.maxStandard,
    required this.error,
    required this.recommendedRows,
  });

  final List<PotentialDifferenceResultRow> rows;
  final double? k;
  final double? maxDelta;
  final double? maxStandard;
  final String error;
  final List<PotentialDifferenceRecommendedRow> recommendedRows;

  Map<String, Object?> toJson() => {
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'k': k,
    'maxDelta': maxDelta,
    'maxStandard': maxStandard,
    'error': error,
  };
}

Map<String, Object?> _potentialMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _potentialText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}

PhysicsDecimal? potentialDecimal(Object? value) => PhysicsDecimal.parse(value);
