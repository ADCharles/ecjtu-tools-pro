// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_physics_core/ecjtu_physics_core.dart';

void main() {
  final state = SolidDensityState.initial().copyWith(
    rectangular: SolidDensityRectangularInput(
      length: List.filled(5, '2'),
      width: List.filled(5, '3'),
      height: List.filled(5, '4'),
      mass: '24',
      massError: '0',
    ),
  );
  final result = SolidDensityCalculator.calculate(state).rectangular;
  if (result.volume != 24 || result.density != 1) {
    throw StateError('Unexpected solid density result');
  }
  print('volume=${result.volume}, density=${result.density}');
}
