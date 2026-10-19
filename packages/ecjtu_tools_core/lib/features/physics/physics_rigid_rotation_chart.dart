// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../theme/ecjtu_theme.dart';
import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import 'physics_rigid_rotation_calculator.dart';
import 'physics_rigid_rotation_models.dart';

class RigidRotationChartSpec {
  const RigidRotationChartSpec({
    required this.title,
    required this.seriesName,
    required this.xLabel,
    required this.yLabel,
    required this.points,
  });

  final String title;
  final String seriesName;
  final String xLabel;
  final String yLabel;
  final List<RigidRotationChartPoint> points;

  bool get hasData => points.isNotEmpty;
}

class RigidRotationChartPoint {
  const RigidRotationChartPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class RigidRotationChartGeometry {
  const RigidRotationChartGeometry._();

  static const width = 760.0;
  static const height = 420.0;
  static const left = 76.0;
  static const right = 718.0;
  static const top = 42.0;
  static const bottom = 330.0;
}

class RigidRotationChartCard extends StatelessWidget {
  const RigidRotationChartCard({
    super.key,
    required this.spec,
    required this.dark,
    required this.onExport,
  });

  final RigidRotationChartSpec spec;
  final bool dark;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.title, style: _rigidChartTitleStyle(dark)),
          const SizedBox(height: 9),
          if (spec.hasData)
            AspectRatio(
              aspectRatio:
                  RigidRotationChartGeometry.width /
                  RigidRotationChartGeometry.height,
              child: CustomPaint(
                painter: RigidRotationChartPainter(
                  spec: spec,
                  dark: dark,
                  fontFamily: fontFamily,
                ),
              ),
            )
          else
            SizedBox(
              height: 96,
              child: Center(
                child: Text(
                  '填写完整数据后显示图形。',
                  style: TextStyle(
                    color: EcjtuColors.platformMuted(
                      dark,
                      (dark
                          ? const Color(0xFF9EACC3)
                          : const Color(0xFF667B8E)),
                    ),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          if (spec.hasData) ...[
            const SizedBox(height: 7),
            OutlinedButton(
              onPressed: onExport,
              child: const Text('下载此图 PDF'),
              style: physicsSecondaryButtonStyle(context),
            ),
          ],
        ],
      ),
    );
  }
}

class RigidRotationChartPainter extends CustomPainter {
  const RigidRotationChartPainter({
    required this.spec,
    required this.dark,
    required this.fontFamily,
  });

  final RigidRotationChartSpec spec;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / RigidRotationChartGeometry.width;
    final sy = size.height / RigidRotationChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final bounds = RigidRotationChartBounds.from(spec.points);
    const chartSize = Size(
      RigidRotationChartGeometry.width,
      RigidRotationChartGeometry.height,
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
    for (var index = 0; index <= 4; index++) {
      final horizontal =
          RigidRotationChartGeometry.top +
          index /
              4 *
              (RigidRotationChartGeometry.bottom -
                  RigidRotationChartGeometry.top);
      final vertical =
          RigidRotationChartGeometry.left +
          index /
              4 *
              (RigidRotationChartGeometry.right -
                  RigidRotationChartGeometry.left);
      canvas.drawLine(
        Offset(vertical, RigidRotationChartGeometry.top),
        Offset(vertical, RigidRotationChartGeometry.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(RigidRotationChartGeometry.left, horizontal),
        Offset(RigidRotationChartGeometry.right, horizontal),
        grid,
      );
      _drawText(
        canvas,
        _axisNumber(bounds.minX + index / 4 * (bounds.maxX - bounds.minX)),
        Offset(vertical, RigidRotationChartGeometry.bottom + 22),
        EcjtuColors.platformMuted(
          dark,
          (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
        ),
        11,
        FontWeight.w400,
        centered: true,
      );
      _drawText(
        canvas,
        _axisNumber(bounds.maxY - index / 4 * (bounds.maxY - bounds.minY)),
        Offset(RigidRotationChartGeometry.left - 12, horizontal + 4),
        EcjtuColors.platformMuted(
          dark,
          (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
        ),
        11,
        FontWeight.w400,
        alignRight: true,
      );
    }

    final axis = Paint()
      ..color = dark ? const Color(0xFF7E9CAF) : const Color(0xFF6D8798)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      const Offset(
        RigidRotationChartGeometry.left,
        RigidRotationChartGeometry.top,
      ),
      const Offset(
        RigidRotationChartGeometry.left,
        RigidRotationChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        RigidRotationChartGeometry.left,
        RigidRotationChartGeometry.bottom,
      ),
      const Offset(
        RigidRotationChartGeometry.right,
        RigidRotationChartGeometry.bottom,
      ),
      axis,
    );

    const color = Color(0xFF287AA8);
    double x(double value) =>
        RigidRotationChartGeometry.left +
        (value - bounds.minX) /
            (bounds.maxX - bounds.minX) *
            (RigidRotationChartGeometry.right -
                RigidRotationChartGeometry.left);
    double y(double value) =>
        RigidRotationChartGeometry.bottom -
        (value - bounds.minY) /
            (bounds.maxY - bounds.minY) *
            (RigidRotationChartGeometry.bottom -
                RigidRotationChartGeometry.top);
    if (spec.points.length > 1) {
      final path = Path();
      for (var index = 0; index < spec.points.length; index++) {
        final point = spec.points[index];
        final position = Offset(x(point.x), y(point.y));
        if (index == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final point in spec.points) {
      final position = Offset(x(point.x), y(point.y));
      canvas.drawCircle(position, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        position,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawLine(
      const Offset(RigidRotationChartGeometry.left, 18),
      const Offset(RigidRotationChartGeometry.left + 18, 18),
      Paint()
        ..color = color
        ..strokeWidth = 2.1,
    );
    _drawText(
      canvas,
      spec.seriesName,
      const Offset(RigidRotationChartGeometry.left + 24, 22),
      EcjtuColors.platformMuted(
        dark,
        (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
      ),
      11,
      FontWeight.w400,
    );
    _drawText(
      canvas,
      spec.xLabel,
      const Offset(
        (RigidRotationChartGeometry.left + RigidRotationChartGeometry.right) /
            2,
        RigidRotationChartGeometry.height - 28,
      ),
      dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
      12,
      FontWeight.w600,
      centered: true,
    );
    _drawRotatedText(
      canvas,
      spec.yLabel,
      const Offset(
        22,
        (RigidRotationChartGeometry.top + RigidRotationChartGeometry.bottom) /
            2,
      ),
      dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
      12,
      FontWeight.w600,
    );
    canvas.restore();
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

  void _drawRotatedText(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(-math.pi / 2);
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
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  static String _axisNumber(double value) =>
      RigidRotationCalculator.formatDouble(value, digits: 4);

  @override
  bool shouldRepaint(covariant RigidRotationChartPainter oldDelegate) => true;
}

class RigidRotationChartBounds {
  const RigidRotationChartBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  factory RigidRotationChartBounds.from(List<RigidRotationChartPoint> points) {
    final minX = points.map((point) => point.x).reduce(math.min).toDouble();
    final maxX = points.map((point) => point.x).reduce(math.max).toDouble();
    final minY = points.map((point) => point.y).reduce(math.min).toDouble();
    final maxY = points.map((point) => point.y).reduce(math.max).toDouble();
    final xSpan = maxX == minX
        ? math.max(maxX.abs() * .2, 1).toDouble()
        : (maxX - minX) * 1.15;
    final ySpan = maxY == minY
        ? math.max(maxY.abs() * .2, 1).toDouble()
        : (maxY - minY) * 1.15;
    final xPadding = (xSpan - (maxX - minX)) / 2;
    final yPadding = (ySpan - (maxY - minY)) / 2;
    return RigidRotationChartBounds(
      minX: minX - xPadding,
      maxX: maxX + xPadding,
      minY: minY - yPadding,
      maxY: maxY + yPadding,
    );
  }
}

List<RigidRotationChartSpec> rigidRotationChartSpecs(
  RigidRotationCalculation calculation,
) {
  return [
    RigidRotationChartSpec(
      title: '总质量-倒数时间平方',
      seriesName: 'sumM-1/t2',
      xLabel: '1/t^2 / s^-2',
      yLabel: 'sumM / kg',
      points: calculation.massRuns
          .where((run) => run.mass != null && run.run.inverseSquare != null)
          .map(
            (run) => RigidRotationChartPoint(
              x: run.run.inverseSquare!,
              y: run.mass!,
            ),
          )
          .toList(growable: false),
    ),
    RigidRotationChartSpec(
      title: '半径-倒数时间',
      seriesName: 'r-1/t',
      xLabel: '1/t / s^-1',
      yLabel: 'r / m',
      points: calculation.secondRuns
          .where((run) => run.radius != null && run.run.inverseTime != null)
          .map(
            (run) => RigidRotationChartPoint(
              x: run.run.inverseTime!,
              y: run.radius!,
            ),
          )
          .toList(growable: false),
    ),
  ];
}

class RigidRotationChartSvg {
  const RigidRotationChartSvg._();

  static String build(RigidRotationChartSpec spec) {
    if (!spec.hasData) throw StateError('当前图表没有可下载的数据。');
    final bounds = RigidRotationChartBounds.from(spec.points);
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 420" width="760" height="420">',
    )..write('<rect x="0" y="0" width="760" height="420" fill="#FFFFFF"/>');
    for (var index = 0; index <= 4; index++) {
      final vertical =
          RigidRotationChartGeometry.left +
          index /
              4 *
              (RigidRotationChartGeometry.right -
                  RigidRotationChartGeometry.left);
      final horizontal =
          RigidRotationChartGeometry.top +
          index /
              4 *
              (RigidRotationChartGeometry.bottom -
                  RigidRotationChartGeometry.top);
      buffer
        ..write(
          '<line x1="${_number(vertical)}" y1="42" x2="${_number(vertical)}" y2="330" stroke="#E3EDF2" stroke-width="1"/>',
        )
        ..write(
          '<line x1="76" y1="${_number(horizontal)}" x2="718" y2="${_number(horizontal)}" stroke="#E3EDF2" stroke-width="1"/>',
        )
        ..write(
          '<text x="${_number(vertical)}" y="352" text-anchor="middle" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(_axisNumber(bounds.minX + index / 4 * (bounds.maxX - bounds.minX)))}</text>',
        )
        ..write(
          '<text x="64" y="${_number(horizontal + 4)}" text-anchor="end" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(_axisNumber(bounds.maxY - index / 4 * (bounds.maxY - bounds.minY)))}</text>',
        );
    }
    buffer
      ..write(
        '<line x1="76" y1="42" x2="76" y2="330" stroke="#6D8798" stroke-width="1.4"/>',
      )
      ..write(
        '<line x1="76" y1="330" x2="718" y2="330" stroke="#6D8798" stroke-width="1.4"/>',
      )
      ..write(
        '<g fill="#527087" font-family="NotoSansSCPdf" font-size="12" font-weight="600">',
      )
      ..write(
        '<text x="397" y="392" text-anchor="middle">${_xml(spec.xLabel)}</text>',
      )
      ..write(
        '<text x="22" y="190" text-anchor="middle" transform="rotate(-90 22 190)">${_xml(spec.yLabel)}</text>',
      )
      ..write('</g>')
      ..write(
        '<line x1="76" y1="18" x2="94" y2="18" stroke="#287AA8" stroke-width="2.1"/>',
      )
      ..write(
        '<text x="100" y="22" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(spec.seriesName)}</text>',
      );
    double x(double value) =>
        RigidRotationChartGeometry.left +
        (value - bounds.minX) /
            (bounds.maxX - bounds.minX) *
            (RigidRotationChartGeometry.right -
                RigidRotationChartGeometry.left);
    double y(double value) =>
        RigidRotationChartGeometry.bottom -
        (value - bounds.minY) /
            (bounds.maxY - bounds.minY) *
            (RigidRotationChartGeometry.bottom -
                RigidRotationChartGeometry.top);
    if (spec.points.length > 1) {
      buffer.write(
        '<polyline points="${spec.points.map((point) => '${_number(x(point.x))},${_number(y(point.y))}').join(' ')}" fill="none" stroke="#287AA8" stroke-width="2.1" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (final point in spec.points) {
      buffer.write(
        '<circle cx="${_number(x(point.x))}" cy="${_number(y(point.y))}" r="4" fill="#FFFFFF" stroke="#287AA8" stroke-width="1.8"/>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _axisNumber(double value) =>
      RigidRotationCalculator.formatDouble(value, digits: 4);

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

TextStyle _rigidChartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
