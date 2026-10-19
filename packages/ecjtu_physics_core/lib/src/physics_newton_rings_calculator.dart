// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'physics_newton_rings_models.dart';
import 'physics_decimal.dart';

class NewtonRingsCalculator {
  const NewtonRingsCalculator._();

  static NewtonRingsCalculation calculate(NewtonRingsState state) {
    final rings = List<NewtonRingComputed>.generate(
      NewtonRingsState.ringCount,
      (index) => _calculateRing(state.rings[index], index),
      growable: false,
    );
    final pairs = List<NewtonRingPairComputed>.generate(
      NewtonRingsState.pairCount,
      (index) => _calculatePair(rings[index], rings[index + 5], index),
      growable: false,
    );

    final wavelength = PhysicsDecimal.parse(state.wavelength);
    final pairGap = PhysicsDecimal.parse(state.pairGap);
    final invalidRing = rings.where((ring) => ring.invalid).firstOrNull;
    if (invalidRing != null) {
      return NewtonRingsCalculation(
        rings: rings,
        pairs: pairs,
        complete: false,
        errorMessage: '第 ${invalidRing.index + 1} 个暗环的环序、左读数或右读数不完整，或不是有效数字。',
      );
    }
    if (wavelength == null ||
        wavelength.isZero ||
        pairGap == null ||
        pairGap.isZero) {
      return NewtonRingsCalculation(
        rings: rings,
        pairs: pairs,
        complete: false,
        errorMessage: '请填写有效的钠光波长和计算用环序差。',
      );
    }
    if (rings.any((ring) => ring.blank)) {
      return NewtonRingsCalculation(
        rings: rings,
        pairs: pairs,
        complete: false,
        errorMessage: '请填写完整的 10 个暗环的左右读数后计算。',
      );
    }

    final deltaValues = pairs
        .map((pair) => PhysicsDecimal.parse(pair.deltaSquare))
        .whereType<PhysicsDecimal>()
        .toList(growable: false);
    if (deltaValues.length != NewtonRingsState.pairCount) {
      return NewtonRingsCalculation(
        rings: rings,
        pairs: pairs,
        complete: false,
        errorMessage: '五组暗环数据还不完整，暂时无法计算曲率半径。',
      );
    }
    final average = deltaValues
        .reduce((left, right) => left + right)
        .divide(PhysicsDecimal.fromInt(NewtonRingsState.pairCount));
    final error = deltaValues
        .map((value) => (value - average).abs())
        .reduce((left, right) => left + right)
        .divide(PhysicsDecimal.fromInt(NewtonRingsState.pairCount));
    final denominator = PhysicsDecimal.fromInt(4) * pairGap * wavelength;
    final radiusTable = average.divide(denominator);
    final radiusErrorTable = error.divide(denominator);
    final radiusMeters = radiusTable * PhysicsDecimal.fromInt(1000);
    final radiusErrorMeters = radiusErrorTable * PhysicsDecimal.fromInt(1000);

    return NewtonRingsCalculation(
      rings: rings,
      pairs: pairs,
      complete: true,
      average: average.format(),
      error: error.format(),
      radiusTable: radiusTable.format(),
      radiusErrorTable: radiusErrorTable.format(),
      radiusMeters: radiusMeters.format(),
      radiusErrorMeters: radiusErrorMeters.format(),
    );
  }

  static NewtonRingComputed _calculateRing(NewtonRingInput input, int index) {
    final orderText = input.order.trim();
    final leftText = input.left.trim();
    final rightText = input.right.trim();
    final defaultOrder = NewtonRingInput.defaultFor(index).order;
    final hasInput =
        leftText.isNotEmpty ||
        rightText.isNotEmpty ||
        orderText != defaultOrder;
    final order = PhysicsDecimal.parse(orderText);
    final left = PhysicsDecimal.parse(leftText);
    final right = PhysicsDecimal.parse(rightText);
    if (!hasInput) {
      return NewtonRingComputed(
        index: index,
        kind: input.kind,
        order: orderText,
        left: leftText,
        right: rightText,
        blank: true,
      );
    }
    if (order == null || left == null || right == null) {
      return NewtonRingComputed(
        index: index,
        kind: input.kind,
        order: orderText,
        left: leftText,
        right: rightText,
        invalid: true,
      );
    }
    final diameter = (left - right).abs();
    return NewtonRingComputed(
      index: index,
      kind: input.kind,
      order: order.format(),
      left: left.format(),
      right: right.format(),
      diameter: diameter.format(),
      diameterSquare: (diameter * diameter).format(),
    );
  }

  static NewtonRingPairComputed _calculatePair(
    NewtonRingComputed mRing,
    NewtonRingComputed nRing,
    int index,
  ) {
    final mOrder = PhysicsDecimal.parse(mRing.order);
    final nOrder = PhysicsDecimal.parse(nRing.order);
    final mSquare = PhysicsDecimal.parse(mRing.diameterSquare);
    final nSquare = PhysicsDecimal.parse(nRing.diameterSquare);
    final actualGap = mOrder != null && nOrder != null
        ? (mOrder - nOrder).format()
        : null;
    final complete = mSquare != null && nSquare != null;
    return NewtonRingPairComputed(
      index: index,
      mOrder: mOrder?.format(),
      nOrder: nOrder?.format(),
      actualGap: actualGap,
      mSquare: mSquare?.format(),
      nSquare: nSquare?.format(),
      deltaSquare: complete ? (mSquare - nSquare).format() : null,
      complete: complete,
    );
  }
}
