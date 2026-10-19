// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import '../../theme/ecjtu_control_palette.dart';
import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_glass.dart';

abstract interface class SettingsControlSize {
  double minimumWidth(BuildContext context);
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.detail,
    this.trailing,
    this.minHeight,
    this.nested = false,
    this.trailingMinWidth = 0,
  });

  final String title;
  final String? detail;
  final Widget? trailing;
  final double? minHeight;
  final bool nested;
  final double trailingMinWidth;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final desktop =
        !EcjtuMetrics.phoneLayout(context) &&
        Theme.of(context).extension<EcjtuDesktopColorStyle>() != null;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final available = constraints.maxWidth - 32;
        final minimum = trailing is SettingsControlSize
            ? (trailing as SettingsControlSize).minimumWidth(context)
            : trailingMinWidth;
        final titlePainter = TextPainter(
          text: TextSpan(
            text: title,
            style: TextStyle(
              fontSize: EcjtuMetrics.phoneLayout(context)
                  ? 14
                  : nested && !desktop
                  ? 14
                  : EcjtuMetrics.fontLabelFor(MediaQuery.sizeOf(context)),
              fontWeight: FontWeight.w700,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final stacked =
            trailing is! SettingsSwitch &&
            (constraints.maxWidth < 280 ||
                minimum > 0 && titlePainter.width + 12 + minimum > available);
        titlePainter.dispose();
        final copy = SettingsCopy(title: title, detail: detail, nested: nested);
        final control = trailing == null
            ? const SizedBox.shrink()
            : ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: stacked ? available : minimum.clamp(0, available),
                  maxWidth: stacked
                      ? constraints.maxWidth - 32
                      : compact
                      ? (available * .60).clamp(
                          minimum.clamp(0, available),
                          available,
                        )
                      : 360.0.clamp(minimum.clamp(0, available), available),
                ),
                child: Align(
                  widthFactor: 1,
                  alignment: stacked
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: trailing,
                ),
              );
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight ?? 0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              desktop ? 10 : 12,
              16,
              desktop ? 10 : 12,
            ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      if (trailing != null) ...[
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: control),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copy),
                      if (trailing != null) ...[
                        SizedBox(width: compact ? 12 : 18),
                        control,
                      ],
                    ],
                  ),
          ),
        );
      },
    );
    final row = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                EcjtuControlPalette.maybeOf(context)?.border ??
                (EcjtuColors.borderFrom(
                  context,
                  dark ? EcjtuColors.darkBorder : const Color(0xFFEAECF0),
                )),
          ),
        ),
      ),
      child: content,
    );
    return row;
  }
}

class SettingsCopy extends StatelessWidget {
  const SettingsCopy({
    super.key,
    required this.title,
    this.detail,
    this.titleColor,
    this.titleFontSize,
    this.titleWeight,
    this.nested = false,
  });

  final String title;
  final String? detail;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleWeight;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final desktop =
        !EcjtuMetrics.phoneLayout(context) &&
        Theme.of(context).extension<EcjtuDesktopColorStyle>() != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color:
                titleColor ??
                EcjtuControlPalette.maybeOf(context)?.foreground ??
                (EcjtuColors.textFrom(
                  context,
                  dark ? EcjtuColors.darkTextPrimary : const Color(0xFF475467),
                )),
            fontSize:
                titleFontSize ??
                (EcjtuMetrics.phoneLayout(context)
                    ? 14
                    : nested && !desktop
                    ? 14
                    : EcjtuMetrics.fontLabelFor(size)),
            fontWeight:
                titleWeight ??
                (nested
                    ? FontWeight.w500
                    : EcjtuMetrics.phoneLayout(context)
                    ? FontWeight.w600
                    : FontWeight.w700),
            height: 1.45,
          ),
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            detail!,
            style: TextStyle(
              color:
                  EcjtuControlPalette.maybeOf(context)?.muted ??
                  (EcjtuColors.mutedFor(context)),
              fontSize: nested && !desktop
                  ? 13
                  : EcjtuMetrics.fontCaptionFor(size),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                ? EcjtuControlPalette.maybeOf(context)?.activeTrack ??
                      (dark ? EcjtuColors.darkPrimary : EcjtuColors.primary)
                : EcjtuControlPalette.maybeOf(context)?.inactiveTrack ??
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
                color:
                    EcjtuControlPalette.maybeOf(context)?.thumb ?? Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
