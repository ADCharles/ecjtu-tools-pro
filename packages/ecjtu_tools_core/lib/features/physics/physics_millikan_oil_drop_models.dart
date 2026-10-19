// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class MillikanConstants {
  const MillikanConstants({
    required this.g,
    required this.eta,
    required this.rho,
    required this.pressure,
    required this.d,
    required this.l,
    required this.b,
    required this.electronCharge,
  });

  final String g;
  final String eta;
  final String rho;
  final String pressure;
  final String d;
  final String l;
  final String b;
  final String electronCharge;

  factory MillikanConstants.initial() {
    return const MillikanConstants(
      g: '9.794',
      eta: '1.83e-5',
      rho: '979',
      pressure: '76.0',
      d: '0.005',
      l: '0.0016',
      b: '6.17e-6',
      electronCharge: '1.602e-19',
    );
  }

  factory MillikanConstants.fromJson(Object? value) {
    final source = _millikanMap(value);
    final fallback = MillikanConstants.initial();
    return MillikanConstants(
      g: _millikanText(source['g'], fallback.g),
      eta: _millikanText(source['eta'], fallback.eta),
      rho: _millikanText(source['rho'], fallback.rho),
      pressure: _millikanText(source['pressure'], fallback.pressure),
      d: _millikanText(source['d'], fallback.d),
      l: _millikanText(source['l'], fallback.l),
      b: _millikanText(source['b'], fallback.b),
      electronCharge: _millikanText(
        source['electronCharge'],
        fallback.electronCharge,
      ),
    );
  }

  MillikanConstants copyWith({
    String? g,
    String? eta,
    String? rho,
    String? pressure,
    String? d,
    String? l,
    String? b,
    String? electronCharge,
  }) {
    return MillikanConstants(
      g: g ?? this.g,
      eta: eta ?? this.eta,
      rho: rho ?? this.rho,
      pressure: pressure ?? this.pressure,
      d: d ?? this.d,
      l: l ?? this.l,
      b: b ?? this.b,
      electronCharge: electronCharge ?? this.electronCharge,
    );
  }

  MillikanConstants update(String field, String value) {
    return switch (field) {
      'g' => copyWith(g: value),
      'eta' => copyWith(eta: value),
      'rho' => copyWith(rho: value),
      'pressure' => copyWith(pressure: value),
      'd' => copyWith(d: value),
      'l' => copyWith(l: value),
      'b' => copyWith(b: value),
      'electronCharge' => copyWith(electronCharge: value),
      _ => this,
    };
  }

  Map<String, String> toJson() => {
    'g': g,
    'eta': eta,
    'rho': rho,
    'pressure': pressure,
    'd': d,
    'l': l,
    'b': b,
    'electronCharge': electronCharge,
  };
}

class MillikanGroupInput {
  const MillikanGroupInput({required this.voltage, required this.times});

  static const timeCount = 5;

  final String voltage;
  final List<String> times;

  factory MillikanGroupInput.initial() {
    return MillikanGroupInput(
      voltage: '',
      times: List<String>.filled(timeCount, '', growable: false),
    );
  }

  factory MillikanGroupInput.fromJson(Object? value) {
    final source = _millikanMap(value);
    final rawTimes = source['times'];
    final times = rawTimes is List
        ? List<String>.generate(
            timeCount,
            (index) =>
                _millikanText(index < rawTimes.length ? rawTimes[index] : null),
            growable: false,
          )
        : _restoreLegacyTimes(source['rise'], source['fall']);
    return MillikanGroupInput(
      voltage: _millikanText(source['voltage']),
      times: times,
    );
  }

  MillikanGroupInput copyWith({String? voltage, List<String>? times}) {
    return MillikanGroupInput(
      voltage: voltage ?? this.voltage,
      times: List<String>.unmodifiable(times ?? this.times),
    );
  }

  MillikanGroupInput updateTime(int index, String value) {
    if (index < 0 || index >= times.length) return this;
    final next = List<String>.of(times);
    next[index] = value;
    return copyWith(times: next);
  }

  Map<String, Object> toJson() => {
    'voltage': voltage,
    'times': times.toList(growable: false),
  };
}

class MillikanState {
  const MillikanState({required this.groups, required this.constants});

  static const groupCount = 5;

  final List<MillikanGroupInput> groups;
  final MillikanConstants constants;

  factory MillikanState.initial() {
    return MillikanState(
      groups: List<MillikanGroupInput>.generate(
        groupCount,
        (_) => MillikanGroupInput.initial(),
        growable: false,
      ),
      constants: MillikanConstants.initial(),
    );
  }

  factory MillikanState.fromJson(Object? value) {
    final source = _millikanMap(value);
    final rawGroups = source['groups'];
    final fallback = MillikanState.initial();
    return MillikanState(
      groups: List<MillikanGroupInput>.generate(
        groupCount,
        (index) => MillikanGroupInput.fromJson(
          rawGroups is List && index < rawGroups.length
              ? rawGroups[index]
              : fallback.groups[index],
        ),
        growable: false,
      ),
      constants: MillikanConstants.fromJson(source['constants']),
    );
  }

  MillikanState copyWith({
    List<MillikanGroupInput>? groups,
    MillikanConstants? constants,
  }) {
    return MillikanState(
      groups: List<MillikanGroupInput>.unmodifiable(groups ?? this.groups),
      constants: constants ?? this.constants,
    );
  }

  MillikanState updateConstant(String field, String value) {
    return copyWith(constants: constants.update(field, value));
  }

  MillikanState updateVoltage(int index, String value) {
    if (index < 0 || index >= groups.length) return this;
    final next = List<MillikanGroupInput>.of(groups);
    next[index] = next[index].copyWith(voltage: value);
    return copyWith(groups: next);
  }

  MillikanState updateTime(int groupIndex, int timeIndex, String value) {
    if (groupIndex < 0 || groupIndex >= groups.length) return this;
    final next = List<MillikanGroupInput>.of(groups);
    next[groupIndex] = next[groupIndex].updateTime(timeIndex, value);
    return copyWith(groups: next);
  }

  Map<String, Object> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'constants': constants.toJson(),
  };
}

class MillikanGroupCalculation {
  const MillikanGroupCalculation({
    required this.voltage,
    required this.times,
    required this.timeMean,
    required this.radius,
    required this.correctedTimeFactor,
    required this.charge,
    required this.chargeNumber,
    required this.nearestChargeNumber,
  });

  final double? voltage;
  final List<double?> times;
  final double? timeMean;
  final double? radius;
  final double? correctedTimeFactor;
  final double? charge;
  final double? chargeNumber;
  final int? nearestChargeNumber;

  bool get complete => charge != null;

  Map<String, Object?> toJson() => {
    'voltage': voltage,
    'times': times,
    'timeMean': timeMean,
    'radius': radius,
    'correctedTimeFactor': correctedTimeFactor,
    'charge': charge,
    'chargeNumber': chargeNumber,
    'nearestChargeNumber': nearestChargeNumber,
  };
}

class MillikanCalculation {
  const MillikanCalculation({
    required this.groups,
    required this.electronCharge,
  });

  final List<MillikanGroupCalculation> groups;
  final double? electronCharge;

  bool get complete => groups.any((group) => group.charge != null);

  Map<String, Object?> toJson() => {
    'groups': groups.map((group) => group.toJson()).toList(growable: false),
    'electronCharge': electronCharge,
  };
}

Map<String, Object?> _millikanMap(Object? value) {
  if (value is Map) {
    return value.map<String, Object?>((key, item) => MapEntry('$key', item));
  }
  return <String, Object?>{};
}

String _millikanText(Object? value, [String fallback = '']) {
  return value == null ? fallback : value.toString();
}

List<String> _restoreLegacyTimes(Object? riseValue, Object? fallValue) {
  final rise = riseValue is List ? riseValue : const <Object?>[];
  final fall = fallValue is List ? fallValue : const <Object?>[];
  return List<String>.generate(MillikanGroupInput.timeCount, (index) {
    final riseValue = index < rise.length ? _millikanNumber(rise[index]) : null;
    final fallValue = index < fall.length ? _millikanNumber(fall[index]) : null;
    if (riseValue == null || fallValue == null) return '';
    return ((riseValue + fallValue) / 2).toString();
  }, growable: false);
}

double? _millikanNumber(Object? value) {
  final source = _millikanText(value).trim().replaceAll(',', '');
  if (source.isEmpty) return null;
  final parsed = double.tryParse(source);
  return parsed != null && parsed.isFinite ? parsed : null;
}
