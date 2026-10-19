// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import 'physics_voltage_current_calculator.dart';
import 'physics_voltage_current_models.dart';

const voltageCurrentChartColors = <Color>[
  Color(0xFF1976A5),
  Color(0xFFA26216),
  Color(0xFF36815A),
  Color(0xFF8D4051),
  Color(0xFF7153A0),
];

const voltageCurrentChartColorHexes = <String>[
  '#1976A5',
  '#A26216',
  '#36815A',
  '#8D4051',
  '#7153A0',
];

class VoltageCurrentChartPoint {
  const VoltageCurrentChartPoint({
    required this.current,
    required this.voltage,
  });

  final double current;
  final double voltage;
}

class VoltageCurrentChartGeometry {
  const VoltageCurrentChartGeometry._();

  static const width = 520.0;
  static const height = 360.0;
  static const left = 62.0;
  static const right = 482.0;
  static const top = 48.0;
  static const bottom = 288.0;
}

class VoltageCurrentChartCard extends StatelessWidget {
  const VoltageCurrentChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
    required this.dark,
    required this.onExport,
  });

  final String title;
  final List<VoltageCurrentChartPoint> points;
  final Color color;
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
    final hasData = points.isNotEmpty;
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
          Text(title, style: _voltageCurrentChartTitleStyle(dark)),
          const SizedBox(height: 8),
          if (hasData)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5EDF2)),
                borderRadius: BorderRadius.circular(5),
                color: dark ? const Color(0xFF12263A) : const Color(0xFFFBFDFF),
              ),
              child: AspectRatio(
                aspectRatio:
                    VoltageCurrentChartGeometry.width /
                    VoltageCurrentChartGeometry.height,
                child: CustomPaint(
                  painter: _VoltageCurrentChartPainter(
                    points: points,
                    color: color,
                    dark: dark,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            )
          else
            Text(
              '填写一组完整数据后显示图形。',
              style: TextStyle(
                color: dark
                    ? EcjtuColors.darkTextSecondary
                    : const Color(0xFF667B8E),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          if (hasData) ...[
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

class _VoltageCurrentChartPainter extends CustomPainter {
  const _VoltageCurrentChartPainter({
    required this.points,
    required this.color,
    required this.dark,
    required this.fontFamily,
  });

  final List<VoltageCurrentChartPoint> points;
  final Color color;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / VoltageCurrentChartGeometry.width;
    final sy = size.height / VoltageCurrentChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final bounds = VoltageCurrentChartBounds.from(points);
    canvas.drawRect(
      Offset.zero &
          const Size(
            VoltageCurrentChartGeometry.width,
            VoltageCurrentChartGeometry.height,
          ),
      Paint()..color = dark ? const Color(0xFF12263A) : const Color(0xFFFBFDFF),
    );
    double x(double value) =>
        VoltageCurrentChartGeometry.left +
        (value - bounds.minCurrent) /
            (bounds.maxCurrent - bounds.minCurrent) *
            (VoltageCurrentChartGeometry.right -
                VoltageCurrentChartGeometry.left);
    double y(double value) =>
        VoltageCurrentChartGeometry.bottom -
        (value - bounds.minVoltage) /
            (bounds.maxVoltage - bounds.minVoltage) *
            (VoltageCurrentChartGeometry.bottom -
                VoltageCurrentChartGeometry.top);

    final axis = Paint()
      ..color = dark ? const Color(0xFF91B8CF) : const Color(0xFF547188)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      const Offset(
        VoltageCurrentChartGeometry.left,
        VoltageCurrentChartGeometry.top,
      ),
      const Offset(
        VoltageCurrentChartGeometry.left,
        VoltageCurrentChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        VoltageCurrentChartGeometry.left,
        VoltageCurrentChartGeometry.bottom,
      ),
      const Offset(
        VoltageCurrentChartGeometry.right,
        VoltageCurrentChartGeometry.bottom,
      ),
      axis,
    );

    final sorted = [...points]
      ..sort((left, right) => left.current.compareTo(right.current));
    if (sorted.length > 1) {
      final path = Path();
      for (var index = 0; index < sorted.length; index++) {
        final point = sorted[index];
        final position = Offset(x(point.current), y(point.voltage));
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
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final point in sorted) {
      final position = Offset(x(point.current), y(point.voltage));
      canvas.drawCircle(position, 4, dot);
      canvas.drawCircle(position, 4, dotOutline);
    }

    final labelColor = dark ? const Color(0xFFC1D7E5) : const Color(0xFF58748A);
    _drawText(
      canvas,
      'I / mA',
      const Offset(
        VoltageCurrentChartGeometry.right,
        VoltageCurrentChartGeometry.bottom + 30,
      ),
      labelColor,
      12,
      FontWeight.w400,
      alignRight: true,
    );
    _drawText(
      canvas,
      'U / V',
      const Offset(
        VoltageCurrentChartGeometry.left,
        VoltageCurrentChartGeometry.top - 12,
      ),
      labelColor,
      12,
      FontWeight.w400,
    );
    _drawText(
      canvas,
      VoltageCurrentCalculator.format(bounds.minVoltage),
      const Offset(
        VoltageCurrentChartGeometry.left - 8,
        VoltageCurrentChartGeometry.bottom + 5,
      ),
      labelColor,
      12,
      FontWeight.w400,
      alignRight: true,
    );
    _drawText(
      canvas,
      VoltageCurrentCalculator.format(bounds.maxVoltage),
      const Offset(
        VoltageCurrentChartGeometry.left - 8,
        VoltageCurrentChartGeometry.top + 5,
      ),
      labelColor,
      12,
      FontWeight.w400,
      alignRight: true,
    );
    _drawText(
      canvas,
      VoltageCurrentCalculator.format(bounds.minCurrent),
      const Offset(
        VoltageCurrentChartGeometry.left,
        VoltageCurrentChartGeometry.bottom + 18,
      ),
      labelColor,
      12,
      FontWeight.w400,
      centered: true,
    );
    _drawText(
      canvas,
      VoltageCurrentCalculator.format(bounds.maxCurrent),
      const Offset(
        VoltageCurrentChartGeometry.right,
        VoltageCurrentChartGeometry.bottom + 18,
      ),
      labelColor,
      12,
      FontWeight.w400,
      centered: true,
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

  @override
  bool shouldRepaint(covariant _VoltageCurrentChartPainter oldDelegate) => true;
}

class VoltageCurrentChartBounds {
  const VoltageCurrentChartBounds({
    required this.minCurrent,
    required this.maxCurrent,
    required this.minVoltage,
    required this.maxVoltage,
  });

  final double minCurrent;
  final double maxCurrent;
  final double minVoltage;
  final double maxVoltage;

  factory VoltageCurrentChartBounds.from(
    List<VoltageCurrentChartPoint> points,
  ) {
    final currents = points
        .map((point) => point.current)
        .toList(growable: false);
    final voltages = points
        .map((point) => point.voltage)
        .toList(growable: false);
    final minCurrent = currents.reduce(math.min);
    final maxCurrent = currents.reduce(math.max);
    final minVoltage = voltages.reduce(math.min);
    final maxVoltage = voltages.reduce(math.max);
    final currentPadding =
        (maxCurrent == minCurrent
                ? math.max(maxCurrent.abs() * .2, .1)
                : (maxCurrent - minCurrent) * .1)
            .toDouble();
    final voltagePadding =
        (maxVoltage == minVoltage
                ? math.max(maxVoltage.abs() * .2, .1)
                : (maxVoltage - minVoltage) * .1)
            .toDouble();
    var currentLow = math.min(0, minCurrent - currentPadding).toDouble();
    var currentHigh = maxCurrent + currentPadding;
    var voltageLow = math.min(0, minVoltage - voltagePadding).toDouble();
    var voltageHigh = maxVoltage + voltagePadding;
    if (currentHigh <= currentLow) currentHigh = currentLow + 1;
    if (voltageHigh <= voltageLow) voltageHigh = voltageLow + 1;
    return VoltageCurrentChartBounds(
      minCurrent: currentLow,
      maxCurrent: currentHigh,
      minVoltage: voltageLow,
      maxVoltage: voltageHigh,
    );
  }
}

TextStyle _voltageCurrentChartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

class VoltageCurrentChartSvg {
  const VoltageCurrentChartSvg._();

  static String build(List<VoltageCurrentChartPoint> points, String colorHex) {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final bounds = VoltageCurrentChartBounds.from(points);
    double x(double value) =>
        VoltageCurrentChartGeometry.left +
        (value - bounds.minCurrent) /
            (bounds.maxCurrent - bounds.minCurrent) *
            (VoltageCurrentChartGeometry.right -
                VoltageCurrentChartGeometry.left);
    double y(double value) =>
        VoltageCurrentChartGeometry.bottom -
        (value - bounds.minVoltage) /
            (bounds.maxVoltage - bounds.minVoltage) *
            (VoltageCurrentChartGeometry.bottom -
                VoltageCurrentChartGeometry.top);
    final sorted = [...points]
      ..sort((left, right) => left.current.compareTo(right.current));
    final buffer =
        StringBuffer(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360" width="520" height="360">',
          )
          ..write('<rect width="520" height="360" fill="#FBFDFF"/>')
          ..write(
            '<line x1="62" y1="48" x2="62" y2="288" stroke="#547188" stroke-width="1.2"/>',
          )
          ..write(
            '<line x1="62" y1="288" x2="482" y2="288" stroke="#547188" stroke-width="1.2"/>',
          )
          ..write(
            '<g fill="#58748A" font-family="NotoSansSCPdf" font-size="12">',
          )
          ..write(
            '<text x="54" y="293" text-anchor="end">${_xml(VoltageCurrentCalculator.format(bounds.minVoltage))}</text>',
          )
          ..write(
            '<text x="54" y="53" text-anchor="end">${_xml(VoltageCurrentCalculator.format(bounds.maxVoltage))}</text>',
          )
          ..write(
            '<text x="62" y="306" text-anchor="middle">${_xml(VoltageCurrentCalculator.format(bounds.minCurrent))}</text>',
          )
          ..write(
            '<text x="482" y="306" text-anchor="middle">${_xml(VoltageCurrentCalculator.format(bounds.maxCurrent))}</text>',
          )
          ..write('<text x="482" y="318" text-anchor="end">I / mA</text>')
          ..write('<text x="62" y="36">U / V</text>')
          ..write('</g>');
    if (sorted.length > 1) {
      buffer.write(
        '<polyline points="${sorted.map((point) => '${_number(x(point.current))},${_number(y(point.voltage))}').join(' ')}" fill="none" stroke="$colorHex" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (final point in sorted) {
      buffer.write(
        '<circle cx="${_number(x(point.current))}" cy="${_number(y(point.voltage))}" r="4" fill="$colorHex" stroke="#FFFFFF" stroke-width="1.2"/>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

List<VoltageCurrentChartPoint> voltageCurrentLinearChartPoints(
  VoltageCurrentBlockResult result,
) {
  return result.points
      .where((point) => point.complete)
      .map(
        (point) => VoltageCurrentChartPoint(
          current: point.currentMilliAmp!,
          voltage: point.voltage!,
        ),
      )
      .toList(growable: false);
}

List<VoltageCurrentChartPoint> voltageCurrentDiodeChartPoints(
  List<VoltageCurrentDiodeResult> points,
) {
  return points
      .where((point) => point.complete)
      .map(
        (point) => VoltageCurrentChartPoint(
          current: point.currentMilliAmp!,
          voltage: point.voltage!,
        ),
      )
      .toList(growable: false);
}
