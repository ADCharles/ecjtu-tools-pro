// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import 'physics_electron_charge_models.dart';

class ElectronChargeChartGeometry {
  const ElectronChargeChartGeometry({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  static const width = 520.0;
  static const height = 320.0;
  static const left = 74.0;
  static const right = width - 22;
  static const top = 24.0;
  static const bottom = height - 56;

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  factory ElectronChargeChartGeometry.from(
    ElectronChargeDeflectionResult result,
  ) {
    final xs = result.fit.valid.map((point) => point.x!.toDouble()).toList();
    final ys = result.fit.valid.map((point) => point.y!.toDouble()).toList();
    var minX = xs.reduce(math.min);
    var maxX = xs.reduce(math.max);
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    final xPadding = math.max((maxX - minX) * 0.08, 1);
    final yPadding = math.max((maxY - minY) * 0.12, 1);
    minX -= xPadding;
    maxX += xPadding;
    minY -= yPadding;
    maxY += yPadding;
    return ElectronChargeChartGeometry(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  double x(double value) {
    return left +
        (value - minX) / (maxX - minX == 0 ? 1 : maxX - minX) * (right - left);
  }

  double y(double value) {
    return bottom -
        (value - minY) / (maxY - minY == 0 ? 1 : maxY - minY) * (bottom - top);
  }
}

class ElectronChargeTrendChart extends StatelessWidget {
  const ElectronChargeTrendChart({
    super.key,
    required this.result,
    required this.dark,
  });

  final ElectronChargeDeflectionResult result;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final border = dark ? const Color(0xFF31546B) : const Color(0xFFE1EBF1);
    final background = EcjtuColors.platformSurface(
      dark,
      (dark ? const Color(0xFF101D31) : Colors.white),
    );
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: ElectronChargeChartGeometry.width,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: result.hasChart
          ? AspectRatio(
              aspectRatio:
                  ElectronChargeChartGeometry.width /
                  ElectronChargeChartGeometry.height,
              child: CustomPaint(
                painter: _ElectronChargeChartPainter(
                  result: result,
                  dark: dark,
                  fontFamily: fontFamily,
                ),
              ),
            )
          : SizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(
                  '填写数据后显示散点和线性趋势线。',
                  style: TextStyle(
                    color: dark
                        ? EcjtuColors.darkTextSecondary
                        : const Color(0xFF667B8E),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ),
    );
  }
}

class _ElectronChargeChartPainter extends CustomPainter {
  const _ElectronChargeChartPainter({
    required this.result,
    required this.dark,
    required this.fontFamily,
  });

  final ElectronChargeDeflectionResult result;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = ElectronChargeChartGeometry.from(result);
    final sx = size.width / ElectronChargeChartGeometry.width;
    final sy = size.height / ElectronChargeChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final chartSize = const Size(
      ElectronChargeChartGeometry.width,
      ElectronChargeChartGeometry.height,
    );
    final background = Paint()
      ..color = EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : Colors.white),
      );
    canvas.drawRect(Offset.zero & chartSize, background);

    final grid = Paint()
      ..color = dark ? const Color(0xFF28465C) : const Color(0xFFE3EDF2)
      ..strokeWidth = 1;
    for (final fraction in const [0.0, 0.5, 1.0]) {
      final y =
          ElectronChargeChartGeometry.top +
          (ElectronChargeChartGeometry.bottom -
                  ElectronChargeChartGeometry.top) *
              fraction;
      canvas.drawLine(
        Offset(ElectronChargeChartGeometry.left, y),
        Offset(ElectronChargeChartGeometry.right, y),
        grid,
      );
      final x =
          ElectronChargeChartGeometry.left +
          (ElectronChargeChartGeometry.right -
                  ElectronChargeChartGeometry.left) *
              fraction;
      canvas.drawLine(
        Offset(x, ElectronChargeChartGeometry.top),
        Offset(x, ElectronChargeChartGeometry.bottom),
        grid,
      );
    }

    final axis = Paint()
      ..color = dark ? const Color(0xFF7E9CAF) : const Color(0xFF6D8798)
      ..strokeWidth = 1.3;
    canvas.drawLine(
      const Offset(
        ElectronChargeChartGeometry.left,
        ElectronChargeChartGeometry.bottom,
      ),
      const Offset(
        ElectronChargeChartGeometry.right,
        ElectronChargeChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        ElectronChargeChartGeometry.left,
        ElectronChargeChartGeometry.top,
      ),
      const Offset(
        ElectronChargeChartGeometry.left,
        ElectronChargeChartGeometry.bottom,
      ),
      axis,
    );

    final labelColor = dark ? const Color(0xFF9EACC3) : const Color(0xFF527087);
    final axisColor = dark ? const Color(0xFF9EACC3) : const Color(0xFF275B7A);
    final xLabel = result.definition.xSymbol == 'U_d' ? 'U_d / V' : 'I / mA';
    _drawXAxisLabel(
      canvas,
      xLabel,
      Offset(ElectronChargeChartGeometry.left, 287),
      axisColor,
      12,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      _plainText('D / mm'),
      const Offset(4, 18),
      axisColor,
      12,
      FontWeight.w700,
    );
    _drawText(
      canvas,
      _plainText(_axisNumber(geometry.minX)),
      Offset(geometry.x(geometry.minX), 283),
      labelColor,
      12,
      FontWeight.w600,
      centered: true,
    );
    _drawText(
      canvas,
      _plainText(_axisNumber(geometry.maxX)),
      Offset(geometry.x(geometry.maxX) - 4, 283),
      labelColor,
      12,
      FontWeight.w600,
      alignRight: true,
    );
    _drawText(
      canvas,
      _plainText(_axisNumber(geometry.minY)),
      Offset(
        ElectronChargeChartGeometry.left - 8,
        geometry.y(geometry.minY) + 4,
      ),
      labelColor,
      12,
      FontWeight.w600,
      alignRight: true,
    );
    _drawText(
      canvas,
      _plainText(_axisNumber(geometry.maxY)),
      Offset(
        ElectronChargeChartGeometry.left - 8,
        geometry.y(geometry.maxY) + 4,
      ),
      labelColor,
      12,
      FontWeight.w600,
      alignRight: true,
    );

    final line = Paint()
      ..color = dark ? const Color(0xFF70B7DE) : const Color(0xFF287AA8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final valid = result.fit.valid;
    if (valid.length > 1) {
      final path = Path();
      for (var index = 0; index < valid.length; index++) {
        final point = valid[index];
        final position = Offset(
          geometry.x(point.x!.toDouble()),
          geometry.y(point.y!.toDouble()),
        );
        if (index == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      canvas.drawPath(path, line);
    }

    if (result.fit.complete) {
      final slope = result.fit.slope!.toDouble();
      final intercept = result.fit.intercept!.toDouble();
      _drawDashedLine(
        canvas,
        Offset(
          geometry.x(geometry.minX),
          geometry.y(slope * geometry.minX + intercept),
        ),
        Offset(
          geometry.x(geometry.maxX),
          geometry.y(slope * geometry.maxX + intercept),
        ),
        line
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    final dot = Paint()
      ..color = dark ? const Color(0xFF70B7DE) : const Color(0xFF287AA8)
      ..style = PaintingStyle.fill;
    for (final point in valid) {
      canvas.drawCircle(
        Offset(
          geometry.x(point.x!.toDouble()),
          geometry.y(point.y!.toDouble()),
        ),
        4,
        dot,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ElectronChargeChartPainter oldDelegate) => true;

  TextSpan _plainText(String text) => TextSpan(text: text);

  String _axisNumber(double value) {
    if (!value.isFinite) return '-';
    return value.toStringAsPrecision(7);
  }

  void _drawXAxisLabel(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    if (text != 'U_d / V') {
      _drawText(canvas, _plainText(text), offset, color, fontSize, weight);
      return;
    }
    final mainStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: weight,
      fontFamily: fontFamily,
      height: 1,
    );
    final main = TextPainter(
      text: TextSpan(text: 'U', style: mainStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    main.paint(canvas, offset);
    final subscript = TextPainter(
      text: TextSpan(
        text: 'd',
        style: mainStyle.copyWith(fontSize: fontSize * .68),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final subscriptOffset = Offset(
      offset.dx + main.width,
      offset.dy + fontSize * .35,
    );
    subscript.paint(canvas, subscriptOffset);
    final suffix = TextPainter(
      text: TextSpan(text: ' / V', style: mainStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    suffix.paint(
      canvas,
      Offset(subscriptOffset.dx + subscript.width, offset.dy),
    );
  }

  void _drawText(
    Canvas canvas,
    TextSpan span,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight weight, {
    bool centered = false,
    bool alignRight = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: fontFamily,
          height: 1,
        ),
        children: [span],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var position = offset;
    if (centered) {
      position = offset.translate(-textPainter.width / 2, 0);
    } else if (alignRight) {
      position = offset.translate(-textPainter.width, 0);
    }
    textPainter.paint(canvas, position);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    const dashLength = 1.0;
    const gapLength = 4.0;
    var offset = 0.0;
    while (offset < distance) {
      final dashEnd = math.min(offset + dashLength, distance);
      canvas.drawLine(
        start + direction * offset,
        start + direction * dashEnd,
        paint,
      );
      offset += dashLength + gapLength;
    }
  }
}

class ElectronChargeChartSvg {
  const ElectronChargeChartSvg._();

  static String build(ElectronChargeDeflectionResult result) {
    final geometry = ElectronChargeChartGeometry.from(result);
    final buffer = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 320" width="520" height="320">',
      )
      ..writeln('<rect x="0" y="0" width="520" height="320" fill="#ffffff"/>');
    for (final fraction in const [0.0, 0.5, 1.0]) {
      final y =
          ElectronChargeChartGeometry.top +
          (ElectronChargeChartGeometry.bottom -
                  ElectronChargeChartGeometry.top) *
              fraction;
      final x =
          ElectronChargeChartGeometry.left +
          (ElectronChargeChartGeometry.right -
                  ElectronChargeChartGeometry.left) *
              fraction;
      buffer
        ..writeln(
          '<line x1="${_number(ElectronChargeChartGeometry.left)}" y1="${_number(y)}" x2="${_number(ElectronChargeChartGeometry.right)}" y2="${_number(y)}" stroke="#e3edf2" stroke-width="1"/>',
        )
        ..writeln(
          '<line x1="${_number(x)}" y1="${_number(ElectronChargeChartGeometry.top)}" x2="${_number(x)}" y2="${_number(ElectronChargeChartGeometry.bottom)}" stroke="#e3edf2" stroke-width="1"/>',
        );
    }
    buffer
      ..writeln(
        '<line x1="74" y1="264" x2="498" y2="264" stroke="#6d8798" stroke-width="1.3"/>',
      )
      ..writeln(
        '<line x1="74" y1="24" x2="74" y2="264" stroke="#6d8798" stroke-width="1.3"/>',
      )
      ..writeln(
        '<g fill="#527087" font-family="NotoSansSCPdf" font-size="12" font-weight="600">',
      )
      ..writeln(
        '<text x="${_number(geometry.x(geometry.minX))}" y="283" text-anchor="middle">${_xml(_axisNumber(geometry.minX))}</text>',
      )
      ..writeln(
        '<text x="${_number(geometry.x(geometry.maxX) - 4)}" y="283" text-anchor="end">${_xml(_axisNumber(geometry.maxX))}</text>',
      )
      ..writeln(
        '<text x="66" y="268" text-anchor="end">${_xml(_axisNumber(geometry.minY))}</text>',
      )
      ..writeln(
        '<text x="66" y="28" text-anchor="end">${_xml(_axisNumber(geometry.maxY))}</text>',
      )
      ..writeln('</g>')
      ..writeln(
        '<g fill="#275b7a" font-family="NotoSansSCPdf" font-size="12" font-weight="700">',
      )
      ..writeln(
        result.definition.xSymbol == 'U_d'
            ? '<text x="74" y="302">U</text><text x="82" y="306" font-size="8">d</text><text x="88" y="302"> / V</text>'
            : '<text x="74" y="302">I / mA</text>',
      )
      ..writeln('<text x="4" y="18">D / mm</text>')
      ..writeln('</g>');

    final valid = result.fit.valid;
    if (valid.length > 1) {
      final points = valid
          .map(
            (point) =>
                '${_number(geometry.x(point.x!.toDouble()))},${_number(geometry.y(point.y!.toDouble()))}',
          )
          .join(' ');
      buffer.writeln(
        '<polyline points="$points" fill="none" stroke="#287aa8" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    if (result.fit.complete) {
      final slope = result.fit.slope!.toDouble();
      final intercept = result.fit.intercept!.toDouble();
      buffer.writeln(
        '<line x1="${_number(geometry.x(geometry.minX))}" y1="${_number(geometry.y(slope * geometry.minX + intercept))}" x2="${_number(geometry.x(geometry.maxX))}" y2="${_number(geometry.y(slope * geometry.maxX + intercept))}" fill="none" stroke="#287aa8" stroke-width="1.5" stroke-dasharray="1 4" stroke-linecap="round"/>',
      );
    }
    for (final point in valid) {
      buffer.writeln(
        '<circle cx="${_number(geometry.x(point.x!.toDouble()))}" cy="${_number(geometry.y(point.y!.toDouble()))}" r="4" fill="#287aa8"/>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _axisNumber(double value) {
    if (!value.isFinite) return '-';
    return value.toStringAsPrecision(7);
  }

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
