// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'physics_component_pdf.dart';

import 'physics_rigid_rotation_chart.dart';
import 'physics_rigid_rotation_models.dart';
import 'physics_pdf_fonts.dart';

class RigidRotationPdfService {
  const RigidRotationPdfService._();

  static Future<void> shareChart(RigidRotationChartSpec spec) async {
    if (!spec.hasData) throw StateError('当前图表没有可下载的数据。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildChartPdf(spec),
      filename: '${spec.title}.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<void> shareAll(RigidRotationCalculation calculation) async {
    final specs = rigidRotationChartSpecs(
      calculation,
    ).where((spec) => spec.hasData).toList(growable: false);
    if (specs.isEmpty) throw StateError('当前没有可下载的图表。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildAllPdf(calculation),
      filename: '刚体转动惯量-图表.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<Uint8List> buildChartPdf(RigidRotationChartSpec spec) async {
    if (!spec.hasData) throw StateError('当前图表没有可下载的数据。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    document.addPage(_chartPage(spec, fonts));
    return document.save();
  }

  static Future<Uint8List> buildAllPdf(
    RigidRotationCalculation calculation,
  ) async {
    final specs = rigidRotationChartSpecs(
      calculation,
    ).where((spec) => spec.hasData).toList(growable: false);
    if (specs.isEmpty) throw StateError('当前没有可下载的图表。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    for (final spec in specs) {
      document.addPage(_chartPage(spec, fonts));
    }
    return document.save();
  }

  static Future<_RigidRotationPdfFonts> _loadFonts() async {
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
    return _RigidRotationPdfFonts(regular: regular, bold: bold);
  }

  static pw.Document _document(_RigidRotationPdfFonts fonts) {
    return pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
    );
  }

  static pw.Page _chartPage(
    RigidRotationChartSpec spec,
    _RigidRotationPdfFonts fonts,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            spec.title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF275B7A),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.SvgImage(
            svg: RigidRotationChartSvg.build(spec),
            width: 500,
            height: 276.32,
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
}

class _RigidRotationPdfFonts {
  const _RigidRotationPdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
