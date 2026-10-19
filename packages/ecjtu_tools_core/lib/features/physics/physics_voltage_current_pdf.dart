// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'physics_component_pdf.dart';

import 'physics_voltage_current_chart.dart';
import 'physics_voltage_current_models.dart';
import 'physics_pdf_fonts.dart';

class VoltageCurrentPdfService {
  const VoltageCurrentPdfService._();

  static Future<void> shareChart({
    required String title,
    required List<VoltageCurrentChartPoint> points,
    required String colorHex,
  }) async {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildChartPdf(
        title: title,
        points: points,
        colorHex: colorHex,
      ),
      filename: '$title.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<void> shareAll(VoltageCurrentCalculation calculation) async {
    final entries = _entries(calculation);
    if (entries.isEmpty) throw StateError('当前没有可下载的图表。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildAllPdf(calculation),
      filename: '电学元件伏安特性的研究-报告图.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<Uint8List> buildChartPdf({
    required String title,
    required List<VoltageCurrentChartPoint> points,
    required String colorHex,
  }) async {
    if (points.isEmpty) throw StateError('当前图表没有可下载的数据。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    document.addPage(_chartPage(title, points, colorHex, fonts));
    return document.save();
  }

  static Future<Uint8List> buildAllPdf(
    VoltageCurrentCalculation calculation,
  ) async {
    final entries = _entries(calculation);
    if (entries.isEmpty) throw StateError('当前没有可下载的图表。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    for (final entry in entries) {
      document.addPage(
        _chartPage(entry.title, entry.points, entry.colorHex, fonts),
      );
    }
    return document.save();
  }

  static Future<_PdfFonts> _loadFonts() async {
    final regular = pw.Font.ttf(
      await rootBundle.load(
        'packages/ecjtu_tools_core/assets/fonts/NotoSansSC-Regular.ttf',
      ),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load(
        'packages/ecjtu_tools_core/assets/fonts/NotoSansSC-Bold.ttf',
      ),
    );
    return _PdfFonts(regular: regular, bold: bold);
  }

  static pw.Document _document(_PdfFonts fonts) {
    return pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    );
  }

  static pw.Page _chartPage(
    String title,
    List<VoltageCurrentChartPoint> points,
    String colorHex,
    _PdfFonts fonts,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF275B7A),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.SvgImage(
            svg: VoltageCurrentChartSvg.build(points, colorHex),
            width: 500,
            height: 346.15,
            customFontLookup: (family, style, weight) => lookupPhysicsSvgFont(
              family: family,
              style: style,
              weight: weight,
              regular: fonts.regular,
              bold: fonts.bold,
            ),
          ),
        ],
      ),
    );
  }

  static List<_VoltageCurrentPdfEntry> _entries(
    VoltageCurrentCalculation calculation,
  ) {
    final entries = <_VoltageCurrentPdfEntry>[];
    for (var index = 0; index < calculation.blocks.length; index++) {
      final block = calculation.blocks[index];
      final points = voltageCurrentLinearChartPoints(block);
      if (points.isEmpty) continue;
      entries.add(
        _VoltageCurrentPdfEntry(
          title: '${block.resistance} Ω 电阻 · 电流表${block.connection}法',
          points: points,
          colorHex: voltageCurrentChartColorHexes[index],
        ),
      );
    }
    final diodePoints = voltageCurrentDiodeChartPoints(calculation.diode);
    if (diodePoints.isNotEmpty) {
      entries.add(
        _VoltageCurrentPdfEntry(
          title: '半导体二极管正向伏安特性',
          points: diodePoints,
          colorHex: voltageCurrentChartColorHexes[4],
        ),
      );
    }
    return entries;
  }
}

class _VoltageCurrentPdfEntry {
  const _VoltageCurrentPdfEntry({
    required this.title,
    required this.points,
    required this.colorHex,
  });

  final String title;
  final List<VoltageCurrentChartPoint> points;
  final String colorHex;
}

class _PdfFonts {
  const _PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
