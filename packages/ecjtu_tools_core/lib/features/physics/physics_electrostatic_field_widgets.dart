// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_electrostatic_field_page.dart';

Widget _electrostaticSection({
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

class _ElectrostaticFormulaBlock extends StatelessWidget {
  const _ElectrostaticFormulaBlock({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    const formulas = [
      r'\bar r=\frac{1}{8}\sum_{j=1}^{8}r_j',
      r'U_{\mathrm{理}}=U_a\frac{\ln(r_b/\bar r)}{\ln(r_b/r_a)}',
      r'\varepsilon=\left|\frac{U_{\mathrm{理}}-U_{\mathrm{测}}}{U_{\mathrm{理}}}\right|\times100\%',
      r'C_i=\frac{R_{1,i}}{R_{2,i}},\qquad\bar C=\frac{1}{8}\sum_{i=1}^{8}C_i',
      r'\sigma_C=\sqrt{\frac{\sum_{i=1}^{8}(C_i-\bar C)^2}{8-1}}',
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
            _ElectrostaticFormulaLine(
              number: '${index + 1}.',
              formula: formulas[index],
              dark: dark,
            ),
        ],
      ),
    );
  }
}

class _ElectrostaticFormulaLine extends StatelessWidget {
  const _ElectrostaticFormulaLine({
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
            child: _electrostaticMath(
              formula,
              dark,
              fontSize: 15,
              mathStyle: MathStyle.display,
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _electrostaticSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _electrostaticTableHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _electrostaticTableCellStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.2,
);

TextStyle _electrostaticTableRowHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF3D647D),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

Widget _electrostaticMath(
  String formula,
  bool dark, {
  double fontSize = 14,
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
            color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.3,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

Widget _electrostaticInlineMath(
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

Widget _electrostaticMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  double fontSize = 11,
  bool rowHeader = false,
}) {
  final textStyle = rowHeader
      ? _electrostaticTableRowHeaderStyle(dark)
      : _electrostaticTableCellStyle(dark);
  final color = rowHeader
      ? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF3D647D))
      : (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65));
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(prefix, style: textStyle),
      const SizedBox(width: 3),
      _electrostaticInlineMath(
        formula,
        dark,
        fontSize: rowHeader ? 12 : fontSize,
        weight: FontWeight.w700,
        color: color,
      ),
    ],
  );
}

class _ElectrostaticLabeledInput extends StatelessWidget {
  const _ElectrostaticLabeledInput({
    super.key,
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(prefix, style: _electrostaticParameterLabelStyle(dark)),
            const SizedBox(width: 4),
            _electrostaticInlineMath(
              formula,
              dark,
              fontSize: 11,
              weight: FontWeight.w700,
              color: _electrostaticParameterLabelColor(dark),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _ElectrostaticTextField(
          value: value,
          label: label,
          placeholder: placeholder,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

TextStyle _electrostaticParameterLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

Color _electrostaticParameterLabelColor(bool dark) => EcjtuColors.platformMuted(
  dark,
  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
);

class _ElectrostaticTextField extends StatefulWidget {
  const _ElectrostaticTextField({
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
    this.width,
    this.height = 34,
    this.borderRadius = 6,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsets contentPadding;

  @override
  State<_ElectrostaticTextField> createState() =>
      _ElectrostaticTextFieldState();
}

class _ElectrostaticTextFieldState extends State<_ElectrostaticTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ElectrostaticTextField oldWidget) {
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
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
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
            contentPadding: widget.contentPadding,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
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

Widget _electrostaticTable({
  required double minWidth,
  required Map<int, TableColumnWidth> columnWidths,
  required List<Widget> headers,
  required List<List<Widget>> rows,
  required bool dark,
}) {
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
        width: minWidth,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: columnWidths,
          border: TableBorder(
            horizontalInside: BorderSide(
              color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
            ),
            verticalInside: BorderSide(
              color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
            ),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA),
              ),
              children: headers,
            ),
            for (final row in rows) TableRow(children: row),
          ],
        ),
      ),
    ),
  );
}

Widget _electrostaticTableCell(Widget child, {Color? backgroundColor}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    alignment: Alignment.center,
    color: backgroundColor,
    child: child,
  );
}

Widget _electrostaticHeader(String text, bool dark) {
  return _electrostaticTableCell(
    Text(
      text,
      textAlign: TextAlign.center,
      style: _electrostaticTableHeaderStyle(dark),
    ),
  );
}

Widget _electrostaticHeaderMath(String label, String formula, bool dark) {
  return _electrostaticTableCell(
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              textAlign: TextAlign.center,
              style: _electrostaticTableHeaderStyle(dark),
            ),
          if (label.isNotEmpty) const SizedBox(width: 3),
          _electrostaticInlineMath(
            formula,
            dark,
            fontSize: 12,
            weight: FontWeight.w700,
            color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
          ),
        ],
      ),
    ),
  );
}

Widget _electrostaticTextCell(String text, bool dark) {
  return _electrostaticTableCell(
    Text(
      text,
      textAlign: TextAlign.center,
      style: _electrostaticTableCellStyle(dark),
    ),
  );
}

Widget _electrostaticRowHeaderText(String text, bool dark) {
  return _electrostaticRowHeader(
    Text(
      text,
      textAlign: TextAlign.center,
      style: _electrostaticTableRowHeaderStyle(dark),
    ),
    dark,
  );
}

Widget _electrostaticRowHeader(Widget child, bool dark) {
  return _electrostaticTableCell(
    child,
    backgroundColor: dark ? const Color(0xFF12263A) : const Color(0xFFF8FBFD),
  );
}

Widget _electrostaticInputCell({
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
  String placeholder = '',
}) {
  return _electrostaticTableCell(
    _ElectrostaticTextField(
      value: value,
      label: label,
      placeholder: placeholder,
      dark: dark,
      width: 70,
      height: 29,
      borderRadius: 5,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      onChanged: onChanged,
    ),
  );
}

class _ElectrostaticCoaxialInputTable extends StatelessWidget {
  const _ElectrostaticCoaxialInputTable({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final ElectrostaticFieldState state;
  final bool dark;
  final void Function(int line, int point, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(110),
    };
    for (var index = 1; index <= ElectrostaticFieldState.pointCount; index++) {
      columnWidths[index] = const FixedColumnWidth(80);
    }
    return _electrostaticTable(
      minWidth: 750,
      columnWidths: columnWidths,
      dark: dark,
      headers: [
        _electrostaticHeaderMath(
          'U测 / V',
          r'U_{\mathrm{测}}\,/\,\mathrm{V}',
          dark,
        ),
        for (var index = 0; index < ElectrostaticFieldState.pointCount; index++)
          _electrostaticHeaderMath('', 'r_${index + 1}', dark),
      ],
      rows: [
        for (
          var lineIndex = 0;
          lineIndex < ElectrostaticFieldState.lineCount;
          lineIndex++
        )
          [
            _electrostaticRowHeaderText('${lineIndex + 1}', dark),
            for (
              var pointIndex = 0;
              pointIndex < ElectrostaticFieldState.pointCount;
              pointIndex++
            )
              _electrostaticInputCell(
                value: state.coaxial[lineIndex].radii[pointIndex],
                label: '${lineIndex + 1} V 等势线第 ${pointIndex + 1} 个半径',
                dark: dark,
                onChanged: (value) => onChanged(lineIndex, pointIndex, value),
              ),
          ],
      ],
    );
  }
}

class _ElectrostaticParallelInputTable extends StatelessWidget {
  const _ElectrostaticParallelInputTable({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final ElectrostaticFieldState state;
  final bool dark;
  final void Function(String field, int point, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(140),
    };
    for (var index = 1; index <= ElectrostaticFieldState.pointCount; index++) {
      columnWidths[index] = const FixedColumnWidth(80);
    }
    return _electrostaticTable(
      minWidth: 780,
      columnWidths: columnWidths,
      dark: dark,
      headers: [
        _electrostaticHeader('', dark),
        for (var index = 0; index < ElectrostaticFieldState.pointCount; index++)
          _electrostaticHeaderMath('点', '${index + 1}', dark),
      ],
      rows: [
        [
          _electrostaticRowHeader(
            _electrostaticMixedLabel(
              prefix: '到 A 电极距离 ',
              formula: r'R_1\,/\,\mathrm{mm}',
              dark: dark,
              rowHeader: true,
            ),
            dark,
          ),
          for (
            var pointIndex = 0;
            pointIndex < ElectrostaticFieldState.pointCount;
            pointIndex++
          )
            _electrostaticInputCell(
              value: state.parallel.r1[pointIndex],
              label: '到 A 电极距离第 ${pointIndex + 1} 点',
              dark: dark,
              onChanged: (value) => onChanged('r1', pointIndex, value),
            ),
        ],
        [
          _electrostaticRowHeader(
            _electrostaticMixedLabel(
              prefix: '到 B 电极距离 ',
              formula: r'R_2\,/\,\mathrm{mm}',
              dark: dark,
              rowHeader: true,
            ),
            dark,
          ),
          for (
            var pointIndex = 0;
            pointIndex < ElectrostaticFieldState.pointCount;
            pointIndex++
          )
            _electrostaticInputCell(
              value: state.parallel.r2[pointIndex],
              label: '到 B 电极距离第 ${pointIndex + 1} 点',
              dark: dark,
              onChanged: (value) => onChanged('r2', pointIndex, value),
            ),
        ],
      ],
    );
  }
}

class _ElectrostaticResults extends StatelessWidget {
  const _ElectrostaticResults({
    required this.calculation,
    required this.dark,
    required this.onExport,
  });

  final ElectrostaticFieldCalculation calculation;
  final bool dark;
  final Future<void> Function(ElectrostaticChartKind kind) onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation.geometryError != null) ...[
          _electrostaticErrorMessage(calculation.geometryError!, dark),
          const SizedBox(height: 10),
        ],
        _electrostaticResultHeading('同轴圆柱面', dark),
        const SizedBox(height: 7),
        _buildCoaxialResults(),
        const SizedBox(height: 18),
        _electrostaticResultHeading('两平行导线', dark),
        const SizedBox(height: 7),
        _buildParallelResults(),
        const SizedBox(height: 18),
        _electrostaticResultHeading('报告图', dark),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 700
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: ElectrostaticFieldChartCard(
                    calculation: calculation,
                    kind: ElectrostaticChartKind.coaxial,
                    dark: dark,
                    onExport: onExport,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: ElectrostaticFieldChartCard(
                    calculation: calculation,
                    kind: ElectrostaticChartKind.parallel,
                    dark: dark,
                    onExport: onExport,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCoaxialResults() {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(100),
      1: const FixedColumnWidth(190),
      2: const FixedColumnWidth(240),
      3: const FixedColumnWidth(190),
    };
    return _electrostaticTable(
      minWidth: 720,
      columnWidths: columnWidths,
      dark: dark,
      headers: [
        _electrostaticHeaderMath(
          'U测 / V',
          r'U_{\mathrm{测}}\,/\,\mathrm{V}',
          dark,
        ),
        _electrostaticHeaderMath('平均半径', r'\bar r\,/\,\mathrm{mm}', dark),
        _electrostaticHeaderMath(
          '理论电势',
          r'U_{\mathrm{理}}\,/\,\mathrm{V}',
          dark,
        ),
        _electrostaticHeaderMath('相对误差', r'\varepsilon\,/\,\%', dark),
      ],
      rows: [
        for (final row in calculation.coaxial)
          [
            _electrostaticTextCell(row.potential, dark),
            _electrostaticResultText(
              ElectrostaticFieldCalculator.format(row.averageRadius),
              dark,
            ),
            _electrostaticResultText(
              ElectrostaticFieldCalculator.format(row.theoreticalPotential),
              dark,
            ),
            _electrostaticResultText(
              row.relativeError == null
                  ? '—'
                  : '${ElectrostaticFieldCalculator.format(row.relativeError)}%',
              dark,
            ),
          ],
      ],
    );
  }

  Widget _buildParallelResults() {
    final columnWidths = <int, TableColumnWidth>{0: const FixedColumnWidth(62)};
    for (var index = 1; index <= ElectrostaticFieldState.pointCount; index++) {
      columnWidths[index] = const FixedColumnWidth(82.25);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _electrostaticTable(
          minWidth: 720,
          columnWidths: columnWidths,
          dark: dark,
          headers: [
            _electrostaticHeader('点', dark),
            for (
              var index = 0;
              index < ElectrostaticFieldState.pointCount;
              index++
            )
              _electrostaticHeaderMath(
                '',
                'C_${index + 1}=R_{1,${index + 1}}/R_{2,${index + 1}}',
                dark,
              ),
          ],
          rows: [
            [
              _electrostaticTextCell('C', dark),
              for (final row in calculation.parallel)
                _electrostaticResultText(
                  ElectrostaticFieldCalculator.format(row.ratio),
                  dark,
                ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth <= 480
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _ElectrostaticSummaryLine(
                    label: '平均值',
                    formula: r'\bar C',
                    value: ElectrostaticFieldCalculator.format(
                      calculation.ratioAverage,
                    ),
                    dark: dark,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ElectrostaticSummaryLine(
                    label: '标准偏差',
                    formula: r'\sigma_C',
                    value: ElectrostaticFieldCalculator.format(
                      calculation.standardDeviation,
                    ),
                    dark: dark,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

Widget _electrostaticResultHeading(String title, bool dark) {
  return Text(
    title,
    style: TextStyle(
      color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
  );
}

Widget _electrostaticResultText(String value, bool dark) {
  return _electrostaticTableCell(
    Text(
      value.isEmpty ? '—' : value,
      textAlign: TextAlign.center,
      style: _electrostaticTableCellStyle(dark),
    ),
  );
}

class _ElectrostaticSummaryLine extends StatelessWidget {
  const _ElectrostaticSummaryLine({
    required this.label,
    required this.formula,
    required this.value,
    required this.dark,
  });

  final String label;
  final String formula;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFF9EACC3)
                        : const Color(0xFF527087),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(width: 5),
                _electrostaticInlineMath(
                  formula,
                  dark,
                  fontSize: 13,
                  weight: FontWeight.w600,
                  color: dark
                      ? const Color(0xFF9EACC3)
                      : const Color(0xFF527087),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _electrostaticErrorMessage(String message, bool dark) {
  return Text(
    message,
    style: const TextStyle(color: Color(0xFFB4533F), fontSize: 11, height: 1.5),
  );
}
