// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../theme/ecjtu_theme.dart';
import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import 'physics_franck_hertz_calculator.dart';
import 'physics_franck_hertz_models.dart';

class FranckHertzChartSpec {
  const FranckHertzChartSpec({required this.title, required this.points});

  final String title;
  final List<FranckHertzChartPoint> points;

  bool get hasData => points.isNotEmpty;
}

class FranckHertzChartPoint {
  const FranckHertzChartPoint({required this.voltage, required this.current});

  final double voltage;
  final double current;
}

class FranckHertzChartGeometry {
  const FranckHertzChartGeometry._();

  static const width = 760.0;
  static const height = 420.0;
  static const left = 76.0;
  static const right = 718.0;
  static const top = 42.0;
  static const bottom = 330.0;
}

class FranckHertzChartCard extends StatelessWidget {
  const FranckHertzChartCard({
    super.key,
    required this.spec,
    required this.dark,
    required this.onExport,
  });

  final FranckHertzChartSpec spec;
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
          Text(spec.title, style: _franckChartTitleStyle(dark)),
          const SizedBox(height: 9),
          if (spec.hasData)
            AspectRatio(
              aspectRatio:
                  FranckHertzChartGeometry.width /
                  FranckHertzChartGeometry.height,
              child: CustomPaint(
                painter: FranckHertzChartPainter(
                  points: spec.points,
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

class FranckHertzChartPainter extends CustomPainter {
  const FranckHertzChartPainter({
    required this.points,
    required this.dark,
    required this.fontFamily,
  });

  final List<FranckHertzChartPoint> points;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / FranckHertzChartGeometry.width;
    final sy = size.height / FranckHertzChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final bounds = FranckHertzChartBounds.from(points);
    canvas.drawRect(
      Offset.zero &
          const Size(
            FranckHertzChartGeometry.width,
            FranckHertzChartGeometry.height,
          ),
      Paint()
        ..color = EcjtuColors.platformSurface(
          dark,
          (dark ? const Color(0xFF101D31) : Colors.white),
        ),
    );
    double x(double value) =>
        FranckHertzChartGeometry.left +
        (value - bounds.minVoltage) /
            (bounds.maxVoltage - bounds.minVoltage) *
            (FranckHertzChartGeometry.right - FranckHertzChartGeometry.left);
    double y(double value) =>
        FranckHertzChartGeometry.bottom -
        (value - bounds.minCurrent) /
            (bounds.maxCurrent - bounds.minCurrent) *
            (FranckHertzChartGeometry.bottom - FranckHertzChartGeometry.top);

    final grid = Paint()
      ..color = dark ? const Color(0xFF28465C) : const Color(0xFFE3EDF2)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final horizontal =
          FranckHertzChartGeometry.top +
          index /
              4 *
              (FranckHertzChartGeometry.bottom - FranckHertzChartGeometry.top);
      final vertical =
          FranckHertzChartGeometry.left +
          index /
              4 *
              (FranckHertzChartGeometry.right - FranckHertzChartGeometry.left);
      canvas.drawLine(
        Offset(vertical, FranckHertzChartGeometry.top),
        Offset(vertical, FranckHertzChartGeometry.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(FranckHertzChartGeometry.left, horizontal),
        Offset(FranckHertzChartGeometry.right, horizontal),
        grid,
      );
      _drawText(
        canvas,
        _axisNumber(
          bounds.minVoltage +
              index / 4 * (bounds.maxVoltage - bounds.minVoltage),
        ),
        Offset(vertical, FranckHertzChartGeometry.bottom + 22),
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
        _axisNumber(
          bounds.maxCurrent -
              index / 4 * (bounds.maxCurrent - bounds.minCurrent),
        ),
        Offset(FranckHertzChartGeometry.left - 12, horizontal + 4),
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
      const Offset(FranckHertzChartGeometry.left, FranckHertzChartGeometry.top),
      const Offset(
        FranckHertzChartGeometry.left,
        FranckHertzChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        FranckHertzChartGeometry.left,
        FranckHertzChartGeometry.bottom,
      ),
      const Offset(
        FranckHertzChartGeometry.right,
        FranckHertzChartGeometry.bottom,
      ),
      axis,
    );

    if (points.length > 1) {
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final position = Offset(x(point.voltage), y(point.current));
        if (index == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF287AA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final point in points) {
      final position = Offset(x(point.voltage), y(point.current));
      canvas.drawCircle(position, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        position,
        4,
        Paint()
          ..color = const Color(0xFF287AA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawLine(
      const Offset(FranckHertzChartGeometry.left, 18),
      const Offset(FranckHertzChartGeometry.left + 18, 18),
      Paint()
        ..color = const Color(0xFF287AA8)
        ..strokeWidth = 2.1,
    );
    _drawText(
      canvas,
      'IA',
      const Offset(FranckHertzChartGeometry.left + 24, 22),
      EcjtuColors.platformMuted(
        dark,
        (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
      ),
      11,
      FontWeight.w400,
    );
    _drawText(
      canvas,
      'UG2K / V',
      Offset(
        (FranckHertzChartGeometry.left + FranckHertzChartGeometry.right) / 2,
        FranckHertzChartGeometry.height - 28,
      ),
      dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
      12,
      FontWeight.w600,
      centered: true,
    );
    _drawRotatedText(
      canvas,
      'IA',
      Offset(
        22,
        (FranckHertzChartGeometry.top + FranckHertzChartGeometry.bottom) / 2,
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
      FranckHertzCalculator.formatDouble(value, digits: 4);

  @override
  bool shouldRepaint(covariant FranckHertzChartPainter oldDelegate) => true;
}

class FranckHertzChartBounds {
  const FranckHertzChartBounds({
    required this.minVoltage,
    required this.maxVoltage,
    required this.minCurrent,
    required this.maxCurrent,
  });

  final double minVoltage;
  final double maxVoltage;
  final double minCurrent;
  final double maxCurrent;

  factory FranckHertzChartBounds.from(List<FranckHertzChartPoint> points) {
    final voltages = points
        .map((point) => point.voltage)
        .toList(growable: false);
    final currents = points
        .map((point) => point.current)
        .toList(growable: false);
    final minVoltage = voltages.reduce(math.min).toDouble();
    final maxVoltage = voltages.reduce(math.max).toDouble();
    final minCurrent = currents.reduce(math.min).toDouble();
    final maxCurrent = currents.reduce(math.max).toDouble();
    final voltageSpan = maxVoltage == minVoltage
        ? math.max(maxVoltage.abs() * .2, 1).toDouble()
        : (maxVoltage - minVoltage) * 1.15;
    final currentSpan = maxCurrent == minCurrent
        ? math.max(maxCurrent.abs() * .2, 1).toDouble()
        : (maxCurrent - minCurrent) * 1.15;
    final voltagePad = (voltageSpan - (maxVoltage - minVoltage)) / 2;
    final currentPad = (currentSpan - (maxCurrent - minCurrent)) / 2;
    return FranckHertzChartBounds(
      minVoltage: minVoltage - voltagePad,
      maxVoltage: maxVoltage + voltagePad,
      minCurrent: minCurrent - currentPad,
      maxCurrent: maxCurrent + currentPad,
    );
  }
}

FranckHertzChartSpec franckHertzChartSpec(FranckHertzCalculation calculation) {
  final points = calculation.rows
      .where((row) => row.voltage != null && row.current != null)
      .map(
        (row) => FranckHertzChartPoint(
          voltage: row.voltage!.toDouble(),
          current: row.current!.toDouble(),
        ),
      )
      .toList(growable: false);
  return FranckHertzChartSpec(title: '弗兰克-赫兹电流曲线', points: points);
}

class FranckHertzChartSvg {
  const FranckHertzChartSvg._();

  static String build(List<FranckHertzChartPoint> points) {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final bounds = FranckHertzChartBounds.from(points);
    double x(double value) =>
        FranckHertzChartGeometry.left +
        (value - bounds.minVoltage) /
            (bounds.maxVoltage - bounds.minVoltage) *
            (FranckHertzChartGeometry.right - FranckHertzChartGeometry.left);
    double y(double value) =>
        FranckHertzChartGeometry.bottom -
        (value - bounds.minCurrent) /
            (bounds.maxCurrent - bounds.minCurrent) *
            (FranckHertzChartGeometry.bottom - FranckHertzChartGeometry.top);
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 420" width="760" height="420">',
    )..write('<rect x="0" y="0" width="760" height="420" fill="#FFFFFF"/>');
    for (var index = 0; index <= 4; index++) {
      final vertical =
          FranckHertzChartGeometry.left +
          index /
              4 *
              (FranckHertzChartGeometry.right - FranckHertzChartGeometry.left);
      final horizontal =
          FranckHertzChartGeometry.top +
          index /
              4 *
              (FranckHertzChartGeometry.bottom - FranckHertzChartGeometry.top);
      buffer
        ..write(
          '<line x1="${_number(vertical)}" y1="42" x2="${_number(vertical)}" y2="330" stroke="#E3EDF2" stroke-width="1"/>',
        )
        ..write(
          '<line x1="76" y1="${_number(horizontal)}" x2="718" y2="${_number(horizontal)}" stroke="#E3EDF2" stroke-width="1"/>',
        )
        ..write(
          '<text x="${_number(vertical)}" y="352" text-anchor="middle" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(_axisNumber(bounds.minVoltage + index / 4 * (bounds.maxVoltage - bounds.minVoltage)))}</text>',
        )
        ..write(
          '<text x="64" y="${_number(horizontal + 4)}" text-anchor="end" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(_axisNumber(bounds.maxCurrent - index / 4 * (bounds.maxCurrent - bounds.minCurrent)))}</text>',
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
      ..write('<text x="397" y="392" text-anchor="middle">UG2K / V</text>')
      ..write(
        '<text x="22" y="190" text-anchor="middle" transform="rotate(-90 22 190)">IA</text>',
      )
      ..write('</g>')
      ..write(
        '<line x1="76" y1="18" x2="94" y2="18" stroke="#287AA8" stroke-width="2.1"/>',
      )
      ..write(
        '<text x="100" y="22" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">IA</text>',
      );
    if (points.length > 1) {
      buffer.write(
        '<polyline points="${points.map((point) => '${_number(x(point.voltage))},${_number(y(point.current))}').join(' ')}" fill="none" stroke="#287AA8" stroke-width="2.1" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (final point in points) {
      buffer.write(
        '<circle cx="${_number(x(point.voltage))}" cy="${_number(y(point.current))}" r="4" fill="#FFFFFF" stroke="#287AA8" stroke-width="1.8"/>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _axisNumber(double value) =>
      FranckHertzCalculator.formatDouble(value, digits: 4);

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

TextStyle _franckChartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
