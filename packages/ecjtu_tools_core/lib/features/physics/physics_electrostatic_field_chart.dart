// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math' as math;
import 'physics_shared_styles.dart';

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import 'physics_electrostatic_field_calculator.dart';
import 'physics_electrostatic_field_models.dart';

enum ElectrostaticChartKind { coaxial, parallel }

class ElectrostaticChartGeometry {
  const ElectrostaticChartGeometry._();

  static const width = 520.0;
  static const height = 360.0;
}

class ElectrostaticFieldChartCard extends StatelessWidget {
  const ElectrostaticFieldChartCard({
    super.key,
    required this.calculation,
    required this.kind,
    required this.dark,
    required this.onExport,
  });

  final ElectrostaticFieldCalculation calculation;
  final ElectrostaticChartKind kind;
  final bool dark;
  final Future<void> Function(ElectrostaticChartKind kind) onExport;

  String get _title =>
      kind == ElectrostaticChartKind.coaxial ? '同轴圆柱面等势线图' : '两平行导线距离比图';

  bool get _hasData => kind == ElectrostaticChartKind.coaxial
      ? calculation.hasCoaxialChart
      : calculation.hasParallelChart;

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
          Text(_title, style: _chartTitleStyle(dark)),
          const SizedBox(height: 8),
          if (_hasData)
            Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF12263A) : const Color(0xFFFBFDFF),
                border: Border.all(
                  color: dark
                      ? const Color(0xFF28465C)
                      : const Color(0xFFE5EDF2),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio:
                    ElectrostaticChartGeometry.width /
                    ElectrostaticChartGeometry.height,
                child: CustomPaint(
                  painter: _ElectrostaticChartPainter(
                    calculation: calculation,
                    kind: kind,
                    dark: dark,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            )
          else
            Text(
              kind == ElectrostaticChartKind.coaxial
                  ? '填写一条完整等势线后显示图形。'
                  : '填写一组完整距离后显示图形。',
              style: TextStyle(
                color: dark
                    ? EcjtuColors.darkTextSecondary
                    : const Color(0xFF667B8E),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          if (_hasData) ...[
            const SizedBox(height: 7),
            OutlinedButton(
              onPressed: () => onExport(kind),
              style: physicsSecondaryButtonStyle(context),
              child: const Text('下载此图 PDF'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ElectrostaticChartPainter extends CustomPainter {
  const _ElectrostaticChartPainter({
    required this.calculation,
    required this.kind,
    required this.dark,
    required this.fontFamily,
  });

  final ElectrostaticFieldCalculation calculation;
  final ElectrostaticChartKind kind;
  final bool dark;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / ElectrostaticChartGeometry.width;
    final sy = size.height / ElectrostaticChartGeometry.height;
    canvas.save();
    canvas.scale(sx, sy);
    final chartSize = const Size(
      ElectrostaticChartGeometry.width,
      ElectrostaticChartGeometry.height,
    );
    canvas.drawRect(
      Offset.zero & chartSize,
      Paint()..color = dark ? const Color(0xFF12263A) : const Color(0xFFFBFDFF),
    );
    if (kind == ElectrostaticChartKind.coaxial) {
      _paintCoaxial(canvas);
    } else {
      _paintParallel(canvas);
    }
    canvas.restore();
  }

  void _paintCoaxial(Canvas canvas) {
    final valid = calculation.coaxial
        .where(
          (row) =>
              row.radii.length == ElectrostaticFieldState.pointCount &&
              row.radii.every((value) => value != null && value.isFinite),
        )
        .toList(growable: false);
    if (valid.isEmpty) return;
    const cx = 255.0;
    const cy = 185.0;
    final radii = valid
        .expand((row) => row.radii.whereType<double>())
        .toList(growable: false);
    final maxRadius = radii.reduce((left, right) => math.max(left, right));
    final radiusScale = 135 / (maxRadius == 0 ? 1 : maxRadius);
    final fieldLine = Paint()
      ..color = dark ? const Color(0xFF638CA5) : const Color(0xFFA7BDCB)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    for (var index = 0; index < ElectrostaticFieldState.pointCount; index++) {
      final angle =
          -math.pi / 2 +
          index * (2 * math.pi / ElectrostaticFieldState.pointCount);
      _drawDashedLine(
        canvas,
        const Offset(cx, cy),
        Offset(cx + math.cos(angle) * 145, cy + math.sin(angle) * 145),
        fieldLine,
        const [4, 4],
      );
    }
    for (final line in valid) {
      final path = Path();
      for (var index = 0; index < line.radii.length; index++) {
        final angle =
            -math.pi / 2 +
            index * (2 * math.pi / ElectrostaticFieldState.pointCount);
        final radius = line.radii[index]! * radiusScale;
        final point = Offset(
          cx + math.cos(angle) * radius,
          cy + math.sin(angle) * radius,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      final stroke = Paint()
        ..color = _lineColors[line.index % _lineColors.length]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, stroke);
    }
    canvas.drawCircle(
      const Offset(cx, cy),
      8,
      Paint()..color = dark ? const Color(0xFFB7D9ED) : const Color(0xFF294F65),
    );
    _drawText(
      canvas,
      '等势线与电场线',
      const Offset(cx, 20),
      const Color(0xFF315B73),
      14,
      FontWeight.w700,
      centered: true,
    );
    for (var index = 0; index < valid.length; index++) {
      final line = valid[index];
      _drawText(
        canvas,
        '${line.potential} V',
        Offset(86 + index * 78, 43),
        _lineColors[line.index % _lineColors.length],
        12,
        FontWeight.normal,
      );
    }
  }

  void _paintParallel(Canvas canvas) {
    final values = calculation.parallel
        .where((row) => row.complete && row.ratio != null)
        .toList(growable: false);
    if (values.isEmpty) return;
    final bounds = _parallelBounds(values);
    const left = 64.0;
    const right = 488.0;
    const top = 54.0;
    const bottom = 292.0;
    double sx(int index) =>
        left +
        index / (ElectrostaticFieldState.pointCount - 1) * (right - left);
    double sy(double value) =>
        bottom -
        (value - bounds.low) / (bounds.high - bounds.low) * (bottom - top);
    final axis = Paint()
      ..color = dark ? const Color(0xFF91B8CF) : const Color(0xFF547188)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(left, top), const Offset(left, bottom), axis);
    canvas.drawLine(
      const Offset(left, bottom),
      const Offset(right, bottom),
      axis,
    );
    if (calculation.ratioAverage != null) {
      final average = Paint()
        ..color = const Color(0xFFB98327)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke;
      final y = sy(calculation.ratioAverage!);
      _drawDashedLine(
        canvas,
        Offset(left, y),
        Offset(right, y),
        average,
        const [5, 4],
      );
    }
    if (values.length > 1) {
      final path = Path();
      for (var index = 0; index < values.length; index++) {
        final row = values[index];
        final point = Offset(sx(row.index), sy(row.ratio!));
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      final line = Paint()
        ..color = const Color(0xFF1976A5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, line);
    }
    final dot = Paint()
      ..color = const Color(0xFF1976A5)
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final row in values) {
      final point = Offset(sx(row.index), sy(row.ratio!));
      canvas.drawCircle(point, 4, dot);
      canvas.drawCircle(point, 4, dotBorder);
    }
    final labelColor = dark ? const Color(0xFFC1D7E5) : const Color(0xFF58748A);
    _drawText(
      canvas,
      'C',
      const Offset(left, top - 14),
      labelColor,
      15,
      FontWeight.normal,
      italic: true,
    );
    _drawText(
      canvas,
      '测点',
      const Offset(right, bottom + 31),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    _drawText(
      canvas,
      ElectrostaticFieldCalculator.format(bounds.low),
      const Offset(left - 9, bottom + 18),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    _drawText(
      canvas,
      ElectrostaticFieldCalculator.format(bounds.high),
      const Offset(left - 9, top + 5),
      labelColor,
      12,
      FontWeight.normal,
      alignRight: true,
    );
    for (var index = 0; index < ElectrostaticFieldState.pointCount; index++) {
      _drawText(
        canvas,
        '${index + 1}',
        Offset(sx(index), bottom + 18),
        labelColor,
        12,
        FontWeight.normal,
        centered: true,
      );
    }
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
    bool italic = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: fontFamily,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
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
  bool shouldRepaint(covariant _ElectrostaticChartPainter oldDelegate) => true;
}

void _drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint,
  List<double> pattern,
) {
  if (pattern.length < 2 || pattern[0] <= 0 || pattern[1] <= 0) {
    canvas.drawLine(start, end, paint);
    return;
  }
  final delta = end - start;
  final length = delta.distance;
  if (length == 0) return;
  final direction = delta / length;
  var distance = 0.0;
  var patternIndex = 0;
  while (distance < length) {
    final segmentLength = pattern[patternIndex % pattern.length];
    final segmentEnd = (distance + segmentLength).clamp(0.0, length);
    if (patternIndex.isEven) {
      canvas.drawLine(
        start + direction * distance,
        start + direction * segmentEnd,
        paint,
      );
    }
    distance = segmentEnd;
    patternIndex++;
  }
}

class _ParallelBounds {
  const _ParallelBounds({required this.low, required this.high});

  final double low;
  final double high;
}

_ParallelBounds _parallelBounds(List<ElectrostaticParallelRowResult> values) {
  final ratios = values.map((row) => row.ratio!).toList(growable: false);
  final minimum = ratios.reduce((left, right) => math.min(left, right));
  final maximum = ratios.reduce((left, right) => math.max(left, right));
  final difference = maximum - minimum;
  final span = difference == 0
      ? math.max(maximum.abs() * .2, .1)
      : difference * 1.2;
  final low = minimum - (span - difference) / 2;
  return _ParallelBounds(low: low, high: low + span);
}

const _lineColors = <Color>[
  Color(0xFF1A7FB4),
  Color(0xFF9D5C18),
  Color(0xFF3A8A5B),
  Color(0xFF9B3E51),
  Color(0xFF7058A7),
];

TextStyle _chartTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

class ElectrostaticChartSvg {
  const ElectrostaticChartSvg._();

  static String build(
    ElectrostaticChartKind kind,
    ElectrostaticFieldCalculation calculation,
  ) {
    return kind == ElectrostaticChartKind.coaxial
        ? _coaxial(calculation)
        : _parallel(calculation);
  }

  static String _coaxial(ElectrostaticFieldCalculation calculation) {
    final valid = calculation.coaxial
        .where(
          (row) =>
              row.radii.length == ElectrostaticFieldState.pointCount &&
              row.radii.every((value) => value != null && value.isFinite),
        )
        .toList(growable: false);
    if (valid.isEmpty) throw StateError('当前图表没有可下载的数据。');
    const cx = 255.0;
    const cy = 185.0;
    final values = valid
        .expand((row) => row.radii.whereType<double>())
        .toList(growable: false);
    final maxRadius = values.reduce((left, right) => math.max(left, right));
    final radiusScale = 135 / (maxRadius == 0 ? 1 : maxRadius);
    final buffer = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360" width="520" height="360">',
    )..write('<rect width="520" height="360" fill="#FBFDFF"/>');
    for (var index = 0; index < ElectrostaticFieldState.pointCount; index++) {
      final angle =
          -math.pi / 2 +
          index * (2 * math.pi / ElectrostaticFieldState.pointCount);
      buffer.write(
        '<line x1="$cx" y1="$cy" x2="${_number(cx + math.cos(angle) * 145)}" y2="${_number(cy + math.sin(angle) * 145)}" stroke="#A7BDCB" stroke-width="1.1" stroke-dasharray="4 4"/>',
      );
    }
    for (final line in valid) {
      final points = <String>[];
      for (var index = 0; index < line.radii.length; index++) {
        final angle =
            -math.pi / 2 +
            index * (2 * math.pi / ElectrostaticFieldState.pointCount);
        final radius = line.radii[index]! * radiusScale;
        points.add(
          '${_number(cx + math.cos(angle) * radius)},${_number(cy + math.sin(angle) * radius)}',
        );
      }
      buffer.write(
        '<polyline points="${points.join(' ')}" fill="none" stroke="${_colorHex(line.index)}" stroke-width="2.2" stroke-linejoin="round"/>',
      );
    }
    buffer
      ..write('<circle cx="$cx" cy="$cy" r="8" fill="#294F65"/>')
      ..write(
        '<text x="$cx" y="20" text-anchor="middle" fill="#315B73" font-family="NotoSansSCPdf" font-size="14" font-weight="700">等势线与电场线</text>',
      );
    for (var index = 0; index < valid.length; index++) {
      final line = valid[index];
      buffer.write(
        '<text x="${86 + index * 78}" y="43" fill="${_colorHex(line.index)}" font-family="NotoSansSCPdf" font-size="12">${_xml('${line.potential} V')}</text>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _parallel(ElectrostaticFieldCalculation calculation) {
    final values = calculation.parallel
        .where((row) => row.complete && row.ratio != null)
        .toList(growable: false);
    if (values.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final bounds = _parallelBounds(values);
    const left = 64.0;
    const right = 488.0;
    const top = 54.0;
    const bottom = 292.0;
    double sx(int index) =>
        left +
        index / (ElectrostaticFieldState.pointCount - 1) * (right - left);
    double sy(double value) =>
        bottom -
        (value - bounds.low) / (bounds.high - bounds.low) * (bottom - top);
    final buffer =
        StringBuffer(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 520 360" width="520" height="360">',
          )
          ..write('<rect width="520" height="360" fill="#FBFDFF"/>')
          ..write(
            '<line x1="$left" y1="$top" x2="$left" y2="$bottom" stroke="#547188" stroke-width="1.2"/>',
          )
          ..write(
            '<line x1="$left" y1="$bottom" x2="$right" y2="$bottom" stroke="#547188" stroke-width="1.2"/>',
          );
    if (calculation.ratioAverage != null) {
      final y = sy(calculation.ratioAverage!);
      buffer.write(
        '<line x1="$left" y1="${_number(y)}" x2="$right" y2="${_number(y)}" stroke="#B98327" stroke-width="1.3" stroke-dasharray="5 4"/>',
      );
    }
    if (values.length > 1) {
      buffer.write(
        '<polyline points="${values.map((row) => '${_number(sx(row.index))},${_number(sy(row.ratio!))}').join(' ')}" fill="none" stroke="#1976A5" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>',
      );
    }
    for (final row in values) {
      buffer.write(
        '<circle cx="${_number(sx(row.index))}" cy="${_number(sy(row.ratio!))}" r="4" fill="#1976A5" stroke="#FFFFFF" stroke-width="1.2"/>',
      );
    }
    buffer
      ..write(
        '<text x="$left" y="${top - 14}" fill="#58748A" font-family="NotoSansSCPdf" font-size="15" font-style="italic">C</text>',
      )
      ..write(
        '<text x="$right" y="${bottom + 31}" text-anchor="end" fill="#58748A" font-family="NotoSansSCPdf" font-size="12">测点</text>',
      )
      ..write(
        '<text x="${left - 9}" y="${bottom + 18}" text-anchor="end" fill="#58748A" font-family="NotoSansSCPdf" font-size="12">${_xml(ElectrostaticFieldCalculator.format(bounds.low))}</text>',
      )
      ..write(
        '<text x="${left - 9}" y="${top + 5}" text-anchor="end" fill="#58748A" font-family="NotoSansSCPdf" font-size="12">${_xml(ElectrostaticFieldCalculator.format(bounds.high))}</text>',
      );
    for (var index = 0; index < ElectrostaticFieldState.pointCount; index++) {
      buffer.write(
        '<text x="${_number(sx(index))}" y="${bottom + 18}" text-anchor="middle" fill="#58748A" font-family="NotoSansSCPdf" font-size="12">${index + 1}</text>',
      );
    }
    buffer.write('</svg>');
    return buffer.toString();
  }

  static String _number(double value) {
    final output = value.toStringAsFixed(4);
    return output == '-0.0000' ? '0' : output;
  }

  static String _colorHex(int index) => switch (index % _lineColors.length) {
    0 => '#1A7FB4',
    1 => '#9D5C18',
    2 => '#3A8A5B',
    3 => '#9B3E51',
    _ => '#7058A7',
  };

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
