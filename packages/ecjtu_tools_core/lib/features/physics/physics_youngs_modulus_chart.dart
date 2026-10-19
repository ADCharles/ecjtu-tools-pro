// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import 'physics_youngs_modulus_calculator.dart';
import 'physics_youngs_modulus_models.dart';

const youngsModulusChartColor = Color(0xFF1976A5);
const youngsModulusChartColorHex = '#1976A5';

class YoungsModulusChartPoint {
  const YoungsModulusChartPoint({required this.index, required this.reading});

  final int index;
  final double reading;
}

class YoungsModulusChartGeometry {
  const YoungsModulusChartGeometry({
    required this.minReading,
    required this.maxReading,
  });

  static const width = 520.0;
  static const height = 360.0;
  static const left = 62.0;
  static const right = 484.0;
  static const top = 48.0;
  static const bottom = 288.0;

  final double minReading;
  final double maxReading;

  factory YoungsModulusChartGeometry.from(
    List<YoungsModulusChartPoint> points,
  ) {
    final values = points.map((point) => point.reading).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = maxValue == minValue
        ? math.max(maxValue.abs() * .2, .1)
        : (maxValue - minValue) * 1.2;
    final low = minValue - (span - (maxValue - minValue)) / 2;
    return YoungsModulusChartGeometry(minReading: low, maxReading: low + span);
  }

  double x(int index) {
    return left + index / (YoungsModulusState.scaleCount - 1) * (right - left);
  }

  double y(double value) {
    final span = maxReading - minReading;
    return bottom -
        (value - minReading) / (span == 0 ? 1 : span) * (bottom - top);
  }
}

class YoungsModulusChartCard extends StatelessWidget {
  const YoungsModulusChartCard({
    super.key,
    required this.points,
    required this.dark,
    required this.onExport,
  });

  final List<YoungsModulusChartPoint> points;
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
      constraints: const BoxConstraints(maxWidth: 620),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('负荷与标尺读数图', style: _youngsChartTitleStyle(dark)),
          const SizedBox(height: 8),
          if (hasData)
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(
                  color: dark
                      ? const Color(0xFF28465C)
                      : const Color(0xFFE5EDF2),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: AspectRatio(
                aspectRatio:
                    YoungsModulusChartGeometry.width /
                    YoungsModulusChartGeometry.height,
                child: CustomPaint(
                  painter: _YoungsModulusChartPainter(
                    points: points,
                    dark: dark,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 96,
              child: Center(
                child: Text(
                  '填写一组完整读数后显示图形。',
                  style: TextStyle(
                    color: dark
                        ? EcjtuColors.darkTextSecondary
                        : const Color(0xFF667B8E),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
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

class _YoungsModulusChartPainter extends CustomPainter {
  const _YoungsModulusChartPainter({
    required this.points,
    required this.dark,
    required this.fontFamily,
  });

  final List<YoungsModulusChartPoint> points;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = YoungsModulusChartGeometry.from(points);
    final sx = size.width / YoungsModulusChartGeometry.width;
    final sy = size.height / YoungsModulusChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final chartSize = const Size(
      YoungsModulusChartGeometry.width,
      YoungsModulusChartGeometry.height,
    );
    canvas.drawRect(
      Offset.zero & chartSize,
      Paint()..color = dark ? const Color(0xFF12263A) : const Color(0xFFFBFDFF),
    );

    final axis = Paint()
      ..color = dark ? const Color(0xFF91B8CF) : const Color(0xFF547188)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      const Offset(
        YoungsModulusChartGeometry.left,
        YoungsModulusChartGeometry.top,
      ),
      const Offset(
        YoungsModulusChartGeometry.left,
        YoungsModulusChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        YoungsModulusChartGeometry.left,
        YoungsModulusChartGeometry.bottom,
      ),
      const Offset(
        YoungsModulusChartGeometry.right,
        YoungsModulusChartGeometry.bottom,
      ),
      axis,
    );

    final sorted = [...points]
      ..sort((left, right) => left.index.compareTo(right.index));
    if (sorted.length > 1) {
      final path = Path();
      for (var index = 0; index < sorted.length; index++) {
        final point = sorted[index];
        final position = Offset(
          geometry.x(point.index),
          geometry.y(point.reading),
        );
        if (index == 0) {
          path.moveTo(position.dx, position.dy);
        } else {
          path.lineTo(position.dx, position.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = youngsModulusChartColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    final dot = Paint()
      ..color = youngsModulusChartColor
      ..style = PaintingStyle.fill;
    final dotOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final point in sorted) {
      final position = Offset(
        geometry.x(point.index),
        geometry.y(point.reading),
      );
      canvas.drawCircle(position, 4, dot);
      canvas.drawCircle(position, 4, dotOutline);
    }

    final labelColor = dark ? const Color(0xFFC1D7E5) : const Color(0xFF58748A);
    _drawText(
      canvas,
      '负荷 / kg',
      const Offset(
        YoungsModulusChartGeometry.right,
        YoungsModulusChartGeometry.bottom + 30,
      ),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    _drawText(
      canvas,
      '标尺读数 / cm',
      const Offset(
        YoungsModulusChartGeometry.left,
        YoungsModulusChartGeometry.top - 12,
      ),
      labelColor,
      12,
      FontWeight.normal,
    );
    _drawText(
      canvas,
      YoungsModulusCalculator.format(geometry.minReading),
      const Offset(
        YoungsModulusChartGeometry.left - 8,
        YoungsModulusChartGeometry.bottom + 5,
      ),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    _drawText(
      canvas,
      YoungsModulusCalculator.format(geometry.maxReading),
      const Offset(
        YoungsModulusChartGeometry.left - 8,
        YoungsModulusChartGeometry.top + 5,
      ),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    for (var index = 0; index < YoungsModulusState.scaleCount; index++) {
      _drawText(
        canvas,
        '$index',
        Offset(geometry.x(index), YoungsModulusChartGeometry.bottom + 18),
        labelColor,
        12,
        FontWeight.normal,
        centered: true,
      );
    }
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
  bool shouldRepaint(covariant _YoungsModulusChartPainter oldDelegate) => true;
}

class YoungsModulusChartSvg {
  const YoungsModulusChartSvg._();

  static String build(List<YoungsModulusChartPoint> points) {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final geometry = YoungsModulusChartGeometry.from(points);
    final sorted = [...points]
      ..sort((left, right) => left.index.compareTo(right.index));
    final buffer = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360" width="520" height="360">',
      )
      ..writeln('<rect x="0" y="0" width="520" height="360" fill="#FBFDFF"/>')
      ..writeln(
        '<line x1="62" y1="48" x2="62" y2="288" stroke="#547188" stroke-width="1.2"/>',
      )
      ..writeln(
        '<line x1="62" y1="288" x2="484" y2="288" stroke="#547188" stroke-width="1.2"/>',
      )
      ..writeln(
        '<g fill="#58748A" font-family="NotoSansSCPdf" font-size="12" font-weight="400">',
      )
      ..writeln(
        '<text x="54" y="293" text-anchor="end">${_xml(YoungsModulusCalculator.format(geometry.minReading))}</text>',
      )
      ..writeln(
        '<text x="54" y="53" text-anchor="end">${_xml(YoungsModulusCalculator.format(geometry.maxReading))}</text>',
      )
      ..writeln('</g>')
      ..writeln(
        '<g fill="#58748A" font-family="NotoSansSCPdf" font-size="12" font-weight="400">',
      )
      ..writeln('<text x="484" y="318" text-anchor="end">负荷 / kg</text>')
      ..writeln('<text x="62" y="36">标尺读数 / cm</text>')
      ..writeln('</g>');
    for (var index = 0; index < YoungsModulusState.scaleCount; index++) {
      buffer.writeln(
        '<text x="${_number(geometry.x(index))}" y="306" text-anchor="middle" fill="#58748A" font-family="NotoSansSCPdf" font-size="12" font-weight="400">$index</text>',
      );
    }
    if (sorted.length > 1) {
      final pointsText = sorted
          .map(
            (point) =>
                '${_number(geometry.x(point.index))},${_number(geometry.y(point.reading))}',
          )
          .join(' ');
      buffer.writeln(
        '<polyline points="$pointsText" fill="none" stroke="$youngsModulusChartColorHex" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (final point in sorted) {
      buffer.writeln(
        '<circle cx="${_number(geometry.x(point.index))}" cy="${_number(geometry.y(point.reading))}" r="4" fill="$youngsModulusChartColorHex"/>',
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
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

TextStyle _youngsChartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

List<YoungsModulusChartPoint> youngsModulusChartPoints(
  List<YoungsModulusScaleResult> scale,
) {
  return scale
      .where((item) => item.complete && item.mean != null)
      .map(
        (item) =>
            YoungsModulusChartPoint(index: item.index, reading: item.mean!),
      )
      .toList(growable: false);
}
