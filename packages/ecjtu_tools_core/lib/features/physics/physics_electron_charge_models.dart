// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';

class ElectronChargeSeriesDefinition {
  const ElectronChargeSeriesDefinition({
    required this.id,
    required this.titlePrefix,
    required this.titleFormula,
    required this.xFormula,
    required this.xSymbol,
    required this.xUnit,
    required this.yFormula,
    required this.ySymbol,
    required this.yUnit,
    required this.ratioFormula,
    required this.ratioOfAveragesFormula,
    required this.slopeUnit,
    required this.xDefaults,
  });

  final String id;
  final String titlePrefix;
  final String titleFormula;
  final String xFormula;
  final String xSymbol;
  final String xUnit;
  final String yFormula;
  final String ySymbol;
  final String yUnit;
  final String ratioFormula;
  final String ratioOfAveragesFormula;
  final String slopeUnit;
  final List<String> xDefaults;

  String get titleText => titlePrefix;
}

class ElectronChargeDefinitions {
  const ElectronChargeDefinitions._();

  static const electric = <ElectronChargeSeriesDefinition>[
    ElectronChargeSeriesDefinition(
      id: 'x-600',
      titlePrefix: 'X 轴偏转，',
      titleFormula: r'U_2=600\,\mathrm{V}',
      xFormula: r'U_d\,/\,\mathrm{V}',
      xSymbol: 'U_d',
      xUnit: 'V',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,U_d',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline{U_d}',
      slopeUnit: 'mm/V',
      xDefaults: ['0', '3', '6', '9', '12', '15', '18'],
    ),
    ElectronChargeSeriesDefinition(
      id: 'x-700',
      titlePrefix: 'X 轴偏转，',
      titleFormula: r'U_2=700\,\mathrm{V}',
      xFormula: r'U_d\,/\,\mathrm{V}',
      xSymbol: 'U_d',
      xUnit: 'V',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,U_d',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline{U_d}',
      slopeUnit: 'mm/V',
      xDefaults: ['0', '3', '6', '9', '12', '15', '18'],
    ),
    ElectronChargeSeriesDefinition(
      id: 'y-600',
      titlePrefix: 'Y 轴偏转，',
      titleFormula: r'U_2=600\,\mathrm{V}',
      xFormula: r'U_d\,/\,\mathrm{V}',
      xSymbol: 'U_d',
      xUnit: 'V',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,U_d',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline{U_d}',
      slopeUnit: 'mm/V',
      xDefaults: ['0', '3', '6', '9', '12', '15', '18'],
    ),
    ElectronChargeSeriesDefinition(
      id: 'y-700',
      titlePrefix: 'Y 轴偏转，',
      titleFormula: r'U_2=700\,\mathrm{V}',
      xFormula: r'U_d\,/\,\mathrm{V}',
      xSymbol: 'U_d',
      xUnit: 'V',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,U_d',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline{U_d}',
      slopeUnit: 'mm/V',
      xDefaults: ['0', '3', '6', '9', '12', '15', '18'],
    ),
  ];

  static const magnetic = <ElectronChargeSeriesDefinition>[
    ElectronChargeSeriesDefinition(
      id: 'magnetic-600',
      titlePrefix: '磁偏转，',
      titleFormula: r'U_2=600\,\mathrm{V}',
      xFormula: r'I\,/\,\mathrm{mA}',
      xSymbol: 'I',
      xUnit: 'mA',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,I',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline I',
      slopeUnit: 'mm/mA',
      xDefaults: ['0', '10', '20', '30', '40', '50'],
    ),
    ElectronChargeSeriesDefinition(
      id: 'magnetic-700',
      titlePrefix: '磁偏转，',
      titleFormula: r'U_2=700\,\mathrm{V}',
      xFormula: r'I\,/\,\mathrm{mA}',
      xSymbol: 'I',
      xUnit: 'mA',
      yFormula: r'D\,/\,\mathrm{mm}',
      ySymbol: 'D',
      yUnit: 'mm',
      ratioFormula: r'D\,/\,I',
      ratioOfAveragesFormula: r'\overline D\,/\,\overline I',
      slopeUnit: 'mm/mA',
      xDefaults: ['0', '10', '20', '30', '40', '50'],
    ),
  ];

  static const focusU2 = ['600', '700', '800', '900', '1000'];
  static const magneticFocusU2 = ['700', '800'];
  static const magneticFocusLength = '0.234';
  static const magneticFocusDiameter = '0.09';
  static const magneticFocusPitch = '0.145';
  static const magneticFocusTurns = '526';
  static const magneticFocusMu0 = '0.0000012566370614359173';
  static const magneticFocusStandard = '175800000000';
}

class ElectronChargePointInput {
  const ElectronChargePointInput({this.x = '', this.y = ''});

  final String x;
  final String y;

  ElectronChargePointInput copyWith({String? x, String? y}) {
    return ElectronChargePointInput(x: x ?? this.x, y: y ?? this.y);
  }

  factory ElectronChargePointInput.fromJson(Object? value) {
    final map = _map(value);
    return ElectronChargePointInput(x: _text(map['x']), y: _text(map['y']));
  }

  Map<String, String> toJson() => {'x': x, 'y': y};
}

class ElectronChargeSeriesInput {
  const ElectronChargeSeriesInput({required this.id, required this.points});

  final String id;
  final List<ElectronChargePointInput> points;

  ElectronChargeSeriesInput updatePoint(
    int index,
    ElectronChargePointInput Function(ElectronChargePointInput) update,
  ) {
    if (index < 0 || index >= points.length) return this;
    final next = List<ElectronChargePointInput>.of(points);
    next[index] = update(next[index]);
    return ElectronChargeSeriesInput(
      id: id,
      points: List<ElectronChargePointInput>.unmodifiable(next),
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'points': points.map((point) => point.toJson()).toList(growable: false),
  };
}

class ElectronChargeFocusInput {
  const ElectronChargeFocusInput({required this.u2, this.u1 = ''});

  final String u2;
  final String u1;

  ElectronChargeFocusInput copyWith({String? u2, String? u1}) {
    return ElectronChargeFocusInput(u2: u2 ?? this.u2, u1: u1 ?? this.u1);
  }

  factory ElectronChargeFocusInput.fromJson(
    Object? value, {
    required String fallbackU2,
  }) {
    final map = _map(value);
    return ElectronChargeFocusInput(
      u2: _text(map['u2'], fallbackU2),
      u1: _text(map['u1']),
    );
  }

  Map<String, String> toJson() => {'u2': u2, 'u1': u1};
}

class ElectronChargeMagneticFocusInput {
  const ElectronChargeMagneticFocusInput({
    required this.u2,
    this.forward = '',
    this.reverse = '',
    required this.length,
    required this.diameter,
    required this.pitch,
    required this.turns,
    required this.mu0,
    required this.standard,
  });

  final String u2;
  final String forward;
  final String reverse;
  final String length;
  final String diameter;
  final String pitch;
  final String turns;
  final String mu0;
  final String standard;

  ElectronChargeMagneticFocusInput copyWith({
    String? u2,
    String? forward,
    String? reverse,
    String? length,
    String? diameter,
    String? pitch,
    String? turns,
    String? mu0,
    String? standard,
  }) {
    return ElectronChargeMagneticFocusInput(
      u2: u2 ?? this.u2,
      forward: forward ?? this.forward,
      reverse: reverse ?? this.reverse,
      length: length ?? this.length,
      diameter: diameter ?? this.diameter,
      pitch: pitch ?? this.pitch,
      turns: turns ?? this.turns,
      mu0: mu0 ?? this.mu0,
      standard: standard ?? this.standard,
    );
  }

  factory ElectronChargeMagneticFocusInput.initial(int index) {
    return ElectronChargeMagneticFocusInput(
      u2: ElectronChargeDefinitions.magneticFocusU2[index],
      length: ElectronChargeDefinitions.magneticFocusLength,
      diameter: ElectronChargeDefinitions.magneticFocusDiameter,
      pitch: ElectronChargeDefinitions.magneticFocusPitch,
      turns: ElectronChargeDefinitions.magneticFocusTurns,
      mu0: ElectronChargeDefinitions.magneticFocusMu0,
      standard: ElectronChargeDefinitions.magneticFocusStandard,
    );
  }

  factory ElectronChargeMagneticFocusInput.fromJson(
    Object? value, {
    required int index,
  }) {
    final fallback = ElectronChargeMagneticFocusInput.initial(index);
    final map = _map(value);
    return fallback.copyWith(
      u2: _text(map['u2'], fallback.u2),
      forward: _text(map['forward']),
      reverse: _text(map['reverse']),
      length: _text(map['L'], fallback.length),
      diameter: _text(map['D'], fallback.diameter),
      pitch: _text(map['h'], fallback.pitch),
      turns: _text(map['N'], fallback.turns),
      mu0: _text(map['mu0'], fallback.mu0),
      standard: _text(map['standard'], fallback.standard),
    );
  }

  Map<String, String> toJson() => {
    'u2': u2,
    'forward': forward,
    'reverse': reverse,
    'L': length,
    'D': diameter,
    'h': pitch,
    'N': turns,
    'mu0': mu0,
    'standard': standard,
  };
}

class ElectronChargeState {
  const ElectronChargeState({
    required this.electric,
    required this.electroFocus,
    required this.magnetic,
    required this.magneticFocus,
  });

  static const electricRowCount = 7;
  static const magneticRowCount = 6;
  static const focusRowCount = 5;
  static const magneticFocusCount = 2;

  final List<ElectronChargeSeriesInput> electric;
  final List<ElectronChargeFocusInput> electroFocus;
  final List<ElectronChargeSeriesInput> magnetic;
  final List<ElectronChargeMagneticFocusInput> magneticFocus;

  factory ElectronChargeState.initial() {
    return ElectronChargeState(
      electric: ElectronChargeDefinitions.electric
          .map(
            (definition) => ElectronChargeSeriesInput(
              id: definition.id,
              points: definition.xDefaults
                  .map((x) => ElectronChargePointInput(x: x))
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
      electroFocus: ElectronChargeDefinitions.focusU2
          .map((u2) => ElectronChargeFocusInput(u2: u2))
          .toList(growable: false),
      magnetic: ElectronChargeDefinitions.magnetic
          .map(
            (definition) => ElectronChargeSeriesInput(
              id: definition.id,
              points: definition.xDefaults
                  .map((x) => ElectronChargePointInput(x: x))
                  .toList(growable: false),
            ),
          )
          .toList(growable: false),
      magneticFocus: List<ElectronChargeMagneticFocusInput>.generate(
        magneticFocusCount,
        ElectronChargeMagneticFocusInput.initial,
        growable: false,
      ),
    );
  }

  factory ElectronChargeState.fromJson(Object? value) {
    final map = _map(value);
    final initial = ElectronChargeState.initial();
    final electricSource = map['electric'];
    final magneticSource = map['magnetic'];
    final focusSource = map['electroFocus'];
    final magneticFocusSource = map['magneticFocus'];
    return ElectronChargeState(
      electric: List<ElectronChargeSeriesInput>.generate(
        initial.electric.length,
        (seriesIndex) {
          final fallback = initial.electric[seriesIndex];
          final source =
              electricSource is List && seriesIndex < electricSource.length
              ? _map(electricSource[seriesIndex])
              : <String, dynamic>{};
          final points = source['points'];
          return ElectronChargeSeriesInput(
            id: fallback.id,
            points: List<ElectronChargePointInput>.generate(
              fallback.points.length,
              (pointIndex) {
                final item = points is List && pointIndex < points.length
                    ? points[pointIndex]
                    : null;
                final point = ElectronChargePointInput.fromJson(item);
                return ElectronChargePointInput(
                  x: _map(item).containsKey('x')
                      ? point.x
                      : fallback.points[pointIndex].x,
                  y: point.y,
                );
              },
              growable: false,
            ),
          );
        },
        growable: false,
      ),
      electroFocus: List<ElectronChargeFocusInput>.generate(
        initial.electroFocus.length,
        (index) {
          final source = focusSource is List && index < focusSource.length
              ? focusSource[index]
              : null;
          return ElectronChargeFocusInput.fromJson(
            source,
            fallbackU2: initial.electroFocus[index].u2,
          );
        },
        growable: false,
      ),
      magnetic: List<ElectronChargeSeriesInput>.generate(
        initial.magnetic.length,
        (seriesIndex) {
          final fallback = initial.magnetic[seriesIndex];
          final source =
              magneticSource is List && seriesIndex < magneticSource.length
              ? _map(magneticSource[seriesIndex])
              : <String, dynamic>{};
          final points = source['points'];
          return ElectronChargeSeriesInput(
            id: fallback.id,
            points: List<ElectronChargePointInput>.generate(
              fallback.points.length,
              (pointIndex) {
                final item = points is List && pointIndex < points.length
                    ? points[pointIndex]
                    : null;
                final point = ElectronChargePointInput.fromJson(item);
                return ElectronChargePointInput(
                  x: _map(item).containsKey('x')
                      ? point.x
                      : fallback.points[pointIndex].x,
                  y: point.y,
                );
              },
              growable: false,
            ),
          );
        },
        growable: false,
      ),
      magneticFocus: List<ElectronChargeMagneticFocusInput>.generate(
        magneticFocusCount,
        (index) {
          final source =
              magneticFocusSource is List && index < magneticFocusSource.length
              ? magneticFocusSource[index]
              : null;
          return ElectronChargeMagneticFocusInput.fromJson(
            source,
            index: index,
          );
        },
        growable: false,
      ),
    );
  }

  ElectronChargeState copyWith({
    List<ElectronChargeSeriesInput>? electric,
    List<ElectronChargeFocusInput>? electroFocus,
    List<ElectronChargeSeriesInput>? magnetic,
    List<ElectronChargeMagneticFocusInput>? magneticFocus,
  }) {
    return ElectronChargeState(
      electric: List.unmodifiable(electric ?? this.electric),
      electroFocus: List.unmodifiable(electroFocus ?? this.electroFocus),
      magnetic: List.unmodifiable(magnetic ?? this.magnetic),
      magneticFocus: List.unmodifiable(magneticFocus ?? this.magneticFocus),
    );
  }

  ElectronChargeState updateDeflectionPoint({
    required String section,
    required int series,
    required int row,
    required String field,
    required String value,
  }) {
    final source = section == 'electric' ? electric : magnetic;
    if (series < 0 || series >= source.length) return this;
    final next = List<ElectronChargeSeriesInput>.of(source);
    next[series] = source[series].updatePoint(row, (point) {
      return field == 'x' ? point.copyWith(x: value) : point.copyWith(y: value);
    });
    return section == 'electric'
        ? copyWith(electric: next)
        : copyWith(magnetic: next);
  }

  ElectronChargeState updateFocus({
    required int row,
    required String field,
    required String value,
  }) {
    if (row < 0 || row >= electroFocus.length) return this;
    final next = List<ElectronChargeFocusInput>.of(electroFocus);
    next[row] = field == 'u2'
        ? next[row].copyWith(u2: value)
        : next[row].copyWith(u1: value);
    return copyWith(electroFocus: next);
  }

  ElectronChargeState updateMagneticFocus({
    required int column,
    required String field,
    required String value,
  }) {
    if (column < 0 || column >= magneticFocus.length) return this;
    final next = List<ElectronChargeMagneticFocusInput>.of(magneticFocus);
    final current = next[column];
    next[column] = switch (field) {
      'u2' => current.copyWith(u2: value),
      'forward' => current.copyWith(forward: value),
      'reverse' => current.copyWith(reverse: value),
      'L' => current.copyWith(length: value),
      'D' => current.copyWith(diameter: value),
      'h' => current.copyWith(pitch: value),
      'N' => current.copyWith(turns: value),
      'mu0' => current.copyWith(mu0: value),
      'standard' => current.copyWith(standard: value),
      _ => current,
    };
    return copyWith(magneticFocus: next);
  }

  Map<String, Object> toJson() => {
    'electric': electric
        .map((series) => series.toJson())
        .toList(growable: false),
    'electroFocus': electroFocus
        .map((row) => row.toJson())
        .toList(growable: false),
    'magnetic': magnetic
        .map((series) => series.toJson())
        .toList(growable: false),
    'magneticFocus': magneticFocus
        .map((column) => column.toJson())
        .toList(growable: false),
  };
}

class ElectronChargePointResult {
  const ElectronChargePointResult({
    required this.index,
    required this.x,
    required this.y,
    required this.ratio,
  });

  final int index;
  final PhysicsDecimal? x;
  final PhysicsDecimal? y;
  final PhysicsDecimal? ratio;

  bool get complete => x != null && y != null;
  bool get partiallyFilled => x != null || y != null;
}

class ElectronChargeFit {
  const ElectronChargeFit({
    required this.valid,
    required this.complete,
    this.slope,
    this.intercept,
    this.error,
  });

  final List<ElectronChargePointResult> valid;
  final bool complete;
  final PhysicsDecimal? slope;
  final PhysicsDecimal? intercept;
  final String? error;
}

class ElectronChargeSummary {
  const ElectronChargeSummary({
    required this.valid,
    required this.complete,
    this.averageX,
    this.averageY,
    this.ratio,
    this.ratioOfAverages,
  });

  final List<ElectronChargePointResult> valid;
  final bool complete;
  final PhysicsDecimal? averageX;
  final PhysicsDecimal? averageY;
  final PhysicsDecimal? ratio;
  final PhysicsDecimal? ratioOfAverages;
}

class ElectronChargeDeflectionResult {
  const ElectronChargeDeflectionResult({
    required this.definition,
    required this.points,
    required this.fit,
    required this.summary,
    this.averageX,
    this.averageY,
  });

  final ElectronChargeSeriesDefinition definition;
  final List<ElectronChargePointResult> points;
  final ElectronChargeFit fit;
  final ElectronChargeSummary summary;
  final PhysicsDecimal? averageX;
  final PhysicsDecimal? averageY;

  bool get hasChart => fit.valid.isNotEmpty;
}

class ElectronChargeFocusRowResult {
  const ElectronChargeFocusRowResult({
    required this.index,
    required this.u2,
    required this.u1,
    required this.ratio,
  });

  final int index;
  final PhysicsDecimal? u2;
  final PhysicsDecimal? u1;
  final PhysicsDecimal? ratio;

  bool get complete => u2 != null && u1 != null && !u1!.isZero;
}

class ElectronChargeFocusResult {
  const ElectronChargeFocusResult({
    required this.rows,
    required this.sumU2,
    required this.sumU1,
    required this.averageU2,
    required this.averageU1,
    required this.averageRatio,
    required this.totalRatio,
  });

  final List<ElectronChargeFocusRowResult> rows;
  final PhysicsDecimal? sumU2;
  final PhysicsDecimal? sumU1;
  final PhysicsDecimal? averageU2;
  final PhysicsDecimal? averageU1;
  final PhysicsDecimal? averageRatio;
  final PhysicsDecimal? totalRatio;

  List<ElectronChargeFocusRowResult> get validRows =>
      rows.where((row) => row.complete).toList(growable: false);
}

class ElectronChargeMagneticFocusResult {
  const ElectronChargeMagneticFocusResult({
    required this.index,
    required this.u2,
    required this.forward,
    required this.reverse,
    required this.length,
    required this.diameter,
    required this.pitch,
    required this.turns,
    required this.mu0,
    required this.standard,
    required this.averageCurrent,
    required this.lengthSquare,
    required this.diameterSquare,
    required this.pitchSquare,
    required this.turnsSquare,
    required this.mu0Square,
    required this.chargeMass,
    required this.relativeError,
    required this.complete,
    this.error,
  });

  final int index;
  final PhysicsDecimal? u2;
  final PhysicsDecimal? forward;
  final PhysicsDecimal? reverse;
  final PhysicsDecimal? length;
  final PhysicsDecimal? diameter;
  final PhysicsDecimal? pitch;
  final PhysicsDecimal? turns;
  final PhysicsDecimal? mu0;
  final PhysicsDecimal? standard;
  final PhysicsDecimal? averageCurrent;
  final PhysicsDecimal? lengthSquare;
  final PhysicsDecimal? diameterSquare;
  final PhysicsDecimal? pitchSquare;
  final PhysicsDecimal? turnsSquare;
  final PhysicsDecimal? mu0Square;
  final PhysicsDecimal? chargeMass;
  final PhysicsDecimal? relativeError;
  final bool complete;
  final String? error;

  PhysicsDecimal? valueFor(String key) => switch (key) {
    'u2' => u2,
    'forward' => forward,
    'reverse' => reverse,
    'L' => length,
    'D' => diameter,
    'h' => pitch,
    'N' => turns,
    'mu0' => mu0,
    'standard' => standard,
    _ => null,
  };
}

class ElectronChargeCalculation {
  const ElectronChargeCalculation({
    required this.electric,
    required this.electroFocus,
    required this.magnetic,
    required this.magneticFocus,
  });

  final List<ElectronChargeDeflectionResult> electric;
  final ElectronChargeFocusResult electroFocus;
  final List<ElectronChargeDeflectionResult> magnetic;
  final List<ElectronChargeMagneticFocusResult> magneticFocus;

  Map<String, Object?> toJson() => {
    'electric': electric
        .map(
          (series) => {
            'id': series.definition.id,
            'slope': series.fit.slope?.format(),
            'intercept': series.fit.intercept?.format(),
            'averageX': series.summary.averageX?.format(),
            'averageY': series.summary.averageY?.format(),
            'ratio': series.summary.ratio?.format(),
            'error': series.fit.error ?? '',
          },
        )
        .toList(growable: false),
    'electroFocus': {
      'rows': electroFocus.rows
          .map((row) => {'index': row.index + 1, 'ratio': row.ratio?.format()})
          .toList(growable: false),
      'sumU2': electroFocus.sumU2?.format(),
      'sumU1': electroFocus.sumU1?.format(),
      'averageU2': electroFocus.averageU2?.format(),
      'averageU1': electroFocus.averageU1?.format(),
      'averageRatio': electroFocus.averageRatio?.format(),
      'totalRatio': electroFocus.totalRatio?.format(),
    },
    'magnetic': magnetic
        .map(
          (series) => {
            'id': series.definition.id,
            'slope': series.fit.slope?.format(),
            'intercept': series.fit.intercept?.format(),
            'averageX': series.averageX?.format(),
            'averageY': series.averageY?.format(),
            'ratio': series.summary.ratio?.format(),
            'ratioOfAverages': series.summary.ratioOfAverages?.format(),
            'error': series.fit.error ?? '',
          },
        )
        .toList(growable: false),
    'magneticFocus': magneticFocus
        .map(
          (column) => {
            'index': column.index + 1,
            'averageCurrent': column.averageCurrent?.format(),
            'chargeMass': column.chargeMass?.format(),
            'relativeError': column.relativeError?.format(),
            'error': column.error ?? '',
          },
        )
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
