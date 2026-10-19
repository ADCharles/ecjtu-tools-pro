// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

@immutable
class EcjtuControlPalette extends ThemeExtension<EcjtuControlPalette> {
  const EcjtuControlPalette({
    required this.surface,
    required this.subtle,
    required this.border,
    required this.foreground,
    required this.muted,
    required this.selected,
    required this.hover,
    required this.focus,
    required this.activeTrack,
    required this.inactiveTrack,
    required this.thumb,
    required this.success,
  });

  final Color surface, subtle, border, foreground, muted;
  final Color selected,
      hover,
      focus,
      activeTrack,
      inactiveTrack,
      thumb,
      success;

  static EcjtuControlPalette? maybeOf(BuildContext context) =>
      Theme.of(context).extension<EcjtuControlPalette>();

  @override
  EcjtuControlPalette copyWith({
    Color? surface,
    Color? subtle,
    Color? border,
    Color? foreground,
    Color? muted,
    Color? selected,
    Color? hover,
    Color? focus,
    Color? activeTrack,
    Color? inactiveTrack,
    Color? thumb,
    Color? success,
  }) => EcjtuControlPalette(
    surface: surface ?? this.surface,
    subtle: subtle ?? this.subtle,
    border: border ?? this.border,
    foreground: foreground ?? this.foreground,
    muted: muted ?? this.muted,
    selected: selected ?? this.selected,
    hover: hover ?? this.hover,
    focus: focus ?? this.focus,
    activeTrack: activeTrack ?? this.activeTrack,
    inactiveTrack: inactiveTrack ?? this.inactiveTrack,
    thumb: thumb ?? this.thumb,
    success: success ?? this.success,
  );

  @override
  EcjtuControlPalette lerp(EcjtuControlPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return EcjtuControlPalette(
      surface: mix(surface, other.surface),
      subtle: mix(subtle, other.subtle),
      border: mix(border, other.border),
      foreground: mix(foreground, other.foreground),
      muted: mix(muted, other.muted),
      selected: mix(selected, other.selected),
      hover: mix(hover, other.hover),
      focus: mix(focus, other.focus),
      activeTrack: mix(activeTrack, other.activeTrack),
      inactiveTrack: mix(inactiveTrack, other.inactiveTrack),
      thumb: mix(thumb, other.thumb),
      success: mix(success, other.success),
    );
  }
}
