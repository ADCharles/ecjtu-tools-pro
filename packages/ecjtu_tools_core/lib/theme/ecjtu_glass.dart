// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

import '../features/settings/settings_models.dart';
import 'ecjtu_desktop_tokens.dart';

class EcjtuDesktopColorStyle extends ThemeExtension<EcjtuDesktopColorStyle> {
  const EcjtuDesktopColorStyle(this.style);

  final DesktopColorStyle style;

  @override
  EcjtuDesktopColorStyle copyWith({DesktopColorStyle? style}) =>
      EcjtuDesktopColorStyle(style ?? this.style);

  @override
  EcjtuDesktopColorStyle lerp(
    covariant ThemeExtension<EcjtuDesktopColorStyle>? other,
    double t,
  ) => this;
}

class EcjtuGlass {
  const EcjtuGlass._(this.dark, this.style, [this.mobile = false]);
  final bool dark;
  final bool mobile;
  final DesktopColorStyle style;
  static DesktopColorStyle platformStyle = DesktopColorStyle.blue;
  static Color mobileChromeFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFF111111)
      : const Color(0xFFEDEDED);
  static EcjtuGlass forBrightness(
    Brightness brightness, [
    DesktopColorStyle style = DesktopColorStyle.blue,
    bool mobile = false,
  ]) => EcjtuGlass._(brightness == Brightness.dark, style, mobile);
  static EcjtuGlass of(BuildContext context) => EcjtuGlass._(
    Theme.of(context).brightness == Brightness.dark,
    Theme.of(context).extension<EcjtuDesktopColorStyle>()?.style ??
        DesktopColorStyle.blue,
    {
      TargetPlatform.android,
      TargetPlatform.iOS,
    }.contains(Theme.of(context).platform),
  );

  fluent.ResourceDictionary get resources => dark
      ? const fluent.ResourceDictionary.dark()
      : const fluent.ResourceDictionary.light();
  bool get blue => style == DesktopColorStyle.blue;
  bool get green => style == DesktopColorStyle.green;
  bool get tinted => blue || green;
  EcjtuDesktopNeutral get neutral => EcjtuDesktopNeutral(dark);
  // DWM supplies an untinted system backdrop, not the source UI's material
  // base. Thin tints over it turn light navigation into dark gray.
  Color get navigationMaterial => panel.withValues(alpha: dark ? .94 : .97);
  Color get titleMaterial => backdrop.first.withValues(alpha: dark ? .94 : .97);
  LinearGradient get chromeGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [backdrop.first, Color.lerp(backdrop.first, content, .08)!],
  );
  Color _blueSurface(Color blue, Color neutral) =>
      Color.lerp(neutral, blue, .65)!;
  Color _darkBlueSurface(Color slate) =>
      Color.lerp(slate, const Color(0xFF091C32), .65)!;
  Color _greenSurface(Color green, Color neutral) =>
      Color.lerp(neutral, green, .65)!;
  Color _darkGreenSurface(Color neutral) =>
      Color.lerp(neutral, const Color(0xFF132D21), .35)!;
  Color get chromeText => text;
  Color get chromeMuted => muted;
  Map<String, int> get nativeChromeColors => {
    'backdropColor': backdrop.first.toARGB32(),
    'contentColor': content.toARGB32(),
    'borderColor': contentBorder.toARGB32(),
  };
  List<Color> get backdrop => mobile
      ? [panel, panel]
      : [
          blue
              ? (dark
                    ? _darkBlueSurface(const Color(0xFF3B434B))
                    : _blueSurface(
                        const Color(0xFFC2E5FF),
                        const Color(0xFFF8F8F8),
                      ))
              : green
              ? (dark
                    ? _darkGreenSurface(const Color(0xFF3B4340))
                    : _greenSurface(
                        const Color(0xFFC4E8D1),
                        const Color(0xFFF8F8F8),
                      ))
              : neutral.navigation,
        ];
  Color get panel => mobile
      ? mobileChromeFor(dark ? Brightness.dark : Brightness.light)
      : blue
      ? (dark
            ? _darkBlueSurface(const Color(0xFF434C56))
            : const Color(0xFFEDF6FC))
      : green
      ? (dark
            ? _darkGreenSurface(const Color(0xFF434C48))
            : _greenSurface(const Color(0xFFE6F6EB), const Color(0xFFFBFBFB)))
      : neutral.panel;
  Color get directory =>
      mobile ? (dark ? const Color(0xFF141414) : Colors.white) : panel;
  Color get content => !dark
      ? Colors.white
      : mobile
      ? (dark ? const Color(0xFF191919) : Colors.white)
      : blue
      ? (dark
            ? _darkBlueSurface(const Color(0xFF333A41))
            : _blueSurface(const Color(0xFFF4FAFF), const Color(0xFFFDFDFD)))
      : green
      ? (dark
            ? _darkGreenSurface(const Color(0xFF333A37))
            : _greenSurface(const Color(0xFFF4FBF6), const Color(0xFFFDFDFD)))
      : neutral.content;
  Color get card => mobile
      ? (dark ? const Color(0xFF191919) : Colors.white)
      : blue
      ? (dark ? _darkBlueSurface(const Color(0xFF2B3035)) : Colors.white)
      : green
      ? (dark ? _darkGreenSurface(const Color(0xFF2B3030)) : Colors.white)
      : neutral.card;
  Color get note => dark
      ? (tinted ? card : const Color(0xFF242424))
      : (tinted ? Color.lerp(content, panel, .24)! : const Color(0xFFF6FAFD));
  Color get noteLabel => dark
      ? (tinted ? panel : const Color(0xFF303030))
      : green
      ? const Color(0xFFE6F6EB)
      : const Color(0xFFE8F3FA);
  LinearGradient get contentGradient => mobile || !dark
      ? LinearGradient(colors: [content, content])
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            blue
                ? (dark
                      ? panel
                      : _blueSurface(
                          const Color(0xFFEDF6FC),
                          const Color(0xFFFBFBFB),
                        ))
                : green
                ? (dark
                      ? panel
                      : _greenSurface(
                          const Color(0xFFE6F6EB),
                          const Color(0xFFFBFBFB),
                        ))
                : content,
            content,
            blue
                ? (dark
                      ? Color.lerp(content, panel, .35)!
                      : _blueSurface(
                          const Color(0xFFFBFDFF),
                          const Color(0xFFFDFDFD),
                        ))
                : green
                ? (dark
                      ? Color.lerp(content, panel, .35)!
                      : const Color(0xFFFBFEFC))
                : content,
          ],
          stops: const [0, .65, 1],
        );
  Color get panelHighlight => Color.alphaBlend(neutral.hover, panel);
  Color get panelBorder => Color.alphaBlend(neutral.separator, panel);
  Color get navigationOutline => Color.alphaBlend(
    dark ? const Color(0x40FFFFFF) : const Color(0x29000000),
    backdrop.first,
  );
  Color get rail => Color.lerp(backdrop.first, panel, .58)!;
  Color get contentBorder => Color.alphaBlend(neutral.separator, content);
  Color get contentOutline => Color.alphaBlend(
    dark ? const Color(0x33FFFFFF) : const Color(0x26000000),
    content,
  );
  Color get text => Color.alphaBlend(neutral.foreground, neutral.content);
  Color get muted => tinted && dark
      ? const Color(0xFFB4BEC7)
      : Color.alphaBlend(neutral.secondary, neutral.content);
  Color get glyph => neutral.glyph;
  Color get accent => blue
      ? (dark ? const Color(0xFF70B8FF) : const Color(0xFF0D74CE))
      : green
      ? (dark ? const Color(0xFF3DD68C) : const Color(0xFF1E874C))
      : dark
      ? Colors.lightBlue.shade200
      : fluent.Colors.blue.darker;
  Color get selected => blue
      ? (dark
            ? Color.alphaBlend(const Color(0x260D74CE), panel)
            : _blueSurface(const Color(0xFFD5EFFF), const Color(0xFFF0F0F0)))
      : green
      ? (dark
            ? Color.alphaBlend(const Color(0x2630A46C), panel)
            : _greenSurface(const Color(0xFFD6F1DF), const Color(0xFFF0F0F0)))
      : Color.alphaBlend(
          dark ? accent.withValues(alpha: .18) : neutral.hover,
          panel,
        );
  Color get selectedBorder => Colors.transparent;
  Color get segmentedTrack => dark
      ? card
      : green
      ? _greenSurface(const Color(0xFFE6F6EB), const Color(0xFFF4F8F5))
      : blue
      ? const Color(0xFFEDF5FA)
      : card;
  Color get hover => Color.alphaBlend(neutral.hover, card);
  Color get badge => const Color(0xFFD94F55);
}
