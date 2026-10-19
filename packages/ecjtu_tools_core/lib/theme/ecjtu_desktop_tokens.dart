// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

class EcjtuDesktopType {
  const EcjtuDesktopType._();
  static const body = 14.0;
  static const description = 12.0;
  static const caption = 10.0;
  static const heading = 16.0;
  static const title = 22.0;
}

class EcjtuDesktopNeutral {
  const EcjtuDesktopNeutral(this.dark);
  final bool dark;
  Color get navigation =>
      dark ? const Color(0xFF3B3B3D) : const Color(0xFFFAFAFA);
  Color get panel => dark ? const Color(0xFF2F2F30) : const Color(0xFFFDFDFD);
  Color get content => dark ? const Color(0xFF242424) : Colors.white;
  Color get card => dark ? const Color(0xFF3B3B3D) : const Color(0xFFFAFAFA);
  Color get foreground =>
      dark ? const Color(0xCCFFFFFF) : const Color(0xE5000000);
  Color get secondary =>
      dark ? const Color(0x99FFFFFF) : const Color(0xB2000000);
  Color get separator =>
      dark ? const Color(0x1AFFFFFF) : const Color(0x08000000);
  Color get hover => dark ? const Color(0x0DFFFFFF) : const Color(0x0D000000);
  Color get glyph => dark ? const Color(0xFFE1E1E5) : const Color(0xFF19191A);
  Color get material =>
      dark ? const Color(0x99252526) : const Color(0x4DE6E6ED);
  Color get thickMaterial =>
      dark ? const Color(0xE5222222) : const Color(0xCCF7F7F7);
}
