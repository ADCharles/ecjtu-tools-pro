// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class PhysicsDecimal {
  const PhysicsDecimal._(this.coefficient, this.scale);

  final BigInt coefficient;
  final int scale;

  static final _pattern = RegExp(
    r'^([+-]?)(?:(\d+)(?:\.(\d*))?|\.(\d+))(?:[eE]([+-]?\d+))?$',
  );

  factory PhysicsDecimal.fromInt(int value) {
    return PhysicsDecimal._(BigInt.from(value), 0);
  }

  static PhysicsDecimal? parse(Object? raw) {
    final text = raw?.toString().trim().replaceAll(',', '') ?? '';
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final exponent = int.tryParse(match.group(5) ?? '0');
    if (exponent == null || exponent.abs() > 1000) return null;
    final negative = match.group(1) == '-';
    final integerPart = match.group(2) ?? '0';
    final fractionPart = match.group(3) ?? match.group(4) ?? '';
    var coefficient = BigInt.parse('$integerPart$fractionPart');
    if (negative) coefficient = -coefficient;
    var scale = fractionPart.length - exponent;
    if (scale < 0) {
      coefficient *= _powerOfTen(-scale);
      scale = 0;
    }
    return _normalize(coefficient, scale);
  }

  bool get isZero => coefficient == BigInt.zero;

  double toDouble() {
    final value = coefficient.toDouble();
    return value / _powerOfTen(scale).toDouble();
  }

  PhysicsDecimal operator +(PhysicsDecimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    return _normalize(
      coefficient * _powerOfTen(targetScale - scale) +
          other.coefficient * _powerOfTen(targetScale - other.scale),
      targetScale,
    );
  }

  PhysicsDecimal operator -(PhysicsDecimal other) {
    return this + PhysicsDecimal._(-other.coefficient, other.scale);
  }

  PhysicsDecimal operator *(PhysicsDecimal other) {
    return _normalize(coefficient * other.coefficient, scale + other.scale);
  }

  PhysicsDecimal abs() =>
      coefficient < BigInt.zero ? PhysicsDecimal._(-coefficient, scale) : this;

  PhysicsDecimal divide(PhysicsDecimal other, {int precision = 50}) {
    if (other.isZero) throw StateError('division by zero');
    final places = precision < 0 ? 0 : precision;
    final negative =
        (coefficient < BigInt.zero) != (other.coefficient < BigInt.zero);
    final numeratorBase = coefficient.abs();
    final denominatorBase = other.coefficient.abs();
    final exponent = places + other.scale - scale;
    var numerator = numeratorBase;
    var denominator = denominatorBase;
    if (exponent >= 0) {
      numerator *= _powerOfTen(exponent);
    } else {
      denominator *= _powerOfTen(-exponent);
    }
    var quotient = numerator ~/ denominator;
    if ((numerator.remainder(denominator) * BigInt.two) >= denominator) {
      quotient += BigInt.one;
    }
    if (negative) quotient = -quotient;
    return _normalize(quotient, places);
  }

  String format({int maxFraction = 16}) {
    var value = this;
    final places = maxFraction < 0 ? 0 : maxFraction;
    if (value.scale > places) {
      value = _roundToScale(value, places);
    }
    final negative = value.coefficient < BigInt.zero;
    final digits = (negative ? -value.coefficient : value.coefficient)
        .toString()
        .padLeft(value.scale + 1, '0');
    if (value.scale == 0) return '${negative ? '-' : ''}$digits';
    final split = digits.length - value.scale;
    final integerPart = digits.substring(0, split);
    final fractionPart = digits
        .substring(split)
        .replaceFirst(RegExp(r'0+$'), '');
    if (fractionPart.isEmpty) return '${negative ? '-' : ''}$integerPart';
    return '${negative ? '-' : ''}$integerPart.$fractionPart';
  }

  static PhysicsDecimal _normalize(BigInt coefficient, int scale) {
    while (scale > 0 &&
        coefficient != BigInt.zero &&
        coefficient.remainder(BigInt.from(10)) == BigInt.zero) {
      coefficient ~/= BigInt.from(10);
      scale--;
    }
    return PhysicsDecimal._(coefficient, scale);
  }

  static PhysicsDecimal _roundToScale(PhysicsDecimal value, int targetScale) {
    if (value.scale <= targetScale) return value;
    final factor = _powerOfTen(value.scale - targetScale);
    final negative = value.coefficient < BigInt.zero;
    final magnitude = value.coefficient.abs();
    var quotient = magnitude ~/ factor;
    if ((magnitude.remainder(factor) * BigInt.two) >= factor) {
      quotient += BigInt.one;
    }
    return _normalize(negative ? -quotient : quotient, targetScale);
  }

  static BigInt _powerOfTen(int exponent) {
    if (exponent <= 0) return BigInt.one;
    return BigInt.parse('1${'0' * exponent}');
  }
}
