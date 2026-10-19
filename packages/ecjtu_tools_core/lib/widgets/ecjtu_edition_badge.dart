// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'ecjtu_ink_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit, PaintingBinding;

class EcjtuEditionBadge extends StatelessWidget {
  const EcjtuEditionBadge({
    super.key,
    required this.label,
    required this.fontSize,
    required this.padding,
    this.color = Colors.white,
    this.borderOpacity = .65,
    this.centered = false,
    this.compact = false,
  });

  final String label;
  final double fontSize;
  final EdgeInsets padding;
  final Color color;
  final double borderOpacity;
  final bool centered;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _buildBadge(context),
  );

  Widget _buildBadge(BuildContext context) {
    final style = TextStyle(
      inherit: !compact,
      color: color,
      fontSize: fontSize,
      fontFamily: 'SourceHanSansCN',
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      height: compact ? 1 : 1.2,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final heightBehavior = centered
        ? const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          )
        : null;
    final labelText = Text(
      label,
      maxLines: 1,
      softWrap: false,
      textHeightBehavior: heightBehavior,
      style: style,
    );
    final Widget text = centered
        ? EcjtuInkCenter(text: labelText, inkCenterEm: .3635)
        : labelText;
    return Transform.translate(
      offset: Offset.zero,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: color.withValues(alpha: borderOpacity)),
          ),
        ),
        child: Padding(
          padding: padding,
          child: SizedBox(
            height: centered
                ? (compact
                          ? MediaQuery.textScalerOf(context).scale(fontSize)
                          : fontSize) *
                      (compact ? 1.25 : 1.6)
                : null,
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              heightFactor: centered ? null : 1,
              child: compact
                  ? OverflowBox(
                      minHeight: 0,
                      maxHeight: double.infinity,
                      fit: OverflowBoxFit.deferToChild,
                      child: text,
                    )
                  : text,
            ),
          ),
        ),
      ),
    );
  }
}
