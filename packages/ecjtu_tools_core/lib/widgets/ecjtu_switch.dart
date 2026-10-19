// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';
import '../theme/ecjtu_control_palette.dart';

/// 与设置页一致的胶囊开关（48×28，白色圆点）。
class EcjtuSwitch extends StatelessWidget {
  const EcjtuSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    return Semantics(
      toggled: value,
      button: true,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? palette?.activeTrack ??
                      (dark ? EcjtuColors.darkPrimary : EcjtuColors.primary)
                : palette?.inactiveTrack ??
                      (EcjtuColors.borderFrom(
                        context,
                        dark ? EcjtuColors.darkBorder : EcjtuColors.switchOff,
                      )),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Align(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: palette?.thumb ?? Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
