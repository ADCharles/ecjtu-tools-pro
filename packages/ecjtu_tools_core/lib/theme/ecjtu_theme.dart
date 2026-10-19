// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ecjtu_control_palette.dart';
import 'ecjtu_glass.dart';
import 'ecjtu_desktop_tokens.dart';

class EcjtuColors {
  const EcjtuColors._();

  static bool get _desktop =>
      !kIsWeb &&
      const {
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      }.contains(defaultTargetPlatform);
  static EcjtuGlass _glass(bool dark) => EcjtuGlass.forBrightness(
    dark ? Brightness.dark : Brightness.light,
    EcjtuGlass.platformStyle,
  );
  static Color platformSurface(bool dark, Color fallback) =>
      _desktop ? _glass(dark).card : fallback;
  static Color platformBorder(bool dark, Color fallback) =>
      _desktop ? _glass(dark).contentOutline : fallback;
  static Color platformText(bool dark, Color fallback) =>
      _desktop ? _glass(dark).text : fallback;
  static Color platformMuted(bool dark, Color fallback) =>
      _desktop ? _glass(dark).muted : fallback;
  static Color platformHover(bool dark, Color fallback) =>
      _desktop ? _glass(dark).hover : fallback;

  static Color surfaceFrom(BuildContext context, Color fallback) =>
      EcjtuControlPalette.maybeOf(context)?.surface ?? fallback;
  static Color borderFrom(BuildContext context, Color fallback) =>
      EcjtuControlPalette.maybeOf(context)?.border ?? fallback;
  static Color hoverFrom(BuildContext context, Color fallback) =>
      EcjtuControlPalette.maybeOf(context)?.hover ?? fallback;
  static Color textFrom(BuildContext context, Color fallback) =>
      EcjtuControlPalette.maybeOf(context)?.foreground ?? fallback;
  static Color mutedFrom(BuildContext context, Color fallback) =>
      EcjtuControlPalette.maybeOf(context)?.muted ?? fallback;

  static Color surfaceFor(BuildContext context) =>
      EcjtuControlPalette.maybeOf(context)?.surface ??
      (Theme.of(context).brightness == Brightness.dark
          ? darkControlSurface
          : controlSurface);
  static Color borderFor(BuildContext context) =>
      EcjtuControlPalette.maybeOf(context)?.border ??
      (Theme.of(context).brightness == Brightness.dark ? darkBorder : border);
  static Color textFor(BuildContext context) =>
      EcjtuControlPalette.maybeOf(context)?.foreground ??
      (Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : textPrimary);
  static Color mutedFor(BuildContext context) =>
      EcjtuControlPalette.maybeOf(context)?.muted ??
      (Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : textSecondary);
  static Color pageFor(BuildContext context) =>
      EcjtuControlPalette.maybeOf(context)?.subtle ??
      (Theme.of(context).brightness == Brightness.dark
          ? darkPageBackground
          : pageBackground);

  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const frameBorder = Color(0xFFDFE3E8);
  static const controlSurface = Color(0xFFFFFFFF);
  static const pageBackground = Color(0xFFFFFFFF);
  static const nativeWindowBackground = Color(0xFFFFFFFF);
  static const primary = Color(0xFF0475CC);
  static const selectionActive = Color(0xFF347AA7);
  static const arrangementActive = Color(0xFF0B5F99);
  static const segmentedSurface = Color(0xFFEDF5FA);
  static const segmentedBorder = Color(0xFFCADDEA);
  static const weekdaySurface = Color(0xFFEDF2F7);
  static const switchOff = Color(0xFFD0D5DD);
  static const headerStart = Color(0xFF0B5E98);
  static const headerEnd = Color(0xFF0B5E98);
  static const loginHeader = Color(0xFF0668B4);
  static const startupBackground = Color(0xFF07558E);
  static const headerMiddle = Color(0xFF08649F);
  static const headerDivider = Color(0xFF5F7F9D);

  static const darkTextPrimary = Color(0xFFE8F0FC);
  static const darkTextSecondary = Color(0xFF9EACC3);
  static const darkBorder = Color(0xFF293851);
  static const darkFrameBorder = Color(0xFF26344B);
  static const darkControlSurface = Color(0xFF131E32);
  static const darkPageBackground = Color(0xFF0E1525);
  static const darkNativeWindowBackground = Color(0xFF0E1525);
  static const darkPrimary = Color(0xFF4A9EFF);
  static const darkSelectionActive = Color(0xFF264A71);
  static const darkSegmentedSurface = Color(0xFF101A2C);
  static const darkSegmentedBorder = Color(0xFF34445F);
  static const darkWeekdaySurface = Color(0xFF101A2C);
  static const darkHeaderStart = Color(0xFF0A3568);
  static const darkHeaderEnd = Color(0xFF0A3568);
  static const darkHeaderMiddle = Color(0xFF103F70);
  static const darkHeaderDivider = Color(0xFF3D6388);

  /// Stops for a three-colour header gradient that spans the whole window.
  /// The header itself only occupies [columnWidth], so the global 0 / 50% /
  /// 100% positions are remapped onto that column; this keeps the header and
  /// the window-control strip on one continuous ramp (see the plugin's
  /// `linear-gradient(90deg, #0d3f78 0%, #0a3568 50%, #0d3f78 100%)`).
  static List<double> headerGradientStops({
    required double windowWidth,
    required double columnWidth,
  }) {
    if (windowWidth <= 0 || columnWidth <= 0 || columnWidth >= windowWidth) {
      return const [0, 0.5, 1];
    }
    final extent = (columnWidth / windowWidth).clamp(0.01, 1.0);
    return [0, (0.5 / extent).clamp(0.0, 1.0), 1];
  }

  static const smartWorkSurface = Color(0xFFF8FBFD);
  static const smartWorkBorder = Color(0xFFD5E4EF);
  static const smartWorkIcon = Color(0xFF3F82A6);
  static const smartWorkStrongText = Color(0xFF223549);
  static const smartWorkCardText = Color(0xFF29445D);
  static const smartWorkSecondarySurface = Color(0xFFF2F8FC);
  static const smartWorkSecondaryBorder = Color(0xFFA9C9DC);
  static const smartWorkSecondaryText = Color(0xFF275B7A);

  static const darkSmartWorkSecondarySurface = Color(0xFF14263A);
  static const darkSmartWorkSecondaryBorder = Color(0xFF426B83);
  static const darkSmartWorkSecondaryText = Color(0xFFB7D9ED);
  static const darkSmartWorkSearchSurface = Color(0xFF16263D);
  static const darkSmartWorkSearchBorder = Color(0xFF3B5878);
  static const darkSmartWorkSearchText = Color(0xFFD9EBFF);
}

class EcjtuMetrics {
  const EcjtuMetrics._();

  static const compactHeaderHeight = 64.0;
  static const fullHeaderHeight = 88.0;
  static const compactNavigationHeight = 46.0;
  static const fullNavigationHeight = 58.0;
  static const cardPadding = 14.0;
  static const cardRadius = 7.0;
  static const pickerHeight = 32.0;
  static const pickerRadius = 6.0;
  static const pickerItemHeight = 28.0;
  static const pickerMaxHeight = 142.0;
  static const compactBreakpoint = 761.0;

  static bool phoneLayout(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.android ||
      Theme.of(context).platform == TargetPlatform.iOS;
  static double mobileSectionTitleFor(BuildContext context) {
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final base = size.shortestSide >= 600 ? 28.0 : 24.0;
    return size.width > size.height ? 22 : base;
  }

  static double pageHeaderHeightFor(BuildContext context) {
    if (!phoneLayout(context)) return 40;
    final view = View.of(context);
    final size = view.physicalSize / view.devicePixelRatio;
    final tablet = size.shortestSide >= 600 && size.width <= size.height;
    final fontSize = mobileSectionTitleFor(context);
    final textHeight = MediaQuery.textScalerOf(context).scale(fontSize) * 1.2;
    return textHeight.clamp(tablet ? 48.0 : 40.0, double.infinity);
  }

  static double pageHeaderGapFor(BuildContext context) => 16;
  static double actionHeightFor(BuildContext context) =>
      phoneLayout(context) ? 36 : 34;

  // Layout mode follows the available horizontal viewport. A desktop window
  // can have a short height because of its aspect ratio or display scaling;
  // using shortestSide would incorrectly switch a landscape window to the
  // phone layout.
  static bool isCompact(Size size) => size.width < compactBreakpoint;

  static bool usesCompactTypography(Size size) => isCompact(size);

  static double fluid(Size size, double small, double large) {
    final phone =
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        (size.shortestSide < 600 || _mobileLandscape);
    final width = phone ? size.shortestSide.clamp(0, 599) : size.width;
    final fraction = ((width - 600) / 500).clamp(0.0, 1.0);
    return small + (large - small) * fraction;
  }

  static double smartWorkBodyFontSizeFor(Size size) {
    return fontBodyFor(size);
  }

  static double smartWorkCaptionFontSizeFor(Size size) {
    return fontCaptionFor(size);
  }

  static bool get _mobileTypography =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _mobileLandscape {
    if (!_mobileTypography) return false;
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    return view != null && view.physicalSize.width > view.physicalSize.height;
  }

  static double fontMicroFor(Size size) {
    return _mobileTypography ? fluid(size, 11, 13) : 12;
  }

  static double fontCaptionFor(Size size) {
    return _mobileTypography ? 12 : EcjtuDesktopType.description;
  }

  static double fontSmallFor(Size size) {
    return _mobileTypography ? 14 : EcjtuDesktopType.description;
  }

  static double fontBodyFor(Size size) {
    return _mobileTypography ? 14 : EcjtuDesktopType.body;
  }

  static double fontLabelFor(Size size) {
    if ((defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        (size.shortestSide < 600 || _mobileLandscape)) {
      return 14;
    }
    return _mobileTypography ? fluid(size, 15, 17) : EcjtuDesktopType.body;
  }

  static double sectionTitleFor(Size size) {
    final phone =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return phone
        ? (size.shortestSide >= 600 ? 28 : 22)
        : EcjtuDesktopType.title;
  }

  static double headerHeightFor(Size size) =>
      fluid(size, compactHeaderHeight, fullHeaderHeight);

  static double navigationHeightFor(Size size) =>
      fluid(size, compactNavigationHeight, fullNavigationHeight);

  static double outerPaddingFor(Size size) {
    if (_mobileTypography || isCompact(size)) return 0;
    return size.width >= 1760 ? 44 : 28;
  }

  static double maxFrameWidthFor(Size size) {
    if (_mobileTypography || isCompact(size)) return size.width;
    if (size.width >= 1760) return 1680;
    if (size.width >= 1360) return 1500;
    return 1040;
  }

  static double headerHorizontalPaddingFor(Size size) {
    return fluid(size, 8, 38);
  }

  static double navigationHorizontalPaddingFor(Size size) {
    return fluid(size, 6, 28);
  }

  static PageColumn columnForContext(BuildContext context, Size size) {
    if (!phoneLayout(context)) return columnFor(size);
    final view = View.of(context);
    final device = view.physicalSize / view.devicePixelRatio;
    if (device.width > device.height) {
      return const PageColumn(
        horizontalPadding: 20,
        topPadding: 20,
        bottomPadding: 20,
        sectionSpacing: 18,
        landscape: true,
      );
    }
    return columnFor(device);
  }

  static PageColumn columnFor(Size size) {
    if ((defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        size.shortestSide < 600) {
      final landscape = size.width > size.height;
      final scale = (size.shortestSide / 360).clamp(.86, 1.35);
      final padding = ((landscape ? 16 : 20) * scale).clamp(16.0, 28.0);
      return PageColumn(
        horizontalPadding: padding,
        topPadding: 20,
        bottomPadding: landscape ? 10 : padding,
        sectionSpacing: landscape ? 10 : (18 * scale).clamp(14.0, 24.0),
        landscape: landscape,
      );
    }
    return PageColumn(
      horizontalPadding: _mobileTypography ? fluid(size, 20, 38) : 24,
      topPadding: 20,
      bottomPadding: _mobileTypography ? fluid(size, 30, 38) : 24,
      sectionSpacing: _mobileTypography ? fluid(size, 18, 24) : 16,
      landscape: !isCompact(size) || size.width > size.height,
    );
  }
}

class PageColumn {
  const PageColumn({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.sectionSpacing,
    required this.landscape,
  });

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double sectionSpacing;
  final bool landscape;
}

class EcjtuAnimation {
  const EcjtuAnimation._();

  static const content = Duration(milliseconds: 220);
  static const overlay = Duration(milliseconds: 180);
  static const smartWorkPage = Duration(milliseconds: 220);
  static const smartWorkLoginSuccess = Duration(milliseconds: 320);
  static const accountForward = Duration(milliseconds: 220);
  static const accountBack = Duration(milliseconds: 200);
  static const settingsBody = Duration(milliseconds: 140);
  static const dialog = Duration(milliseconds: 220);
  static const navigation = Duration(milliseconds: 180);
  static const curve = Cubic(0.25, 0.1, 0.25, 1);
  static const easeOut = Curves.easeOut;
  static const accountCurve = Cubic(0.2, 0.8, 0.2, 1);
}

class EcjtuTheme {
  const EcjtuTheme._();

  /// Sentinel passed as `fontFamily` to request the platform's own UI font.
  /// A literal `null` keeps meaning "the bundled Source Han Sans default", so
  /// the two cases need distinct signals.
  static const String platformFontSentinel = '\u0000platform';

  static String? _controlFontFamily = 'SourceHanSansCN';
  static List<String> _controlFontFallback = const ['Microsoft YaHei'];

  static TextStyle buttonTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _controlFontFamily,
      fontFamilyFallback: _controlFontFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData lightFor({String? fontFamily}) =>
      _buildTheme(Brightness.light, fontFamily: fontFamily);

  static ThemeData darkFor({String? fontFamily}) =>
      _buildTheme(Brightness.dark, fontFamily: fontFamily);

  /// Light theme using the host platform's own sans-serif (Android's system
  /// font, "系统黑体"). No bundled family and no fallback are declared so the
  /// engine resolves every glyph through the platform default.
  static ThemeData lightForPlatformFont() =>
      _buildTheme(Brightness.light, fontFamily: platformFontSentinel);

  static ThemeData darkForPlatformFont() =>
      _buildTheme(Brightness.dark, fontFamily: platformFontSentinel);

  static TextTheme responsiveTextTheme(TextTheme base, Size size) {
    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (mobile) {
      TextStyle? role(
        TextStyle? style,
        double size,
        double lineHeight,
        FontWeight weight,
      ) => style?.copyWith(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: 0,
      );
      return base.copyWith(
        titleLarge: role(base.titleLarge, 22, 28, FontWeight.w700),
        titleMedium: role(base.titleMedium, 16, 24, FontWeight.w500),
        titleSmall: role(base.titleSmall, 14, 20, FontWeight.w500),
        bodyLarge: role(base.bodyLarge, 16, 24, FontWeight.w400),
        bodyMedium: role(base.bodyMedium, 14, 20, FontWeight.w400),
        bodySmall: role(base.bodySmall, 12, 16, FontWeight.w400),
        labelLarge: role(base.labelLarge, 14, 20, FontWeight.w500),
        labelMedium: role(base.labelMedium, 12, 16, FontWeight.w500),
        labelSmall: role(base.labelSmall, 11, 16, FontWeight.w500),
      );
    }
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        fontSize: EcjtuMetrics.sectionTitleFor(size),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: EcjtuMetrics.fontLabelFor(size),
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: EcjtuMetrics.fontBodyFor(size),
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: EcjtuMetrics.fontSmallFor(size),
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: EcjtuMetrics.fontCaptionFor(size),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: EcjtuMetrics.fontLabelFor(size),
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: EcjtuMetrics.fontSmallFor(size),
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: EcjtuMetrics.fontCaptionFor(size),
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness, {String? fontFamily}) {
    final dark = brightness == Brightness.dark;
    final primary = dark ? EcjtuColors.darkPrimary : EcjtuColors.primary;
    final textPrimary = dark
        ? EcjtuColors.darkTextPrimary
        : EcjtuColors.textPrimary;
    final textSecondary = dark
        ? EcjtuColors.darkTextSecondary
        : EcjtuColors.textSecondary;
    final background = dark
        ? EcjtuColors.darkPageBackground
        : EcjtuColors.pageBackground;
    final surface = dark
        ? EcjtuColors.darkControlSurface
        : EcjtuColors.controlSurface;
    final border = dark ? EcjtuColors.darkBorder : EcjtuColors.border;
    // The platform-font sentinel means "declare no family at all" so the engine
    // resolves glyphs through the host system font (Android's 系统黑体).
    final platformFont = fontFamily == platformFontSentinel;
    fontFamily = platformFont ? null : (fontFamily ?? 'SourceHanSansCN');
    final fontFallback = platformFont
        ? const <String>[]
        : (fontFamily == 'SourceHanSansCN'
              ? const ['Microsoft YaHei']
              : const ['SourceHanSansCN']);
    _controlFontFamily = fontFamily;
    _controlFontFallback = fontFallback;

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surface,
        outline: border,
      ),
    );

    final textTheme = base.textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: textPrimary,
          decoration: TextDecoration.none,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: textSecondary,
          decoration: TextDecoration.none,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          decoration: TextDecoration.none,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          decoration: TextDecoration.none,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          decoration: TextDecoration.none,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontFamilyFallback: fontFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.18),
        selectionHandleColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.disabled))
            return dark ? const Color(0xFF101B2A) : const Color(0xFFF2F4F7);
          if (states.contains(WidgetState.focused))
            return dark ? const Color(0xFF18283D) : Colors.white;
          return dark ? const Color(0xFF152235) : const Color(0xFFF8FAFC);
        }),
        hoverColor: primary.withValues(alpha: 0.035),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.82)),
        hintFadeDuration: const Duration(milliseconds: 150),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF34475F) : const Color(0xFFD4DFE9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF629BC3) : const Color(0xFF5594BD),
            width: 1.25,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: base.colorScheme.error, width: 1.25),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shadowColor: dark
            ? const Color.fromRGBO(0, 0, 0, 0.42)
            : const Color.fromRGBO(17, 52, 78, 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
        barrierColor: dark
            ? const Color.fromRGBO(0, 0, 0, 0.6)
            : const Color.fromRGBO(8, 24, 40, 0.48),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        contentTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 15,
          height: 1.75,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      ),
    );
  }
}
