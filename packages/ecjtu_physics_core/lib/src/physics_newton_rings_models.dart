// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

enum NewtonRingKind { m, n }

extension NewtonRingKindLabel on NewtonRingKind {
  String get value {
    switch (this) {
      case NewtonRingKind.m:
        return 'm';
      case NewtonRingKind.n:
        return 'n';
    }
  }

  static NewtonRingKind parse(Object? value, NewtonRingKind fallback) {
    return value?.toString().toLowerCase() == 'n' ? NewtonRingKind.n : fallback;
  }
}

class NewtonRingInput {
  const NewtonRingInput({
    required this.kind,
    required this.order,
    this.left = '',
    this.right = '',
  });

  final NewtonRingKind kind;
  final String order;
  final String left;
  final String right;

  factory NewtonRingInput.defaultFor(int index) {
    final isLowOrder = index >= NewtonRingsState.pairCount;
    final order = isLowOrder
        ? 24 - (index - NewtonRingsState.pairCount)
        : 29 - index;
    return NewtonRingInput(
      kind: isLowOrder ? NewtonRingKind.n : NewtonRingKind.m,
      order: '$order',
    );
  }

  NewtonRingInput copyWith({
    NewtonRingKind? kind,
    String? order,
    String? left,
    String? right,
  }) {
    return NewtonRingInput(
      kind: kind ?? this.kind,
      order: order ?? this.order,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  factory NewtonRingInput.fromJson(Object? value, {required int index}) {
    final fallback = NewtonRingInput.defaultFor(index);
    final map = _map(value);
    return NewtonRingInput(
      kind: NewtonRingKindLabel.parse(map['type'], fallback.kind),
      order: _text(map['order'], fallback.order),
      left: _text(map['left']),
      right: _text(map['right']),
    );
  }

  Map<String, String> toJson() => {
    'type': kind.value,
    'order': order,
    'left': left,
    'right': right,
  };
}

class NewtonRingsState {
  const NewtonRingsState({
    required this.wavelength,
    required this.pairGap,
    required this.rings,
  });

  static const ringCount = 10;
  static const pairCount = 5;
  static const defaultWavelength = '589.3';
  static const defaultPairGap = '5';

  final String wavelength;
  final String pairGap;
  final List<NewtonRingInput> rings;

  factory NewtonRingsState.initial() {
    return NewtonRingsState(
      wavelength: defaultWavelength,
      pairGap: defaultPairGap,
      rings: List<NewtonRingInput>.generate(
        ringCount,
        NewtonRingInput.defaultFor,
        growable: false,
      ),
    );
  }

  factory NewtonRingsState.fromJson(Object? value) {
    final map = _map(value);
    final inputRings = map['rings'];
    final rings = List<NewtonRingInput>.generate(ringCount, (index) {
      final source = inputRings is List && index < inputRings.length
          ? inputRings[index]
          : null;
      return NewtonRingInput.fromJson(source, index: index);
    }, growable: false);
    return NewtonRingsState(
      wavelength: _text(map['wavelength'], defaultWavelength),
      pairGap: _text(map['pairGap'], defaultPairGap),
      rings: rings,
    );
  }

  NewtonRingsState copyWith({
    String? wavelength,
    String? pairGap,
    List<NewtonRingInput>? rings,
  }) {
    return NewtonRingsState(
      wavelength: wavelength ?? this.wavelength,
      pairGap: pairGap ?? this.pairGap,
      rings: List<NewtonRingInput>.unmodifiable(rings ?? this.rings),
    );
  }

  NewtonRingsState updateRing(
    int index,
    NewtonRingInput Function(NewtonRingInput) update,
  ) {
    if (index < 0 || index >= rings.length) return this;
    final next = List<NewtonRingInput>.of(rings);
    next[index] = update(next[index]);
    return copyWith(rings: next);
  }

  Map<String, Object> toJson() => {
    'wavelength': wavelength,
    'pairGap': pairGap,
    'rings': rings.map((ring) => ring.toJson()).toList(growable: false),
  };
}

class NewtonRingComputed {
  const NewtonRingComputed({
    required this.index,
    required this.kind,
    required this.order,
    required this.left,
    required this.right,
    this.diameter,
    this.diameterSquare,
    this.blank = false,
    this.invalid = false,
  });

  final int index;
  final NewtonRingKind kind;
  final String order;
  final String left;
  final String right;
  final String? diameter;
  final String? diameterSquare;
  final bool blank;
  final bool invalid;

  Map<String, Object?> toJson() => {
    'type': kind.value,
    'order': order.isEmpty ? null : order,
    'diameter': diameter,
    'diameterSquare': diameterSquare,
  };
}

class NewtonRingPairComputed {
  const NewtonRingPairComputed({
    required this.index,
    required this.mOrder,
    required this.nOrder,
    this.actualGap,
    this.mSquare,
    this.nSquare,
    this.deltaSquare,
    this.complete = false,
  });

  final int index;
  final String? mOrder;
  final String? nOrder;
  final String? actualGap;
  final String? mSquare;
  final String? nSquare;
  final String? deltaSquare;
  final bool complete;

  Map<String, Object?> toJson() => {
    'actualGap': actualGap,
    'deltaSquare': deltaSquare,
  };
}

class NewtonRingsCalculation {
  const NewtonRingsCalculation({
    required this.rings,
    required this.pairs,
    required this.complete,
    this.errorMessage,
    this.average,
    this.error,
    this.radiusTable,
    this.radiusErrorTable,
    this.radiusMeters,
    this.radiusErrorMeters,
  });

  final List<NewtonRingComputed> rings;
  final List<NewtonRingPairComputed> pairs;
  final bool complete;
  final String? errorMessage;
  final String? average;
  final String? error;
  final String? radiusTable;
  final String? radiusErrorTable;
  final String? radiusMeters;
  final String? radiusErrorMeters;

  Map<String, Object?> toJson() => {
    'rings': rings.map((ring) => ring.toJson()).toList(growable: false),
    'pairs': pairs.map((pair) => pair.toJson()).toList(growable: false),
    'average': average,
    'error': error,
    'radiusTable': radiusTable,
    'radiusErrorTable': radiusErrorTable,
    'radiusMeters': radiusMeters,
    'radiusErrorMeters': radiusErrorMeters,
    'message': complete ? '' : (errorMessage ?? ''),
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
