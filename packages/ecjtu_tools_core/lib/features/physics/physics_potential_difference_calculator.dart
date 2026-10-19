// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_decimal.dart';
import 'physics_potential_difference_models.dart';

class PotentialDifferenceCalculator {
  const PotentialDifferenceCalculator._();

  static PotentialDifferenceCalculation calculate(
    PotentialDifferenceState state,
  ) {
    final resistance = PhysicsDecimal.parse(state.resistance);
    if (resistance == null || resistance.isZero) {
      return _empty('请输入有效的电阻箱电阻 R_B');
    }

    final uncertaintyText = state.uncertainty.trim();
    final uncertainty = PhysicsDecimal.parse(uncertaintyText);
    if (uncertaintyText.isNotEmpty &&
        (uncertainty == null ||
            uncertainty.isZero ||
            uncertainty.coefficient < BigInt.zero)) {
      return _empty('请输入大于 0 的不确定度');
    }

    final rows = <PotentialDifferenceResultRow>[];
    var hasInvalid = false;
    for (var index = 0; index < state.rows.length; index++) {
      final input = state.rows[index];
      final hasAnyInput = [
        input.standard,
        input.ux1,
        input.ux2,
      ].any((value) => value.trim().isNotEmpty);
      if (!hasAnyInput) continue;

      final standard = PhysicsDecimal.parse(input.standard);
      final ux1 = PhysicsDecimal.parse(input.ux1);
      final ux2 = PhysicsDecimal.parse(input.ux2);
      if (standard == null || ux1 == null || ux2 == null) {
        hasInvalid = true;
        rows.add(
          PotentialDifferenceResultRow(
            index: index,
            standard: null,
            ux1: null,
            ux2: null,
            ix1: null,
            ix2: null,
            ix: null,
            delta: null,
            invalid: true,
          ),
        );
        continue;
      }

      final ix1 = ux1.divide(resistance);
      final ix2 = ux2.divide(resistance);
      final ix = (ix1 + ix2).divide(PhysicsDecimal.fromInt(2));
      final delta = ix - standard;
      rows.add(
        PotentialDifferenceResultRow(
          index: index,
          standard: standard.toDouble(),
          ux1: ux1.toDouble(),
          ux2: ux2.toDouble(),
          ix1: ix1.toDouble(),
          ix2: ix2.toDouble(),
          ix: ix.toDouble(),
          delta: delta.toDouble(),
          invalid: false,
        ),
      );
    }

    if (hasInvalid) {
      return PotentialDifferenceCalculation(
        rows: List.unmodifiable(rows),
        k: null,
        maxDelta: null,
        maxStandard: null,
        error: '请检查输入：每组数据都需要填写 Is、Ux1 和 Ux2',
        recommendedRows: const [],
      );
    }
    if (rows.isEmpty) return _empty('请先填写一组测量数据');

    final validRows = rows.where((row) => !row.invalid).toList(growable: false);
    final maxDelta = validRows
        .map((row) => row.delta!.abs())
        .reduce((left, right) => left > right ? left : right);
    final maxStandard = validRows
        .map((row) => row.standard!.abs())
        .reduce((left, right) => left > right ? left : right);
    if (maxStandard == 0) {
      return PotentialDifferenceCalculation(
        rows: List.unmodifiable(rows),
        k: null,
        maxDelta: maxDelta,
        maxStandard: maxStandard,
        error: '标准电流 Is 不能全部为 0',
        recommendedRows: const [],
      );
    }

    final k = maxDelta / maxStandard * 100;
    final recommendations = uncertainty == null
        ? const <PotentialDifferenceRecommendedRow>[]
        : validRows
              .map(
                (row) => PotentialDifferenceRecommendedRow(
                  ix: _roundToUncertainty(row.ix, uncertainty),
                  delta: _roundToUncertainty(row.delta, uncertainty),
                ),
              )
              .toList(growable: false);
    return PotentialDifferenceCalculation(
      rows: List.unmodifiable(rows),
      k: k,
      maxDelta: maxDelta,
      maxStandard: maxStandard,
      error: '',
      recommendedRows: recommendations,
    );
  }

  static List<PotentialDifferenceInputRow>? parsePaste(String text) {
    final source = text.trim();
    if (source.isEmpty) return null;
    final pattern = RegExp(r'[+-]?(?:\d+(?:\.\d*)?|\.\d+)');
    final lines = source
        .split(RegExp(r'\r?\n'))
        .map(
          (line) => pattern
              .allMatches(line)
              .map((match) => match.group(0)!)
              .toList(growable: false),
        )
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    List<List<String>>? values;
    if (lines.length == 3 && lines.every((line) => line.length == 8)) {
      values = lines;
    } else {
      final all = pattern
          .allMatches(source)
          .map((match) => match.group(0)!)
          .toList(growable: false);
      if (all.length == 24) {
        values = [all.sublist(0, 8), all.sublist(8, 16), all.sublist(16, 24)];
      }
    }
    if (values == null) return null;
    return List<PotentialDifferenceInputRow>.generate(
      8,
      (index) => PotentialDifferenceInputRow(
        standard: values![0][index],
        ux1: values[1][index],
        ux2: values[2][index],
      ),
      growable: false,
    );
  }

  static String format(double? value, {int digits = 15}) {
    if (value == null || !value.isFinite) return '—';
    final parsed = PhysicsDecimal.parse(value.toString());
    if (parsed != null) return parsed.format(maxFraction: digits);
    final fixed = value.toStringAsFixed(digits);
    final trimmed = fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return trimmed == '-0' ? '0' : trimmed;
  }

  static PotentialDifferenceCalculation _empty(String error) {
    return PotentialDifferenceCalculation(
      rows: const [],
      k: null,
      maxDelta: null,
      maxStandard: null,
      error: error,
      recommendedRows: const [],
    );
  }

  static String? _roundToUncertainty(
    double? value,
    PhysicsDecimal uncertainty,
  ) {
    final parsed = value == null
        ? null
        : PhysicsDecimal.parse(value.toString());
    return parsed?.format(maxFraction: uncertainty.scale);
  }
}
