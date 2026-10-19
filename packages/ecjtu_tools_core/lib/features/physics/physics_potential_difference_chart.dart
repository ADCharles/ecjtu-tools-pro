// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../theme/ecjtu_theme.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'physics_potential_difference_calculator.dart';
import 'physics_potential_difference_models.dart';

const potentialDifferenceChartColor = Color(0xFF287AA8);
const potentialDifferenceChartColorHex = '#287AA8';

class PotentialDifferenceChartPoint {
  const PotentialDifferenceChartPoint({
    required this.standard,
    required this.delta,
  });

  final double standard;
  final double delta;
}

class PotentialDifferenceChartGeometry {
  const PotentialDifferenceChartGeometry({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  static const width = 900.0;
  static const height = 500.0;
  static const left = 104.0;
  static const right = width - 42;
  static const top = 42.0;
  static const bottom = height - 86;

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  factory PotentialDifferenceChartGeometry.from(
    List<PotentialDifferenceChartPoint> points,
  ) {
    final xs = points.map((point) => point.standard).toList(growable: false);
    final ys = points.map((point) => point.delta).toList(growable: false);
    final rawMinX = xs.reduce(math.min);
    final rawMaxX = xs.reduce(math.max);
    final rawMinY = math.min(0, ys.reduce(math.min));
    final rawMaxY = math.max(0, ys.reduce(math.max));
    final xPadding = math.max((rawMaxX - rawMinX) * .08, .5);
    final yPadding = math.max((rawMaxY - rawMinY) * .16, .001);
    return PotentialDifferenceChartGeometry(
      minX: rawMinX - xPadding,
      maxX: rawMaxX + xPadding,
      minY: rawMinY - yPadding,
      maxY: rawMaxY + yPadding,
    );
  }

  double x(double value) {
    final span = maxX - minX;
    return left + (value - minX) / (span == 0 ? 1 : span) * (right - left);
  }

  double y(double value) {
    final span = maxY - minY;
    return bottom - (value - minY) / (span == 0 ? 1 : span) * (bottom - top);
  }
}

class PotentialDifferenceChartCard extends StatelessWidget {
  const PotentialDifferenceChartCard({
    super.key,
    required this.points,
    required this.dark,
  });

  final List<PotentialDifferenceChartPoint> points;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final border = EcjtuColors.platformBorder(
      dark,
      (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
    );
    final surface = EcjtuColors.platformSurface(
      dark,
      (dark ? const Color(0xFF101D31) : Colors.white),
    );
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio:
            PotentialDifferenceChartGeometry.width /
            PotentialDifferenceChartGeometry.height,
        child: CustomPaint(
          painter: _PotentialDifferenceChartPainter(
            points: points,
            dark: dark,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}

class _PotentialDifferenceChartPainter extends CustomPainter {
  const _PotentialDifferenceChartPainter({
    required this.points,
    required this.dark,
    required this.fontFamily,
  });

  final List<PotentialDifferenceChartPoint> points;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = PotentialDifferenceChartGeometry.from(points);
    final scaleX = size.width / PotentialDifferenceChartGeometry.width;
    final scaleY = size.height / PotentialDifferenceChartGeometry.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    const chartSize = Size(
      PotentialDifferenceChartGeometry.width,
      PotentialDifferenceChartGeometry.height,
    );
    canvas.drawRect(
      Offset.zero & chartSize,
      Paint()
        ..color = EcjtuColors.platformSurface(
          dark,
          (dark ? const Color(0xFF101D31) : Colors.white),
        ),
    );

    final grid = Paint()
      ..color = dark ? const Color(0xFF28465C) : const Color(0xFFE3EDF2)
      ..strokeWidth = 1;
    for (final fraction in const [0.0, .25, .5, .75, 1.0]) {
      final y =
          PotentialDifferenceChartGeometry.top +
          (PotentialDifferenceChartGeometry.bottom -
                  PotentialDifferenceChartGeometry.top) *
              fraction;
      canvas.drawLine(
        Offset(PotentialDifferenceChartGeometry.left, y),
        Offset(PotentialDifferenceChartGeometry.right, y),
        grid,
      );
      final x =
          PotentialDifferenceChartGeometry.left +
          (PotentialDifferenceChartGeometry.right -
                  PotentialDifferenceChartGeometry.left) *
              fraction;
      canvas.drawLine(
        Offset(x, PotentialDifferenceChartGeometry.top),
        Offset(x, PotentialDifferenceChartGeometry.bottom),
        grid,
      );
    }

    final axis = Paint()
      ..color = dark ? const Color(0xFF7E9CAF) : const Color(0xFF6D8798)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      const Offset(
        PotentialDifferenceChartGeometry.left,
        PotentialDifferenceChartGeometry.top,
      ),
      const Offset(
        PotentialDifferenceChartGeometry.left,
        PotentialDifferenceChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        PotentialDifferenceChartGeometry.left,
        PotentialDifferenceChartGeometry.bottom,
      ),
      const Offset(
        PotentialDifferenceChartGeometry.right,
        PotentialDifferenceChartGeometry.bottom,
      ),
      axis,
    );

    final line = Paint()
      ..color = potentialDifferenceChartColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final position = Offset(
          geometry.x(point.standard),
          geometry.y(point.delta),
        );
        if (index == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      canvas.drawPath(path, line);
    }

    final dot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotOutline = Paint()
      ..color = potentialDifferenceChartColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final position = Offset(
        geometry.x(point.standard),
        geometry.y(point.delta),
      );
      canvas.drawCircle(position, 4, dot);
      canvas.drawCircle(position, 4, dotOutline);
      final offset = index.isOdd ? 22.0 : -14.0;
      final labelY = math.max(
        PotentialDifferenceChartGeometry.top + 12,
        math.min(
          PotentialDifferenceChartGeometry.bottom - 8,
          position.dy + offset,
        ),
      );
      _drawText(
        canvas,
        PotentialDifferenceCalculator.format(point.delta, digits: 8),
        Offset(position.dx, labelY),
        dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
        11,
        FontWeight.w700,
        centered: true,
      );
    }

    final labelColor = EcjtuColors.platformMuted(
      dark,
      (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
    );
    final axisLabelColor = dark
        ? const Color(0xFF9EACC3)
        : const Color(0xFF527087);
    for (final fraction in const [0.0, .25, .5, .75, 1.0]) {
      final x =
          PotentialDifferenceChartGeometry.left +
          (PotentialDifferenceChartGeometry.right -
                  PotentialDifferenceChartGeometry.left) *
              fraction;
      final value = geometry.minX + (geometry.maxX - geometry.minX) * fraction;
      _drawText(
        canvas,
        PotentialDifferenceCalculator.format(value, digits: 6),
        Offset(x, PotentialDifferenceChartGeometry.bottom + 20),
        labelColor,
        11,
        FontWeight.w400,
        centered: true,
      );
      final y =
          PotentialDifferenceChartGeometry.top +
          (PotentialDifferenceChartGeometry.bottom -
                  PotentialDifferenceChartGeometry.top) *
              fraction;
      final yValue = geometry.maxY - (geometry.maxY - geometry.minY) * fraction;
      _drawText(
        canvas,
        PotentialDifferenceCalculator.format(yValue, digits: 6),
        Offset(PotentialDifferenceChartGeometry.left - 10, y + 4),
        labelColor,
        11,
        FontWeight.w400,
        alignRight: true,
      );
    }
    _drawText(
      canvas,
      'Iₛ / mA',
      Offset(
        (PotentialDifferenceChartGeometry.left +
                PotentialDifferenceChartGeometry.right) /
            2,
        PotentialDifferenceChartGeometry.height - 28,
      ),
      axisLabelColor,
      12,
      FontWeight.w600,
      centered: true,
    );
    canvas.save();
    canvas.translate(
      24,
      (PotentialDifferenceChartGeometry.top +
              PotentialDifferenceChartGeometry.bottom) /
          2,
    );
    canvas.rotate(-math.pi / 2);
    _drawText(
      canvas,
      'ΔIₓ / mA',
      Offset.zero,
      axisLabelColor,
      12,
      FontWeight.w600,
      centered: true,
    );
    canvas.restore();
    _drawText(
      canvas,
      _timestamp(DateTime.now()),
      const Offset(PotentialDifferenceChartGeometry.width - 18, 22),
      dark ? const Color(0xFF9EACC3) : const Color(0xFF6B7F8E),
      11,
      FontWeight.w400,
      alignRight: true,
    );
    canvas.restore();
  }

  static String _timestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '生成时间 ${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  void _drawText(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight weight, {
    bool centered = false,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: fontFamily,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final position = centered
        ? offset.translate(-painter.width / 2, 0)
        : alignRight
        ? offset.translate(-painter.width, 0)
        : offset;
    painter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PotentialDifferenceChartPainter oldDelegate) =>
      true;
}

class PotentialDifferenceChartSvg {
  const PotentialDifferenceChartSvg._();

  static String build(List<PotentialDifferenceChartPoint> points) {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final geometry = PotentialDifferenceChartGeometry.from(points);
    final buffer = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 900 500" width="900" height="500">',
      )
      ..writeln('<rect x="0" y="0" width="900" height="500" fill="#FFFFFF"/>')
      ..writeln(
        '<line x1="104" y1="42" x2="104" y2="414" stroke="#6D8798" stroke-width="1.3"/>',
      )
      ..writeln(
        '<line x1="104" y1="414" x2="858" y2="414" stroke="#6D8798" stroke-width="1.3"/>',
      )
      ..writeln('<g stroke="#E3EDF2" stroke-width="1">');
    for (final fraction in const [0.0, .25, .5, .75, 1.0]) {
      final y =
          PotentialDifferenceChartGeometry.top +
          (PotentialDifferenceChartGeometry.bottom -
                  PotentialDifferenceChartGeometry.top) *
              fraction;
      final x =
          PotentialDifferenceChartGeometry.left +
          (PotentialDifferenceChartGeometry.right -
                  PotentialDifferenceChartGeometry.left) *
              fraction;
      buffer
        ..writeln(
          '<line x1="104" y1="${_number(y)}" x2="858" y2="${_number(y)}"/>',
        )
        ..writeln(
          '<line x1="${_number(x)}" y1="42" x2="${_number(x)}" y2="414"/>',
        );
    }
    buffer.writeln('</g>');
    buffer.writeln(
      '<g fill="#667B8E" font-family="NotoSansSCPdf" font-size="11" font-weight="400">',
    );
    for (final fraction in const [0.0, .25, .5, .75, 1.0]) {
      final x =
          PotentialDifferenceChartGeometry.left +
          (PotentialDifferenceChartGeometry.right -
                  PotentialDifferenceChartGeometry.left) *
              fraction;
      final y =
          PotentialDifferenceChartGeometry.top +
          (PotentialDifferenceChartGeometry.bottom -
                  PotentialDifferenceChartGeometry.top) *
              fraction;
      final xValue = geometry.minX + (geometry.maxX - geometry.minX) * fraction;
      final yValue = geometry.maxY - (geometry.maxY - geometry.minY) * fraction;
      buffer
        ..writeln(
          '<text x="${_number(x)}" y="434" text-anchor="middle">${_xml(PotentialDifferenceCalculator.format(xValue, digits: 6))}</text>',
        )
        ..writeln(
          '<text x="94" y="${_number(y + 4)}" text-anchor="end">${_xml(PotentialDifferenceCalculator.format(yValue, digits: 6))}</text>',
        );
    }
    buffer
      ..writeln('</g>')
      ..writeln(
        '<g fill="#275B7A" font-family="NotoSansSCPdf" font-size="12" font-weight="700">',
      )
      ..writeln(
        '<text x="481" y="472" text-anchor="middle" font-weight="600">Iₛ / mA</text>',
      )
      ..writeln(
        '<text x="24" y="228" text-anchor="middle" font-weight="600" transform="rotate(-90 24 228)">ΔIₓ / mA</text>',
      )
      ..writeln('</g>');
    if (points.length > 1) {
      final pointsText = points
          .map(
            (point) =>
                '${_number(geometry.x(point.standard))},${_number(geometry.y(point.delta))}',
          )
          .join(' ');
      buffer.writeln(
        '<polyline points="$pointsText" fill="none" stroke="$potentialDifferenceChartColorHex" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = geometry.x(point.standard);
      final y = geometry.y(point.delta);
      buffer
        ..writeln(
          '<circle cx="${_number(x)}" cy="${_number(y)}" r="4" fill="#FFFFFF" stroke="$potentialDifferenceChartColorHex" stroke-width="2"/>',
        )
        ..writeln(
          '<text x="${_number(x)}" y="${_number(math.max(54, math.min(406, y + (index.isOdd ? 22 : -14))))}" text-anchor="middle" fill="#176496" font-family="NotoSansSCPdf" font-size="11" font-weight="700">${_xml(PotentialDifferenceCalculator.format(point.delta, digits: 8))}</text>',
        );
    }
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

List<PotentialDifferenceChartPoint> potentialDifferenceChartPoints(
  PotentialDifferenceCalculation calculation,
) {
  return calculation.rows
      .where((row) => !row.invalid && row.standard != null && row.delta != null)
      .map(
        (row) => PotentialDifferenceChartPoint(
          standard: row.standard!,
          delta: row.delta!,
        ),
      )
      .toList(growable: false);
}
