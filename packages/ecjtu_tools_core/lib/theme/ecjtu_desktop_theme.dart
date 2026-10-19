// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoThemeData, CupertinoTextThemeData;

import '../features/settings/settings_models.dart';
import 'ecjtu_control_palette.dart';
import 'ecjtu_glass.dart';
import 'ecjtu_desktop_tokens.dart';

class EcjtuDesktopTheme {
  const EcjtuDesktopTheme._();

  static ThemeData apply(
    ThemeData base, {
    DesktopColorStyle style = DesktopColorStyle.blue,
    bool preserveTypography = false,
  }) {
    final dark = base.brightness == Brightness.dark;
    final mobile =
        base.platform == TargetPlatform.android ||
        base.platform == TargetPlatform.iOS;
    final colors = EcjtuGlass.forBrightness(
      base.brightness,
      style,
      preserveTypography,
    );
    final palette = EcjtuControlPalette(
      surface: colors.card,
      subtle: colors.content,
      border: colors.contentOutline,
      foreground: colors.text,
      muted: colors.muted,
      selected: colors.selected,
      hover: colors.hover,
      focus: colors.accent,
      activeTrack: colors.accent,
      inactiveTrack: dark ? const Color(0xFF666666) : const Color(0xFFCCCCCC),
      thumb: Colors.white,
      success: dark ? const Color(0xFF65D6A3) : const Color(0xFF067647),
    );
    final scheme = base.colorScheme.copyWith(
      primary: colors.accent,
      onPrimary: dark ? Colors.black : Colors.white,
      primaryContainer: colors.selected,
      onPrimaryContainer: colors.text,
      secondary: colors.accent,
      onSecondary: dark ? Colors.black : Colors.white,
      secondaryContainer: colors.selected,
      onSecondaryContainer: colors.text,
      tertiary: colors.accent,
      onTertiary: dark ? Colors.black : Colors.white,
      tertiaryContainer: colors.selected,
      onTertiaryContainer: colors.text,
      surface: colors.card,
      surfaceContainerLowest: colors.content,
      surfaceContainerLow: colors.content,
      surfaceContainer: colors.card,
      surfaceContainerHigh: colors.hover,
      surfaceContainerHighest: colors.selected,
      onSurface: colors.text,
      onSurfaceVariant: colors.muted,
      outline: colors.contentOutline,
      outlineVariant: colors.contentBorder,
    );
    final text = base.textTheme.apply(
      bodyColor: colors.text,
      displayColor: colors.text,
    );
    return base.copyWith(
      scrollbarTheme: mobile
          ? const ScrollbarThemeData(
              thickness: WidgetStatePropertyAll(0),
              thumbVisibility: WidgetStatePropertyAll(false),
              trackVisibility: WidgetStatePropertyAll(false),
              interactive: false,
            )
          : base.scrollbarTheme,
      cupertinoOverrideTheme: preserveTypography
          ? CupertinoThemeData(
              brightness: base.brightness,
              primaryColor: colors.accent,
              scaffoldBackgroundColor: colors.content,
              barBackgroundColor: colors.panel,
              textTheme: CupertinoTextThemeData(
                textStyle: text.bodyMedium ?? const TextStyle(fontSize: 16),
                tabLabelTextStyle: TextStyle(
                  fontFamily: text.bodyMedium?.fontFamily,
                  fontFamilyFallback: text.bodyMedium?.fontFamilyFallback,
                  fontSize: 11,
                ),
              ),
            )
          : base.cupertinoOverrideTheme,
      extensions: [
        ...base.extensions.values.where(
          (e) => e is! EcjtuControlPalette && e is! EcjtuDesktopColorStyle,
        ),
        EcjtuDesktopColorStyle(style),
        palette,
      ],
      scaffoldBackgroundColor: colors.content,
      tooltipTheme: base.tooltipTheme.copyWith(
        waitDuration: const Duration(seconds: 1),
      ),
      canvasColor: colors.card,
      cardColor: colors.card,
      dividerColor: colors.contentBorder,
      colorScheme: scheme,
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: colors.contentOutline),
      ),
      textSelectionTheme: base.textSelectionTheme.copyWith(
        cursorColor: colors.accent,
        selectionColor: colors.accent.withValues(alpha: .18),
        selectionHandleColor: colors.accent,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.dialogTheme.titleTextStyle?.copyWith(
          color: colors.text,
        ),
        contentTextStyle: base.dialogTheme.contentTextStyle?.copyWith(
          color: colors.text,
        ),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        textStyle: text.bodyMedium,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colors.card,
        modalBackgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: preserveTypography
          ? text
          : text.copyWith(
              titleLarge: text.titleLarge?.copyWith(
                fontSize: EcjtuDesktopType.title,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              titleMedium: text.titleMedium?.copyWith(
                fontSize: EcjtuDesktopType.heading,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              bodyLarge: text.bodyLarge?.copyWith(
                fontSize: EcjtuDesktopType.body,
                height: 1.5,
              ),
              bodyMedium: text.bodyMedium?.copyWith(
                fontSize: EcjtuDesktopType.body,
                height: 1.5,
              ),
              bodySmall: text.bodySmall?.copyWith(
                fontSize: EcjtuDesktopType.description,
                height: 1.4,
                color: colors.muted,
              ),
            ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: colors.card,
        hoverColor: colors.hover,
        hintStyle: base.inputDecorationTheme.hintStyle?.copyWith(
          color: colors.muted,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.contentOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.accent, width: 1.25),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: colors.contentOutline.withValues(alpha: .5),
          ),
        ),
      ),
      focusColor: colors.accent.withValues(alpha: .12),
    );
  }
}
