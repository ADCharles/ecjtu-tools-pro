// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';
import 'physics_voltage_current_models.dart';

class VoltageCurrentCalculator {
  const VoltageCurrentCalculator._();

  static VoltageCurrentCalculation calculate(VoltageCurrentState state) {
    return VoltageCurrentCalculation(
      blocks: state.blocks
          .map((block) => _calculateBlock(block, state.instrument))
          .toList(growable: false),
      diode: state.diode
          .asMap()
          .entries
          .map((entry) => _calculateDiode(entry.key, entry.value))
          .toList(growable: false),
    );
  }

  static VoltageCurrentBlockResult _calculateBlock(
    VoltageCurrentBlockInput block,
    VoltageCurrentInstrumentInput instrument,
  ) {
    final voltageRange = _number(block.voltageRange);
    final currentRange = _number(block.currentRange);
    final meterResistance = _number(block.meterResistance);
    final voltageGrade = _number(instrument.voltageGrade);
    final currentGrade = _number(instrument.currentGrade);
    final validMeters =
        voltageRange != null &&
        voltageRange > 0 &&
        currentRange != null &&
        currentRange > 0 &&
        meterResistance != null &&
        meterResistance > 0 &&
        voltageGrade != null &&
        voltageGrade >= 0 &&
        currentGrade != null &&
        currentGrade >= 0;

    final points = block.points
        .asMap()
        .entries
        .map(
          (entry) => _calculatePoint(
            index: entry.key,
            input: entry.value,
            connection: block.connection,
            meterResistance: meterResistance,
            validMeters: validMeters,
          ),
        )
        .toList(growable: false);
    final rawAverage = _average(
      points.map((point) => point.rawResistance).toList(growable: false),
    );
    final correctedAverage = _average(
      points.map((point) => point.correctedResistance).toList(growable: false),
    );
    final deltaVoltage = validMeters ? voltageRange * voltageGrade / 100 : null;
    final deltaCurrent = validMeters ? currentRange * currentGrade / 100 : null;
    final minVoltage = _minimum(points.map((point) => point.voltage));
    final minCurrent = _minimum(points.map((point) => point.currentMilliAmp));
    final relativeInstrumentError =
        deltaVoltage != null &&
            deltaCurrent != null &&
            minVoltage != null &&
            minVoltage > 0 &&
            minCurrent != null &&
            minCurrent > 0
        ? (deltaVoltage / minVoltage + deltaCurrent / minCurrent) * 100
        : null;
    final correctionDifference = rawAverage != null && correctedAverage != null
        ? rawAverage - correctedAverage
        : null;
    final correctionRatio =
        correctionDifference != null &&
            correctedAverage != null &&
            correctedAverage != 0
        ? (correctionDifference / correctedAverage).abs()
        : null;
    return VoltageCurrentBlockResult(
      id: block.id,
      resistance: block.resistance,
      connection: block.connection,
      points: points,
      rawAverage: rawAverage,
      correctedAverage: correctedAverage,
      deltaVoltage: deltaVoltage,
      deltaCurrentMilliAmp: deltaCurrent,
      relativeInstrumentError: relativeInstrumentError,
      correctionRatio: correctionRatio,
      correctionDifference: correctionDifference,
      complete: points.every((point) => point.complete),
    );
  }

  static VoltageCurrentPointResult _calculatePoint({
    required int index,
    required VoltageCurrentPointInput input,
    required String connection,
    required double? meterResistance,
    required bool validMeters,
  }) {
    final voltage = _number(input.voltage);
    final currentMilliAmp = _number(input.current);
    final currentAmp = currentMilliAmp == null ? null : currentMilliAmp / 1000;
    final rawResistance =
        voltage != null && currentAmp != null && currentAmp != 0
        ? voltage / currentAmp
        : null;
    final correctedResistance =
        rawResistance != null &&
            voltage != null &&
            currentAmp != null &&
            meterResistance != null &&
            validMeters
        ? connection == '内接'
              ? rawResistance - meterResistance
              : _externalCorrection(voltage, currentAmp, meterResistance)
        : null;
    final corrected =
        correctedResistance != null && correctedResistance.isFinite;
    return VoltageCurrentPointResult(
      index: index,
      voltage: voltage,
      currentMilliAmp: currentMilliAmp,
      currentAmp: currentAmp,
      rawResistance: rawResistance,
      correctedResistance: corrected ? correctedResistance : null,
      complete:
          voltage != null &&
          currentMilliAmp != null &&
          rawResistance != null &&
          corrected,
    );
  }

  static double? _externalCorrection(
    double voltage,
    double currentAmp,
    double voltageMeterResistance,
  ) {
    final denominator = currentAmp - voltage / voltageMeterResistance;
    if (denominator == 0) return null;
    final value = voltage / denominator;
    return value.isFinite ? value : null;
  }

  static VoltageCurrentDiodeResult _calculateDiode(
    int index,
    VoltageCurrentPointInput input,
  ) {
    final voltage = _number(input.voltage);
    final current = _number(input.current);
    return VoltageCurrentDiodeResult(
      index: index,
      voltage: voltage,
      currentMilliAmp: current,
      complete: voltage != null && current != null,
    );
  }

  static double? _number(Object? raw) {
    final parsed = PhysicsDecimal.parse(raw);
    if (parsed == null) return null;
    final value = parsed.toDouble();
    return value.isFinite ? value : null;
  }

  static double? _average(List<double?> values) {
    final valid = values.whereType<double>().toList(growable: false);
    if (valid.length != values.length || valid.isEmpty) return null;
    return valid.reduce((left, right) => left + right) / valid.length;
  }

  static double? _minimum(Iterable<double?> values) {
    final valuesList = values.toList(growable: false);
    if (valuesList.isEmpty ||
        valuesList.any((value) => value == null || !value.isFinite)) {
      return null;
    }
    final valid = valuesList.cast<double>();
    return valid.reduce((left, right) => left < right ? left : right);
  }

  static String format(double? value, {int digits = 7}) {
    if (value == null || !value.isFinite) return '—';
    final formatted = value.toStringAsFixed(digits);
    final trimmed = formatted
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }
}
