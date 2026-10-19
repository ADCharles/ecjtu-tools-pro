// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_galvanometer_page.dart';

Widget _galvanometerSection({
  required bool dark,
  required Widget title,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD)),
      ),
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: physicsCardShadow(dark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, const SizedBox(height: 12), child],
    ),
  );
}

class _GalvanometerFormulaBlock extends StatelessWidget {
  const _GalvanometerFormulaBlock({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    const formulas = [
      r'R_g=\frac{U_xR_{x+1}-U_{x+1}R_x}{U_{x+1}-U_x}',
      r'\overline{R_g}=\frac{1}{5}\sum_{i=1}^{5}R_{g,i},\qquad \Delta R_g=\frac{1}{5}\sum_{i=1}^{5}|R_{g,i}-\overline{R_g}|',
      r'I_g=\frac{10^6 U R_b}{R_a(\overline{R_g}+R_c)}\ \mu\mathrm{A}',
      r'K_i=\frac{I_g}{d_i},\qquad S_i=\frac{1}{K_i}',
      r'\overline{S}=\frac{1}{6}\sum_{i=1}^{6}S_i,\qquad \Delta S=\frac{1}{5}\sum_{i=1}^{5}|S_i-\overline{S}|',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF14263A) : const Color(0xFFF1F7FB),
        border: Border(
          left: BorderSide(
            color: dark ? const Color(0xFF6DA8D0) : const Color(0xFF6DA8D0),
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '计算公式',
            style: TextStyle(
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
              ),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          for (var index = 0; index < formulas.length; index++)
            _GalvanometerFormulaLine(
              number: '${index + 1}.',
              formula: formulas[index],
              dark: dark,
            ),
        ],
      ),
    );
  }
}

class _GalvanometerFormulaLine extends StatelessWidget {
  const _GalvanometerFormulaLine({
    required this.number,
    required this.formula,
    required this.dark,
  });

  final String number;
  final String formula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: TextStyle(
                color: EcjtuColors.platformText(
                  dark,
                  (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
                ),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _galvanometerMath(
              formula,
              dark,
              fontSize: 15,
              mathStyle: MathStyle.display,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _galvanometerSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _galvanometerTableHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _galvanometerTableCellStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.2,
);

Widget _galvanometerMath(
  String formula,
  bool dark, {
  double fontSize = 13,
  FontWeight? weight,
  Color? color,
  MathStyle mathStyle = MathStyle.text,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: mathStyle,
      textStyle: TextStyle(
        color:
            color ??
            (EcjtuColors.platformText(
              dark,
              (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
            )),
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.3,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

Widget _galvanometerInlineMath(
  String formula,
  bool dark, {
  double fontSize = 11,
  FontWeight? weight,
  Color? color,
}) {
  return Math.tex(
    formula,
    mathStyle: MathStyle.text,
    textStyle: TextStyle(
      color:
          color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
      fontSize: fontSize,
      fontWeight: weight,
      height: 1.2,
    ),
    onErrorFallback: (_) => const SizedBox.shrink(),
  );
}

Widget _galvanometerMixedText({
  required String prefix,
  required String formula,
  required bool dark,
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w700,
  Color? textColor,
  Color? mathColor,
  bool wrap = true,
}) {
  return _galvanometerMixedParts(
    dark: dark,
    fontSize: fontSize,
    fontWeight: fontWeight,
    textColor: textColor,
    mathColor: mathColor,
    wrap: wrap,
    parts: [prefix, _GalvanometerMathPart(formula)],
  );
}

Widget _galvanometerMixedParts({
  required List<Object> parts,
  required bool dark,
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.w700,
  Color? textColor,
  Color? mathColor,
  bool wrap = true,
}) {
  final resolvedTextColor =
      textColor ??
      (EcjtuColors.platformText(
        dark,
        (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
      ));
  final resolvedMathColor = mathColor ?? resolvedTextColor;
  final children = <Widget>[
    for (final part in parts)
      if (part is String)
        Text(
          part,
          style: _galvanometerSectionTitleStyle(dark).copyWith(
            color: resolvedTextColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        )
      else if (part is _GalvanometerMathPart)
        _galvanometerInlineMath(
          part.formula,
          dark,
          fontSize: fontSize,
          weight: fontWeight,
          color: resolvedMathColor,
        ),
  ];
  if (!wrap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

class _GalvanometerMathPart {
  const _GalvanometerMathPart(this.formula);

  final String formula;
}

Widget _buildResistanceInputTable({
  required GalvanometerState state,
  required bool dark,
  required void Function(int, String, String) onChanged,
}) {
  const labelWidth = 116.0;
  const valueWidth = 86.0;
  final tableWidth = labelWidth + valueWidth * 10;
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : Colors.white),
      ),
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _galvanometerGridCell(
                    width: labelWidth,
                    height: 68,
                    dark: dark,
                    header: true,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '数据项',
                      style: _galvanometerTableHeaderStyle(dark),
                    ),
                  ),
                  for (
                    var index = 0;
                    index < GalvanometerState.resistanceCount;
                    index++
                  )
                    SizedBox(
                      width: valueWidth * 2,
                      height: 68,
                      child: Column(
                        children: [
                          _galvanometerGridCell(
                            width: valueWidth * 2,
                            height: 34,
                            dark: dark,
                            header: true,
                            child: Text(
                              '第 ${index + 1} 组',
                              style: _galvanometerTableHeaderStyle(dark),
                            ),
                          ),
                          Row(
                            children: [
                              _galvanometerGridCell(
                                width: valueWidth,
                                height: 34,
                                dark: dark,
                                header: true,
                                child: _galvanometerInlineMath(
                                  'x',
                                  dark,
                                  fontSize: 11.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              _galvanometerGridCell(
                                width: valueWidth,
                                height: 34,
                                dark: dark,
                                header: true,
                                child: _galvanometerInlineMath(
                                  'x+1',
                                  dark,
                                  fontSize: 11.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _galvanometerResistanceInputRow(
              label: '电压 ',
              formula: r'U\,/\,\mathrm{V}',
              values: state.resistance,
              lowField: 'uLow',
              highField: 'uHigh',
              labelWidth: labelWidth,
              valueWidth: valueWidth,
              dark: dark,
              onChanged: onChanged,
            ),
            _galvanometerResistanceInputRow(
              label: '电阻 ',
              formula: r'R_0\,/\,\Omega',
              values: state.resistance,
              lowField: 'rLow',
              highField: 'rHigh',
              labelWidth: labelWidth,
              valueWidth: valueWidth,
              dark: dark,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _galvanometerResistanceInputRow({
  required String label,
  required String formula,
  required List<GalvanometerResistanceInput> values,
  required String lowField,
  required String highField,
  required double labelWidth,
  required double valueWidth,
  required bool dark,
  required void Function(int, String, String) onChanged,
}) {
  return SizedBox(
    height: 34,
    child: Row(
      children: [
        _galvanometerGridCell(
          width: labelWidth,
          height: 34,
          dark: dark,
          rowLabel: true,
          alignment: Alignment.centerLeft,
          child: _galvanometerMixedText(
            prefix: label,
            formula: formula,
            dark: dark,
            fontSize: 12,
            fontWeight: FontWeight.normal,
            textColor: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
            mathColor: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
            wrap: false,
          ),
        ),
        for (
          var index = 0;
          index < GalvanometerState.resistanceCount;
          index++
        ) ...[
          _galvanometerInputGridCell(
            width: valueWidth,
            value: _resistanceValue(values, index, lowField),
            label: '$label第 ${index + 1} 组前项',
            dark: dark,
            key: 'galvanometer-resistance-$index-$lowField',
            onChanged: (value) => onChanged(index, lowField, value),
          ),
          _galvanometerInputGridCell(
            width: valueWidth,
            value: _resistanceValue(values, index, highField),
            label: '$label第 ${index + 1} 组后项',
            dark: dark,
            key: 'galvanometer-resistance-$index-$highField',
            onChanged: (value) => onChanged(index, highField, value),
          ),
        ],
      ],
    ),
  );
}

String _resistanceValue(
  List<GalvanometerResistanceInput> values,
  int index,
  String field,
) {
  if (index >= values.length) return '';
  final source = values[index];
  return switch (field) {
    'uLow' => source.uLow,
    'rLow' => source.rLow,
    'uHigh' => source.uHigh,
    'rHigh' => source.rHigh,
    _ => '',
  };
}

Widget _buildSensitivityInputTable({
  required GalvanometerState state,
  required bool dark,
  required void Function(int, String, String) onChanged,
}) {
  const labelWidth = 116.0;
  const intrinsicValueWidth = 86.0;
  const minimumTableWidth = 720.0;
  final intrinsicTableWidth =
      labelWidth + intrinsicValueWidth * GalvanometerState.sensitivityCount;
  final tableWidth = intrinsicTableWidth < minimumTableWidth
      ? minimumTableWidth
      : intrinsicTableWidth;
  final valueWidth =
      (tableWidth - labelWidth) / GalvanometerState.sensitivityCount;
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : Colors.white),
      ),
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  _galvanometerGridCell(
                    width: labelWidth,
                    height: 34,
                    dark: dark,
                    header: true,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '数据项',
                      style: _galvanometerTableHeaderStyle(dark),
                    ),
                  ),
                  for (
                    var index = 0;
                    index < GalvanometerState.sensitivityCount;
                    index++
                  )
                    _galvanometerGridCell(
                      width: valueWidth,
                      height: 34,
                      dark: dark,
                      header: true,
                      child: Text(
                        '${index + 1}',
                        style: _galvanometerTableHeaderStyle(dark),
                      ),
                    ),
                ],
              ),
            ),
            _galvanometerSensitivityInputRow(
              label: '电压 ',
              formula: r'U\,/\,\mathrm{V}',
              values: state.sensitivity,
              field: 'u',
              labelWidth: labelWidth,
              valueWidth: valueWidth,
              dark: dark,
              onChanged: onChanged,
            ),
            _galvanometerSensitivityInputRow(
              label: '偏移 ',
              formula: r'd\,/\,\mathrm{mm}',
              values: state.sensitivity,
              field: 'd',
              labelWidth: labelWidth,
              valueWidth: valueWidth,
              dark: dark,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _galvanometerSensitivityInputRow({
  required String label,
  required String formula,
  required List<GalvanometerSensitivityInput> values,
  required String field,
  required double labelWidth,
  required double valueWidth,
  required bool dark,
  required void Function(int, String, String) onChanged,
}) {
  return SizedBox(
    height: 34,
    child: Row(
      children: [
        _galvanometerGridCell(
          width: labelWidth,
          height: 34,
          dark: dark,
          rowLabel: true,
          alignment: Alignment.centerLeft,
          child: _galvanometerMixedText(
            prefix: label,
            formula: formula,
            dark: dark,
            fontSize: 12,
            fontWeight: FontWeight.normal,
            textColor: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
            mathColor: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
          ),
        ),
        for (var index = 0; index < GalvanometerState.sensitivityCount; index++)
          _galvanometerInputGridCell(
            width: valueWidth,
            value: index < values.length
                ? (field == 'u' ? values[index].u : values[index].d)
                : '',
            label: '$label第 ${index + 1} 次',
            dark: dark,
            key: 'galvanometer-sensitivity-$index-$field',
            onChanged: (value) => onChanged(index, field, value),
          ),
      ],
    ),
  );
}

Widget _galvanometerGridCell({
  required double width,
  required double height,
  required bool dark,
  required Widget child,
  bool header = false,
  bool rowLabel = false,
  Alignment alignment = Alignment.center,
}) {
  return Container(
    width: width,
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    alignment: alignment,
    decoration: BoxDecoration(
      color: header
          ? (dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA))
          : rowLabel
          ? (dark ? const Color(0xFF12263A) : const Color(0xFFF8FBFD))
          : (EcjtuColors.platformSurface(
              dark,
              (dark ? const Color(0xFF101D31) : Colors.white),
            )),
      border: Border(
        right: BorderSide(
          color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
        ),
        bottom: BorderSide(
          color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
        ),
      ),
    ),
    child: child,
  );
}

Widget _galvanometerInputGridCell({
  required double width,
  required String value,
  required String label,
  required bool dark,
  required String key,
  required ValueChanged<String> onChanged,
}) {
  return _galvanometerGridCell(
    width: width,
    height: 34,
    dark: dark,
    child: _GalvanometerTextField(
      key: ValueKey<String>(key),
      value: value,
      label: label,
      dark: dark,
      compact: true,
      onChanged: onChanged,
    ),
  );
}

class _GalvanometerLabeledInput extends StatelessWidget {
  const _GalvanometerLabeledInput({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.placeholder,
    required this.label,
    required this.dark,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String value;
  final String placeholder;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _galvanometerMixedText(
          prefix: prefix,
          formula: formula,
          dark: dark,
          fontSize: 11,
          fontWeight: FontWeight.normal,
          textColor: EcjtuColors.platformMuted(
            dark,
            (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
          ),
          mathColor: EcjtuColors.platformMuted(
            dark,
            (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
          ),
          wrap: false,
        ),
        const SizedBox(height: 5),
        _GalvanometerTextField(
          value: value,
          placeholder: placeholder,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget _buildResistanceResults(bool dark) {
  return Builder(
    builder: (context) {
      final page = context
          .findAncestorStateOfType<_PhysicsGalvanometerPageState>()!;
      final result = page._calculation.resistance;
      final rows = result.rows
          .map(
            (row) => [
              _galvanometerOutputText('${row.index + 1}', dark, first: true),
              _galvanometerOutputText(row.uLow.isEmpty ? '—' : row.uLow, dark),
              _galvanometerOutputText(row.rLow.isEmpty ? '—' : row.rLow, dark),
              _galvanometerOutputText(
                row.uHigh.isEmpty ? '—' : row.uHigh,
                dark,
              ),
              _galvanometerOutputText(
                row.rHigh.isEmpty ? '—' : row.rHigh,
                dark,
              ),
              _galvanometerOutputText(row.rg ?? '—', dark),
            ],
          )
          .toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _galvanometerMixedText(
            prefix: '表二：测定电流计内阻 ',
            formula: r'R_g',
            dark: dark,
            fontSize: 13,
          ),
          const SizedBox(height: 10),
          _galvanometerOutputTable(
            dark: dark,
            headers: [
              const _GalvanometerHeader.plain('组数'),
              const _GalvanometerHeader.math(r'U_x\,/\,\mathrm{V}', '电压 '),
              const _GalvanometerHeader.math(r'R_x\,/\,\Omega', '电阻 '),
              const _GalvanometerHeader.math(r'U_{x+1}\,/\,\mathrm{V}', '电压 '),
              const _GalvanometerHeader.math(r'R_{x+1}\,/\,\Omega', '电阻 '),
              const _GalvanometerHeader.math(r'R_g\,/\,\Omega', '内阻 '),
            ],
            rows: rows,
          ),
          if (!result.complete) ...[
            const SizedBox(height: 7),
            _galvanometerError(result.message ?? '当前数据还不能完成计算', dark),
          ] else ...[
            const SizedBox(height: 9),
            _galvanometerSummaryLine(
              label: '内阻平均值 ',
              formula: r'\overline{R_g}',
              value: result.average!,
              unit: r'\Omega',
              dark: dark,
            ),
            _galvanometerSummaryLine(
              label: '内阻平均绝对偏差 ',
              formula: r'\Delta R_g',
              value: result.averageAbsoluteDeviation!,
              unit: r'\Omega',
              dark: dark,
            ),
            _galvanometerFormulaSummary(
              r'R_g=' +
                  result.average! +
                  r'\,\pm\,' +
                  result.averageAbsoluteDeviation! +
                  r'\,\Omega',
              dark,
            ),
          ],
        ],
      );
    },
  );
}

Widget _buildSensitivityResults(bool dark) {
  return Builder(
    builder: (context) {
      final page = context
          .findAncestorStateOfType<_PhysicsGalvanometerPageState>()!;
      final result = page._calculation.sensitivity;
      final rows = result.rows
          .map(
            (row) => [
              _galvanometerOutputText('${row.index + 1}', dark, first: true),
              _galvanometerOutputText(row.u.isEmpty ? '—' : row.u, dark),
              _galvanometerOutputText(row.d.isEmpty ? '—' : row.d, dark),
              _galvanometerOutputText(row.currentMicroAmp ?? '—', dark),
              _galvanometerOutputText(row.constant ?? '—', dark),
              _galvanometerOutputText(row.sensitivity ?? '—', dark),
              _galvanometerOutputText(row.deviation ?? '—', dark),
            ],
          )
          .toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _galvanometerMixedParts(
            dark: dark,
            fontSize: 13,
            parts: const [
              '表三：测定电流计常量 ',
              _GalvanometerMathPart(r'K_i'),
              ' 及 ',
              _GalvanometerMathPart(r'S_i'),
            ],
          ),
          const SizedBox(height: 10),
          _galvanometerOutputTable(
            dark: dark,
            headers: [
              const _GalvanometerHeader.plain('次数'),
              const _GalvanometerHeader.math(r'U\,/\,\mathrm{V}', '电压 '),
              const _GalvanometerHeader.math(r'd\,/\,\mathrm{mm}', '偏移 '),
              const _GalvanometerHeader.math(r'I_g\,/\,\mu\mathrm{A}', '电流 '),
              const _GalvanometerHeader.math(
                r'K_i\,/\,(\mu\mathrm{A}/\mathrm{mm})',
                '电流计常量 ',
              ),
              const _GalvanometerHeader.math(
                r'S_i\,/\,(\mathrm{mm}/\mu\mathrm{A})',
                '灵敏度 ',
              ),
              const _GalvanometerHeader.math(
                r'S_i-\overline{S}\,/\,(\mathrm{mm}/\mu\mathrm{A})',
                '灵敏度偏差 ',
              ),
            ],
            rows: rows,
          ),
          if (!result.complete) ...[
            const SizedBox(height: 7),
            _galvanometerError(result.message ?? '当前数据还不能完成计算', dark),
          ] else ...[
            const SizedBox(height: 9),
            _galvanometerSummaryLine(
              label: '电流平均值 ',
              formula: r'\overline{I_g}',
              value: result.averageCurrent!,
              unit: r'\mu\mathrm{A}',
              dark: dark,
            ),
            _galvanometerSummaryLine(
              label: '电流计常量平均值 ',
              formula: r'\overline{K_i}',
              value: result.averageConstant!,
              unit: r'\mu\mathrm{A}/\mathrm{mm}',
              dark: dark,
            ),
            _galvanometerSummaryLine(
              label: '灵敏度平均值 ',
              formula: r'\overline{S}',
              value: result.averageSensitivity!,
              unit: r'\mathrm{mm}/\mu\mathrm{A}',
              dark: dark,
            ),
            _galvanometerSummaryLine(
              label: '灵敏度平均绝对偏差 ',
              formula: r'\Delta S',
              value: result.averageAbsoluteDeviation!,
              unit: r'\mathrm{mm}/\mu\mathrm{A}',
              dark: dark,
            ),
            _galvanometerFormulaSummary(
              r'S=' +
                  result.averageSensitivity! +
                  r'\,\pm\,' +
                  result.averageAbsoluteDeviation! +
                  r'\,\mathrm{mm}/\mu\mathrm{A}',
              dark,
            ),
          ],
        ],
      );
    },
  );
}

class _GalvanometerHeader {
  const _GalvanometerHeader.plain(this.text) : formula = null, prefix = '';

  const _GalvanometerHeader.math(this.formula, this.prefix) : text = '';

  final String text;
  final String? formula;
  final String prefix;
}

Widget _galvanometerOutputTable({
  required bool dark,
  required List<_GalvanometerHeader> headers,
  required List<List<Widget>> rows,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final tableWidth =
          constraints.hasBoundedWidth && constraints.maxWidth > 620
          ? constraints.maxWidth
          : 620.0;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: tableWidth,
          decoration: BoxDecoration(
            border: Border.all(
              color: EcjtuColors.platformBorder(
                dark,
                (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
              ),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(116),
              for (var index = 1; index < headers.length; index++)
                index: const FlexColumnWidth(),
            },
            border: TableBorder.all(
              color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
              width: .8,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF14263A)
                      : const Color(0xFFEEF6FA),
                ),
                children: [
                  for (var index = 0; index < headers.length; index++)
                    _galvanometerOutputHeaderCell(
                      headers[index],
                      dark,
                      index == 0,
                    ),
                ],
              ),
              for (final row in rows)
                TableRow(
                  decoration: BoxDecoration(
                    color: EcjtuColors.platformSurface(
                      dark,
                      (dark ? const Color(0xFF101D31) : Colors.white),
                    ),
                  ),
                  children: row,
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _galvanometerOutputHeaderCell(
  _GalvanometerHeader header,
  bool dark,
  bool first,
) {
  return Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: first ? Alignment.centerLeft : Alignment.centerRight,
    child: header.formula == null
        ? Text(header.text, style: _galvanometerTableHeaderStyle(dark))
        : _galvanometerMixedParts(
            dark: dark,
            fontSize: 12,
            textColor: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
            mathColor: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
            wrap: false,
            parts: [header.prefix, _GalvanometerMathPart(header.formula!)],
          ),
  );
}

Widget _galvanometerOutputText(String value, bool dark, {bool first = false}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: first ? Alignment.centerLeft : Alignment.centerRight,
    child: Text(value, style: _galvanometerTableCellStyle(dark)),
  );
}

Widget _galvanometerSummaryLine({
  required String label,
  required String formula,
  required String value,
  required String unit,
  required bool dark,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final labelWidget = _galvanometerMixedParts(
          dark: dark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          textColor: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
          mathColor: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
          parts: [label, _GalvanometerMathPart(formula)],
        );
        final valueWidget = _galvanometerMath(
          '$value\\,$unit',
          dark,
          fontSize: 13,
          weight: FontWeight.w800,
          color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 2), valueWidget],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: labelWidget,
            ),
            Expanded(child: valueWidget),
          ],
        );
      },
    ),
  );
}

Widget _galvanometerFormulaSummary(String formula, bool dark) {
  return Padding(
    padding: const EdgeInsets.only(top: 3),
    child: _galvanometerMath(
      formula,
      dark,
      fontSize: 13,
      weight: FontWeight.w800,
      color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
    ),
  );
}

Widget _galvanometerError(String message, bool dark) {
  return Text(
    message,
    style: TextStyle(
      color: dark ? const Color(0xFFFF9B91) : const Color(0xFFB4533F),
      fontSize: 11,
      height: 1.5,
    ),
  );
}

class _GalvanometerTextField extends StatefulWidget {
  const _GalvanometerTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
    this.compact = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool compact;

  @override
  State<_GalvanometerTextField> createState() => _GalvanometerTextFieldState();
}

class _GalvanometerTextFieldState extends State<_GalvanometerTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _GalvanometerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 29.0 : 34.0;
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: widget.dark
                ? const Color(0xFFE1EDFF)
                : const Color(0xFF223549),
            fontSize: 12,
            height: 1.1,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: widget.dark
                  ? const Color(0xFF7891A7)
                  : const Color(0xFF9AAEBC),
              fontSize: 11,
            ),
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 8,
              vertical: widget.compact ? 4 : 6,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.compact ? 5 : 6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.compact ? 5 : 6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF9DDCFF)
                    : const Color(0xFF287AA8),
              ),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}
