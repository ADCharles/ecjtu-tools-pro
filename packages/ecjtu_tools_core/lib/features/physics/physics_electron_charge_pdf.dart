// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'physics_component_pdf.dart';

import 'physics_electron_charge_chart.dart';
import 'physics_electron_charge_models.dart';
import 'physics_pdf_fonts.dart';

class ElectronChargePdfService {
  const ElectronChargePdfService._();

  static Future<void> shareChart(ElectronChargeDeflectionResult result) async {
    if (!result.hasChart) throw StateError('当前图表没有可下载的数据。');
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildChartPdf(result),
      filename: '${_title(result)}-趋势图.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<void> shareAll(ElectronChargeCalculation calculation) async {
    final opened = await PhysicsComponentPdf.sharePdf(
      bytes: await buildAllPdf(calculation),
      filename: '电子比荷的测量-趋势图.pdf',
    );
    if (!opened) throw StateError('PDF 文件未能打开。');
  }

  static Future<Uint8List> buildChartPdf(
    ElectronChargeDeflectionResult result,
  ) async {
    if (!result.hasChart) throw StateError('当前图表没有可下载的数据。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    document.addPage(_chartPage(result, fonts));
    return document.save();
  }

  static Future<Uint8List> buildAllPdf(
    ElectronChargeCalculation calculation,
  ) async {
    final charts = <ElectronChargeDeflectionResult>[
      ...calculation.electric,
      ...calculation.magnetic,
    ].where((result) => result.hasChart).toList(growable: false);
    if (charts.isEmpty) throw StateError('当前没有可下载的趋势图。');
    final fonts = await _loadFonts();
    final document = _document(fonts);
    for (final result in charts) {
      document.addPage(_chartPage(result, fonts));
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
    ElectronChargeDeflectionResult result,
    _PdfFonts fonts,
  ) {
    final points = result.fit.valid;
    return pw.Page(
      pageFormat: const PdfPageFormat(595.28, 841.89),
      margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _titleFormula(
            result,
            fonts: fonts,
            fontSize: 16,
            color: PdfColors.blueGrey800,
          ),
          pw.SizedBox(height: 10),
          pw.SvgImage(
            svg: ElectronChargeChartSvg.build(result),
            width: 500,
            height: 307.7,
            customFontLookup: (family, style, weight) => lookupPhysicsSvgFont(
              family: family,
              style: style,
              weight: weight,
              regular: fonts.regular,
              bold: fonts.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          if (result.fit.complete)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('趋势线方程：', style: _bodyStyle(fonts)),
                _equationFormula(result, fonts),
              ],
            )
          else
            pw.Text(result.fit.error ?? '趋势线未生成', style: _bodyStyle(fonts)),
          pw.SizedBox(height: 5),
          pw.Text('有效数据：${points.length} 组', style: _bodyStyle(fonts)),
          pw.SizedBox(height: 12),
          _dataTable(result, fonts),
        ],
      ),
    );
  }

  static pw.Widget _dataTable(
    ElectronChargeDeflectionResult result,
    _PdfFonts fonts,
  ) {
    final headerStyle = pw.TextStyle(
      font: fonts.bold,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );
    final cellStyle = pw.TextStyle(font: fonts.regular, fontSize: 9);
    return pw.Table(
      border: pw.TableBorder.all(width: .6),
      columnWidths: const {
        0: pw.FixedColumnWidth(46),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            _tableCell(pw.Text('组数', style: headerStyle)),
            _tableCell(
              _axisFormula(
                result.definition.xSymbol,
                result.definition.xUnit,
                headerStyle,
                fonts.bold,
              ),
            ),
            _tableCell(
              _axisFormula(
                result.definition.ySymbol,
                result.definition.yUnit,
                headerStyle,
                fonts.bold,
              ),
            ),
            _tableCell(_ratioFormula(result, headerStyle, fonts.bold)),
          ],
        ),
        ...result.points.map(
          (point) => pw.TableRow(
            children: [
              _tableCell(pw.Text('${point.index + 1}', style: cellStyle)),
              _tableCell(pw.Text(point.x?.format() ?? '-', style: cellStyle)),
              _tableCell(pw.Text(point.y?.format() ?? '-', style: cellStyle)),
              _tableCell(
                pw.Text(point.ratio?.format() ?? '-', style: cellStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(pw.Widget child) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(child: child),
    );
  }

  static pw.Widget _titleFormula(
    ElectronChargeDeflectionResult result, {
    required _PdfFonts fonts,
    required double fontSize,
    required PdfColor color,
  }) {
    final voltage = _voltage(result);
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
        children: [
          pw.TextSpan(text: result.definition.titlePrefix),
          pw.TextSpan(text: 'U'),
          _subscript('2', fontSize, fonts.bold),
          pw.TextSpan(text: ' = $voltage V'),
        ],
      ),
    );
  }

  static pw.Widget _equationFormula(
    ElectronChargeDeflectionResult result,
    _PdfFonts fonts,
  ) {
    final fontSize = 10.5;
    final intercept = result.fit.intercept!;
    final interceptText = intercept.format();
    final visibleIntercept = !intercept.isZero;
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(font: fonts.regular, fontSize: fontSize),
        children: [
          pw.TextSpan(text: result.definition.ySymbol),
          pw.TextSpan(text: ' = ${result.fit.slope!.format()} '),
          ..._symbolSpans(result.definition.xSymbol, fontSize, fonts.regular),
          if (visibleIntercept)
            pw.TextSpan(
              text: interceptText.startsWith('-')
                  ? ' - ${interceptText.substring(1)}'
                  : ' + $interceptText',
            ),
        ],
      ),
    );
  }

  static pw.Widget _axisFormula(
    String symbol,
    String unit,
    pw.TextStyle style,
    pw.Font font,
  ) {
    final fontSize = style.fontSize ?? 9;
    return pw.RichText(
      text: pw.TextSpan(
        style: style,
        children: [
          ..._symbolSpans(symbol, fontSize, font),
          pw.TextSpan(text: ' / $unit'),
        ],
      ),
    );
  }

  static pw.Widget _ratioFormula(
    ElectronChargeDeflectionResult result,
    pw.TextStyle style,
    pw.Font font,
  ) {
    final fontSize = style.fontSize ?? 9;
    return pw.RichText(
      text: pw.TextSpan(
        style: style,
        children: [
          const pw.TextSpan(text: 'D / '),
          ..._symbolSpans(result.definition.xSymbol, fontSize, font),
        ],
      ),
    );
  }

  static List<pw.InlineSpan> _symbolSpans(
    String symbol,
    double fontSize,
    pw.Font font,
  ) {
    if (symbol == 'U_d') {
      return [pw.TextSpan(text: 'U'), _subscript('d', fontSize, font)];
    }
    return [pw.TextSpan(text: symbol)];
  }

  static pw.TextSpan _subscript(String text, double fontSize, pw.Font font) {
    return pw.TextSpan(
      text: text,
      baseline: -fontSize * .22,
      style: pw.TextStyle(font: font, fontSize: fontSize * .7),
    );
  }

  static pw.TextStyle _bodyStyle(_PdfFonts fonts) {
    return pw.TextStyle(font: fonts.regular, fontSize: 10.5);
  }

  static String _voltage(ElectronChargeDeflectionResult result) {
    final pieces = result.definition.id.split('-');
    return pieces.length > 1 ? pieces.last : '';
  }

  static String _title(ElectronChargeDeflectionResult result) {
    return '${result.definition.titlePrefix}U2 = ${_voltage(result)} V';
  }
}

class _PdfFonts {
  const _PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
