// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'physics_component_pdf.dart';

import 'physics_electrostatic_field_chart.dart';
import 'physics_electrostatic_field_models.dart';
import 'physics_pdf_fonts.dart';

class ElectrostaticFieldPdfService {
  const ElectrostaticFieldPdfService._();

  static Future<void> shareChart(
    ElectrostaticFieldCalculation calculation,
    ElectrostaticChartKind kind,
  ) async {
    if (!_hasChart(calculation, kind)) {
      throw StateError('当前图表没有可下载的数据。');
    }
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildChartPdf(calculation, kind),
      filename: '${_title(kind)}.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<void> shareAll(
    ElectrostaticFieldCalculation calculation,
  ) async {
    final kinds = _availableKinds(calculation);
    if (kinds.isEmpty) throw StateError('当前没有可下载的图表。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildAllPdf(calculation),
      filename: '静电场的描绘-报告图.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<Uint8List> buildChartPdf(
    ElectrostaticFieldCalculation calculation,
    ElectrostaticChartKind kind,
  ) async {
    if (!_hasChart(calculation, kind)) {
      throw StateError('当前图表没有可下载的数据。');
    }
    final fonts = await _loadFonts();
    final document = _document(fonts);
    document.addPage(_chartPage(calculation, kind, fonts));
    return document.save();
  }

  static Future<Uint8List> buildAllPdf(
    ElectrostaticFieldCalculation calculation,
  ) async {
    final kinds = _availableKinds(calculation);
    if (kinds.isEmpty) throw StateError('当前没有可下载的图表。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    for (final kind in kinds) {
      document.addPage(_chartPage(calculation, kind, fonts));
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
    ElectrostaticFieldCalculation calculation,
    ElectrostaticChartKind kind,
    _PdfFonts fonts,
  ) {
    return pw.Page(
      margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _title(kind),
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF275B7A),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.SvgImage(
            svg: ElectrostaticChartSvg.build(kind, calculation),
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

  static List<ElectrostaticChartKind> _availableKinds(
    ElectrostaticFieldCalculation calculation,
  ) {
    return [
      if (calculation.hasCoaxialChart) ElectrostaticChartKind.coaxial,
      if (calculation.hasParallelChart) ElectrostaticChartKind.parallel,
    ];
  }

  static bool _hasChart(
    ElectrostaticFieldCalculation calculation,
    ElectrostaticChartKind kind,
  ) {
    return kind == ElectrostaticChartKind.coaxial
        ? calculation.hasCoaxialChart
        : calculation.hasParallelChart;
  }

  static String _title(ElectrostaticChartKind kind) =>
      kind == ElectrostaticChartKind.coaxial ? '同轴圆柱面等势线图' : '两平行导线距离比图';
}

class _PdfFonts {
  const _PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
