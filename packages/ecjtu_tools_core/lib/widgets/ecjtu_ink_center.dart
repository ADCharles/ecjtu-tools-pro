// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Aligns packaged font outlines instead of the font's ascent/descent box.
class EcjtuInkCenter extends StatelessWidget {
  const EcjtuInkCenter({
    super.key,
    required this.text,
    required this.inkCenterEm,
  });

  final Text text;
  final double inkCenterEm;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(text.style);
    final scaler = text.textScaler ?? MediaQuery.textScalerOf(context);
    return _InkAlignment(
      baselineToInkCenter: scaler.scale(style.fontSize!) * inkCenterEm,
      child: text,
    );
  }
}

class _InkAlignment extends SingleChildRenderObjectWidget {
  const _InkAlignment({
    required this.baselineToInkCenter,
    required super.child,
  });
  final double baselineToInkCenter;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderInkAlignment(baselineToInkCenter);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderInkAlignment renderObject,
  ) {
    renderObject.baselineToInkCenter = baselineToInkCenter;
  }
}

class _RenderInkAlignment extends RenderShiftedBox {
  _RenderInkAlignment(this._baselineToInkCenter) : super(null);
  double _baselineToInkCenter;

  set baselineToInkCenter(double value) {
    if (_baselineToInkCenter == value) return;
    _baselineToInkCenter = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child!.getDryLayout(constraints);

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    size = child!.size;
    final baseline = child!.getDistanceToBaseline(TextBaseline.alphabetic)!;
    (child!.parentData! as BoxParentData).offset = Offset(
      0,
      size.height / 2 - baseline + _baselineToInkCenter,
    );
  }
}
