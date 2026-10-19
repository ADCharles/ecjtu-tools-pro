// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../theme/ecjtu_theme.dart';
import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import 'physics_decimal.dart';
import 'physics_hall_effect_models.dart';

const hallEffectChartColors = <Color>[
  Color(0xFF287AA8),
  Color(0xFFC36A36),
  Color(0xFF4D8D63),
  Color(0xFF8A619B),
  Color(0xFFAD7B24),
];

const hallEffectChartColorHexes = <String>[
  '#287AA8',
  '#C36A36',
  '#4D8D63',
  '#8A619B',
  '#AD7B24',
];

class HallEffectChartPoint {
  const HallEffectChartPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class HallEffectChartSeries {
  const HallEffectChartSeries({
    required this.name,
    required this.points,
    this.color,
    this.colorHex,
  });

  final String name;
  final List<HallEffectChartPoint> points;
  final Color? color;
  final String? colorHex;
}

class HallEffectChartSpec {
  const HallEffectChartSpec({required this.title, required this.series});

  final String title;
  final List<HallEffectChartSeries> series;

  bool get hasData => series.any((item) => item.points.isNotEmpty);
}

class HallEffectChartCard extends StatelessWidget {
  const HallEffectChartCard({
    super.key,
    required this.spec,
    required this.dark,
    required this.onExport,
  });

  final HallEffectChartSpec spec;
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
          Text(spec.title, style: _hallChartTitleStyle(dark)),
          const SizedBox(height: 9),
          if (spec.hasData)
            AspectRatio(
              aspectRatio:
                  HallEffectChartGeometry.width /
                  HallEffectChartGeometry.height,
              child: CustomPaint(
                painter: HallEffectChartPainter(
                  series: spec.series,
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

class HallEffectChartGeometry {
  const HallEffectChartGeometry._();

  static const width = 760.0;
  static const height = 420.0;
  static const left = 76.0;
  static const right = 718.0;
  static const top = 42.0;
  static const bottom = 330.0;
}

class HallEffectChartPainter extends CustomPainter {
  const HallEffectChartPainter({
    required this.series,
    required this.dark,
    required this.fontFamily,
  });

  final List<HallEffectChartSeries> series;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / HallEffectChartGeometry.width;
    final sy = size.height / HallEffectChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final usableSeries = series
        .where((item) => item.points.isNotEmpty)
        .toList(growable: false);
    final bounds = HallEffectChartBounds.from(usableSeries);
    canvas.drawRect(
      Offset.zero &
          const Size(
            HallEffectChartGeometry.width,
            HallEffectChartGeometry.height,
          ),
      Paint()
        ..color = EcjtuColors.platformSurface(
          dark,
          (dark ? const Color(0xFF101D31) : Colors.white),
        ),
    );
    double x(double value) =>
        HallEffectChartGeometry.left +
        (value - bounds.minX) /
            (bounds.maxX - bounds.minX) *
            (HallEffectChartGeometry.right - HallEffectChartGeometry.left);
    double y(double value) =>
        HallEffectChartGeometry.bottom -
        (value - bounds.minY) /
            (bounds.maxY - bounds.minY) *
            (HallEffectChartGeometry.bottom - HallEffectChartGeometry.top);

    final grid = Paint()
      ..color = dark ? const Color(0xFF28465C) : const Color(0xFFE3EDF2)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final horizontal =
          HallEffectChartGeometry.top +
          index /
              4 *
              (HallEffectChartGeometry.bottom - HallEffectChartGeometry.top);
      final vertical =
          HallEffectChartGeometry.left +
          index /
              4 *
              (HallEffectChartGeometry.right - HallEffectChartGeometry.left);
      canvas.drawLine(
        Offset(vertical, HallEffectChartGeometry.top),
        Offset(vertical, HallEffectChartGeometry.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(HallEffectChartGeometry.left, horizontal),
        Offset(HallEffectChartGeometry.right, horizontal),
        grid,
      );
      _drawText(
        canvas,
        _axisNumber(bounds.minX + index / 4 * (bounds.maxX - bounds.minX)),
        Offset(vertical, HallEffectChartGeometry.bottom + 22),
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
        Offset(HallEffectChartGeometry.left - 12, horizontal + 4),
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
      const Offset(HallEffectChartGeometry.left, HallEffectChartGeometry.top),
      const Offset(
        HallEffectChartGeometry.left,
        HallEffectChartGeometry.bottom,
      ),
      axis,
    );
    canvas.drawLine(
      const Offset(
        HallEffectChartGeometry.left,
        HallEffectChartGeometry.bottom,
      ),
      const Offset(
        HallEffectChartGeometry.right,
        HallEffectChartGeometry.bottom,
      ),
      axis,
    );

    for (var index = 0; index < usableSeries.length; index++) {
      final item = usableSeries[index];
      final color =
          item.color ??
          hallEffectChartColors[index % hallEffectChartColors.length];
      if (item.points.length > 1) {
        final path = Path();
        for (
          var pointIndex = 0;
          pointIndex < item.points.length;
          pointIndex++
        ) {
          final point = item.points[pointIndex];
          final position = Offset(x(point.x), y(point.y));
          if (pointIndex == 0) {
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
      for (final point in item.points) {
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
      final legendX = HallEffectChartGeometry.left + index * 128;
      canvas.drawLine(
        Offset(legendX, 18),
        Offset(legendX + 18, 18),
        Paint()
          ..color = color
          ..strokeWidth = 2.1,
      );
      _drawText(
        canvas,
        item.name,
        Offset(legendX + 24, 22),
        EcjtuColors.platformMuted(
          dark,
          (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
        ),
        11,
        FontWeight.w400,
      );
    }
    _drawText(
      canvas,
      'x / cm',
      Offset(
        (HallEffectChartGeometry.left + HallEffectChartGeometry.right) / 2,
        HallEffectChartGeometry.height - 28,
      ),
      dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
      12,
      FontWeight.w600,
      centered: true,
    );
    _drawRotatedText(
      canvas,
      'B',
      Offset(
        22,
        (HallEffectChartGeometry.top + HallEffectChartGeometry.bottom) / 2,
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

  static String _axisNumber(double value) {
    if (!value.isFinite) return '-';
    final fixed = value.toStringAsFixed(4);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  bool shouldRepaint(covariant HallEffectChartPainter oldDelegate) => true;
}

class HallEffectChartBounds {
  const HallEffectChartBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  factory HallEffectChartBounds.from(List<HallEffectChartSeries> series) {
    final points = series.expand((item) => item.points).toList(growable: false);
    final xValues = points.map((point) => point.x).toList(growable: false);
    final yValues = points.map((point) => point.y).toList(growable: false);
    final minX = xValues.reduce(math.min).toDouble();
    final maxX = xValues.reduce(math.max).toDouble();
    final minY = yValues.reduce(math.min).toDouble();
    final maxY = yValues.reduce(math.max).toDouble();
    final xSpan = maxX == minX
        ? math.max(maxX.abs() * .2, 1).toDouble()
        : (maxX - minX) * 1.15;
    final ySpan = maxY == minY
        ? math.max(maxY.abs() * .2, 1).toDouble()
        : (maxY - minY) * 1.15;
    final xPad = (xSpan - (maxX - minX)) / 2;
    final yPad = (ySpan - (maxY - minY)) / 2;
    return HallEffectChartBounds(
      minX: minX - xPad,
      maxX: maxX + xPad,
      minY: minY - yPad,
      maxY: maxY + yPad,
    );
  }
}

class HallEffectChartSvg {
  const HallEffectChartSvg._();

  static String build(List<HallEffectChartSeries> series) {
    final usable = series
        .map(
          (item) => HallEffectChartSeries(
            name: item.name,
            points: item.points
                .where((point) => point.x.isFinite && point.y.isFinite)
                .toList(growable: false),
            colorHex: item.colorHex,
          ),
        )
        .where((item) => item.points.isNotEmpty)
        .toList(growable: false);
    if (usable.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final bounds = HallEffectChartBounds.from(usable);
    double x(double value) =>
        HallEffectChartGeometry.left +
        (value - bounds.minX) /
            (bounds.maxX - bounds.minX) *
            (HallEffectChartGeometry.right - HallEffectChartGeometry.left);
    double y(double value) =>
        HallEffectChartGeometry.bottom -
        (value - bounds.minY) /
            (bounds.maxY - bounds.minY) *
            (HallEffectChartGeometry.bottom - HallEffectChartGeometry.top);
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 420" width="760" height="420">',
    )..write('<rect x="0" y="0" width="760" height="420" fill="#FFFFFF"/>');
    for (var index = 0; index <= 4; index++) {
      final vertical =
          HallEffectChartGeometry.left +
          index /
              4 *
              (HallEffectChartGeometry.right - HallEffectChartGeometry.left);
      final horizontal =
          HallEffectChartGeometry.top +
          index /
              4 *
              (HallEffectChartGeometry.bottom - HallEffectChartGeometry.top);
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
      ..write('<text x="397" y="392" text-anchor="middle">x / cm</text>')
      ..write(
        '<text x="22" y="190" text-anchor="middle" transform="rotate(-90 22 190)">B</text>',
      )
      ..write('</g>');
    for (var index = 0; index < usable.length; index++) {
      final item = usable[index];
      final color =
          item.colorHex ??
          hallEffectChartColorHexes[index % hallEffectChartColorHexes.length];
      if (item.points.length > 1) {
        buffer.write(
          '<polyline points="${item.points.map((point) => '${_number(x(point.x))},${_number(y(point.y))}').join(' ')}" fill="none" stroke="$color" stroke-width="2.1" stroke-linejoin="round" stroke-linecap="round"/>',
        );
      }
      for (final point in item.points) {
        buffer.write(
          '<circle cx="${_number(x(point.x))}" cy="${_number(y(point.y))}" r="4" fill="#FFFFFF" stroke="$color" stroke-width="1.8"/>',
        );
      }
      final legendX = HallEffectChartGeometry.left + index * 128;
      buffer
        ..write(
          '<line x1="${_number(legendX)}" y1="18" x2="${_number(legendX + 18)}" y2="18" stroke="$color" stroke-width="2.1"/>',
        )
        ..write(
          '<text x="${_number(legendX + 24)}" y="22" fill="#667B8E" font-family="NotoSansSCPdf" font-size="11">${_xml(item.name)}</text>',
        );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _axisNumber(double value) {
    if (!value.isFinite) return '-';
    final fixed = value.toStringAsFixed(4);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _number(double value) => value.toStringAsFixed(4);

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

List<HallEffectChartSpec> hallEffectChartSpecs(
  HallEffectCalculation calculation,
  List<String> radii,
) {
  final solenoidPoints = calculation.solenoid
      .where((row) => row.x != null && row.field != null)
      .map(
        (row) => HallEffectChartPoint(
          x: row.x!.toDouble(),
          y: row.field!.toDouble(),
        ),
      )
      .toList(growable: false);
  final specs = <HallEffectChartSpec>[
    HallEffectChartSpec(
      title: '直螺线管磁感应强度',
      series: [HallEffectChartSeries(name: 'B', points: solenoidPoints)],
    ),
  ];
  for (var index = 0; index < calculation.coils.length; index++) {
    final rows = calculation.coils[index];
    List<HallEffectChartPoint> pointsFor(
      PhysicsDecimal? Function(HallEffectCoilRowResult row) value,
    ) {
      return rows
          .where((row) => row.x != null && value(row) != null)
          .map(
            (row) => HallEffectChartPoint(
              x: row.x!.toDouble(),
              y: value(row)!.toDouble(),
            ),
          )
          .toList(growable: false);
    }

    final radius = index < radii.length ? radii[index] : '';
    specs.add(
      HallEffectChartSpec(
        title: 'a = $radius cm 磁场关系',
        series: [
          HallEffectChartSeries(
            name: 'Ba',
            points: pointsFor((row) => row.a.field),
          ),
          HallEffectChartSeries(
            name: 'Bb',
            points: pointsFor((row) => row.b.field),
          ),
          HallEffectChartSeries(
            name: 'Ba+b',
            points: pointsFor((row) => row.combined.field),
          ),
          HallEffectChartSeries(
            name: 'Ba+Bb',
            points: pointsFor((row) => row.sum),
          ),
        ],
      ),
    );
  }
  return specs;
}

TextStyle _hallChartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
