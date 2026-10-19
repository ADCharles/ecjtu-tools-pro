// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_voltage_current_page.dart';

Widget _voltageCurrentSection({
  required bool dark,
  required String title,
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
      children: [
        Text(title, style: _voltageCurrentSectionTitleStyle(dark)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _voltageCurrentFormulaBlock(bool dark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF14263A) : const Color(0xFFF1F7FB),
      border: Border(
        left: BorderSide(color: const Color(0xFF6DA8D0), width: 3),
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('计算公式', style: _voltageCurrentFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _VoltageCurrentFormulaLine(
          number: '1.',
          formula: r'R=\frac{U}{I}',
          dark: dark,
        ),
        _VoltageCurrentFormulaLine(
          number: '2.',
          formula: r'R_{\mathrm{in}}^{\prime}=\frac{U}{I}-R_A',
          dark: dark,
        ),
        _VoltageCurrentFormulaLine(
          number: '3.',
          formula: r'R_{\mathrm{out}}^{\prime}=\frac{U}{I-U/R_V}',
          dark: dark,
        ),
        _VoltageCurrentFormulaLine(
          number: '4.',
          formula:
              r'\frac{\Delta R}{R}=\left(\frac{\Delta U}{U_{\min}}+\frac{\Delta I}{I_{\min}}\right)\times100\%',
          dark: dark,
        ),
      ],
    ),
  );
}

class _VoltageCurrentFormulaLine extends StatelessWidget {
  const _VoltageCurrentFormulaLine({
    required this.number,
    required this.formula,
    required this.dark,
  });

  final String number;
  final String formula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                number,
                style: _voltageCurrentFormulaNumberStyle(dark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _voltageCurrentMath(
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
      ),
    );
  }
}

class _VoltageCurrentLabeledInput extends StatelessWidget {
  const _VoltageCurrentLabeledInput({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _voltageCurrentMixedLabel(prefix: prefix, formula: formula, dark: dark),
        const SizedBox(height: 5),
        _VoltageCurrentTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VoltageCurrentTextField extends StatefulWidget {
  const _VoltageCurrentTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.table = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final bool table;

  @override
  State<_VoltageCurrentTextField> createState() =>
      _VoltageCurrentTextFieldState();
}

class _VoltageCurrentTextFieldState extends State<_VoltageCurrentTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _VoltageCurrentTextField oldWidget) {
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
    final border = widget.dark
        ? const Color(0xFF426B83)
        : const Color(0xFFB9CFDD);
    return Semantics(
      textField: true,
      label: widget.label,
      child: SizedBox(
        width: widget.table ? 76 : double.infinity,
        height: widget.table ? 29 : 34,
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: widget.dark
                ? const Color(0xFFE1EDFF)
                : const Color(0xFF223549),
            fontSize: 12,
            height: 1.15,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.table ? 5 : 8,
              vertical: widget.table ? 4 : 6,
            ),
            border: _voltageCurrentInputBorder(border),
            enabledBorder: _voltageCurrentInputBorder(border),
            focusedBorder: _voltageCurrentInputBorder(
              widget.dark ? const Color(0xFF8FD2FF) : const Color(0xFF287AA8),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}

class _VoltageCurrentBlockInput extends StatelessWidget {
  const _VoltageCurrentBlockInput({
    required this.block,
    required this.blockIndex,
    required this.dark,
    required this.onParameterChanged,
    required this.onPointChanged,
  });

  final VoltageCurrentBlockInput block;
  final int blockIndex;
  final bool dark;
  final void Function(String field, String value) onParameterChanged;
  final void Function(int point, String field, String value) onPointChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaQuery.sizeOf(context).width <= 700 ? 1 : 3;
            final gap = 10.0;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _VoltageCurrentLabeledInput(
                    prefix: '电压表量程 ',
                    formula: r'U_{max}\,/\,\mathrm{V}',
                    value: block.voltageRange,
                    label: '${block.resistance} Ω ${block.connection}法电压表量程',
                    dark: dark,
                    onChanged: (value) =>
                        onParameterChanged('voltageRange', value),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _VoltageCurrentLabeledInput(
                    prefix: '电流表量程 ',
                    formula: r'I_{max}\,/\,\mathrm{mA}',
                    value: block.currentRange,
                    label: '${block.resistance} Ω ${block.connection}法电流表量程',
                    dark: dark,
                    onChanged: (value) =>
                        onParameterChanged('currentRange', value),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _VoltageCurrentLabeledInput(
                    prefix: block.connection == '内接' ? '电流表内阻 ' : '电压表内阻 ',
                    formula: block.connection == '内接'
                        ? r'R_A\,/\,\Omega'
                        : r'R_V\,/\,\Omega',
                    value: block.meterResistance,
                    label: '${block.resistance} Ω ${block.connection}法仪表内阻',
                    dark: dark,
                    onChanged: (value) =>
                        onParameterChanged('meterResistance', value),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _voltageCurrentTableBox(
          dark: dark,
          child: SizedBox(
            width: 570,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(125),
                1: FixedColumnWidth(111.25),
                2: FixedColumnWidth(111.25),
                3: FixedColumnWidth(111.25),
                4: FixedColumnWidth(111.25),
              },
              border: _voltageCurrentTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF14263A)
                        : const Color(0xFFEEF6FA),
                  ),
                  children: [
                    _voltageCurrentHeaderCell('数据项', dark, alignLeft: true),
                    for (
                      var index = 0;
                      index < VoltageCurrentBlockInput.pointCount;
                      index++
                    )
                      _voltageCurrentHeaderCell('第 ${index + 1} 组', dark),
                  ],
                ),
                TableRow(
                  children: [
                    _voltageCurrentRowHeaderMathCell(
                      '电压 ',
                      r'U\,/\,\mathrm{V}',
                      dark,
                    ),
                    for (var index = 0; index < block.points.length; index++)
                      _voltageCurrentInputCell(
                        key: 'voltage-current-$blockIndex-$index-voltage',
                        value: block.points[index].voltage,
                        label:
                            '${block.resistance} Ω ${block.connection}法第 ${index + 1} 组电压',
                        dark: dark,
                        onChanged: (value) =>
                            onPointChanged(index, 'voltage', value),
                      ),
                  ],
                ),
                TableRow(
                  children: [
                    _voltageCurrentRowHeaderMathCell(
                      '电流 ',
                      r'I\,/\,\mathrm{mA}',
                      dark,
                    ),
                    for (var index = 0; index < block.points.length; index++)
                      _voltageCurrentInputCell(
                        key: 'voltage-current-$blockIndex-$index-current',
                        value: block.points[index].current,
                        label:
                            '${block.resistance} Ω ${block.connection}法第 ${index + 1} 组电流',
                        dark: dark,
                        onChanged: (value) =>
                            onPointChanged(index, 'current', value),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VoltageCurrentDiodeInput extends StatelessWidget {
  const _VoltageCurrentDiodeInput({
    required this.points,
    required this.dark,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<VoltageCurrentPointInput> points;
  final bool dark;
  final void Function(int index, String field, String value) onChanged;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _voltageCurrentTableBox(
          dark: dark,
          child: SizedBox(
            width: (125 + points.length * 80) < 570
                ? 570
                : 125 + points.length * 80,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(125),
                for (var index = 0; index < points.length; index++)
                  index + 1: const FixedColumnWidth(80),
              },
              border: _voltageCurrentTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF14263A)
                        : const Color(0xFFEEF6FA),
                  ),
                  children: [
                    _voltageCurrentHeaderCell('数据项', dark, alignLeft: true),
                    for (var index = 0; index < points.length; index++)
                      _voltageCurrentHeaderCell('第 ${index + 1} 组', dark),
                  ],
                ),
                TableRow(
                  children: [
                    _voltageCurrentRowHeaderMathCell(
                      '电压 ',
                      r'U\,/\,\mathrm{V}',
                      dark,
                    ),
                    for (var index = 0; index < points.length; index++)
                      _voltageCurrentInputCell(
                        key: 'voltage-current-diode-$index-voltage',
                        value: points[index].voltage,
                        label: '二极管第 ${index + 1} 组电压',
                        dark: dark,
                        onChanged: (value) =>
                            onChanged(index, 'voltage', value),
                      ),
                  ],
                ),
                TableRow(
                  children: [
                    _voltageCurrentRowHeaderMathCell(
                      '电流 ',
                      r'I\,/\,\mathrm{mA}',
                      dark,
                    ),
                    for (var index = 0; index < points.length; index++)
                      _voltageCurrentInputCell(
                        key: 'voltage-current-diode-$index-current',
                        value: points[index].current,
                        label: '二极管第 ${index + 1} 组电流',
                        dark: dark,
                        onChanged: (value) =>
                            onChanged(index, 'current', value),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onAdd,
              style: physicsSecondaryButtonStyle(context),
              child: const Text('增加一组'),
            ),
            OutlinedButton(
              onPressed: onRemove,
              style: physicsSecondaryButtonStyle(context),
              child: const Text('删除一组'),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _voltageCurrentLinearResults({
  required VoltageCurrentCalculation calculation,
  required bool dark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('线性电阻计算结果', style: _voltageCurrentResultHeadingStyle(dark)),
      const SizedBox(height: 9),
      for (var index = 0; index < calculation.blocks.length; index++) ...[
        _voltageCurrentLinearResultCard(calculation.blocks[index], dark),
        if (index < calculation.blocks.length - 1) const SizedBox(height: 12),
      ],
    ],
  );
}

Widget _voltageCurrentLinearResultCard(
  VoltageCurrentBlockResult result,
  bool dark,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${result.resistance} Ω 电阻 · 电流表${result.connection}法',
          style: _voltageCurrentResultTitleStyle(dark),
        ),
        const SizedBox(height: 9),
        _voltageCurrentResultTable(result, dark),
        const SizedBox(height: 9),
        _voltageCurrentSummary(result, dark),
      ],
    ),
  );
}

Widget _voltageCurrentResultTable(VoltageCurrentBlockResult result, bool dark) {
  return _voltageCurrentTableBox(
    dark: dark,
    child: SizedBox(
      width: 570,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(125),
          1: FixedColumnWidth(89),
          2: FixedColumnWidth(89),
          3: FixedColumnWidth(89),
          4: FixedColumnWidth(89),
          5: FixedColumnWidth(89),
        },
        border: _voltageCurrentTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA),
            ),
            children: [
              _voltageCurrentHeaderCell('数据项', dark, alignLeft: true),
              for (
                var index = 0;
                index < VoltageCurrentBlockInput.pointCount;
                index++
              )
                _voltageCurrentHeaderCell('第 ${index + 1} 组', dark),
              _voltageCurrentHeaderCell('平均值', dark),
            ],
          ),
          TableRow(
            children: [
              _voltageCurrentRowHeaderMathCell(
                '测得电阻 ',
                r'R_i\,/\,\Omega',
                dark,
              ),
              for (final point in result.points)
                _voltageCurrentResultCell(
                  VoltageCurrentCalculator.format(point.rawResistance),
                  dark,
                ),
              _voltageCurrentResultCell(
                VoltageCurrentCalculator.format(result.rawAverage),
                dark,
              ),
            ],
          ),
          TableRow(
            children: [
              _voltageCurrentRowHeaderMathCell(
                '修正后电阻 ',
                r"R_i^{\prime}\,/\,\Omega",
                dark,
              ),
              for (final point in result.points)
                _voltageCurrentResultCell(
                  VoltageCurrentCalculator.format(point.correctedResistance),
                  dark,
                ),
              _voltageCurrentResultCell(
                VoltageCurrentCalculator.format(result.correctedAverage),
                dark,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _voltageCurrentSummary(VoltageCurrentBlockResult result, bool dark) {
  final items = [
    (
      '测得电阻平均值',
      r'\bar R\,/\,\Omega',
      VoltageCurrentCalculator.format(result.rawAverage),
    ),
    (
      '修正后电阻平均值',
      r"\bar R^{\prime}\,/\,\Omega",
      VoltageCurrentCalculator.format(result.correctedAverage),
    ),
    (
      '电压表仪器误差',
      r'\Delta U\,/\,\mathrm{V}',
      VoltageCurrentCalculator.format(result.deltaVoltage),
    ),
    (
      '电流表仪器误差',
      r'\Delta I\,/\,\mathrm{mA}',
      VoltageCurrentCalculator.format(result.deltaCurrentMilliAmp),
    ),
    (
      '仪器相对误差',
      r'\frac{\Delta R}{R}',
      result.relativeInstrumentError == null
          ? '—'
          : '${VoltageCurrentCalculator.format(result.relativeInstrumentError)}%',
    ),
    (
      '修正相对差',
      r'\left|\frac{\Delta R}{R}\right|',
      VoltageCurrentCalculator.format(result.correctionRatio),
    ),
    (
      '修正前后差值',
      r'\Delta R\,/\,\Omega',
      VoltageCurrentCalculator.format(result.correctionDifference),
    ),
  ];
  return LayoutBuilder(
    builder: (context, constraints) {
      final columns = MediaQuery.sizeOf(context).width <= 480 ? 1 : 2;
      final gap = 8.0;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: _voltageCurrentSummaryLine(
                label: item.$1,
                formula: item.$2,
                value: item.$3,
                dark: dark,
                summary: true,
              ),
            ),
        ],
      );
    },
  );
}

Widget _voltageCurrentSummaryLine({
  required String label,
  required String formula,
  required String value,
  required bool dark,
  bool summary = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: _voltageCurrentMixedLabel(
          prefix: label,
          formula: formula,
          dark: dark,
          fontSize: 12,
          summary: summary,
        ),
      ),
      const SizedBox(width: 8),
      Text(value, style: _voltageCurrentSummaryValueStyle(dark)),
    ],
  );
}

Widget _voltageCurrentDiodeResults(
  List<VoltageCurrentDiodeResult> points,
  bool dark,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('半导体二极管正向伏安数据', style: _voltageCurrentResultHeadingStyle(dark)),
      const SizedBox(height: 9),
      _voltageCurrentTableBox(
        dark: dark,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FixedColumnWidth(150),
            2: FixedColumnWidth(150),
          },
          border: _voltageCurrentTableBorder(dark),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA),
              ),
              children: [
                _voltageCurrentHeaderCell('组数', dark),
                _voltageCurrentHeaderMathCell('电压 ', r'U\,/\,\mathrm{V}', dark),
                _voltageCurrentHeaderMathCell(
                  '电流 ',
                  r'I\,/\,\mathrm{mA}',
                  dark,
                ),
              ],
            ),
            for (final point in points)
              TableRow(
                children: [
                  _voltageCurrentResultCell('${point.index + 1}', dark),
                  _voltageCurrentResultCell(
                    VoltageCurrentCalculator.format(point.voltage),
                    dark,
                  ),
                  _voltageCurrentResultCell(
                    VoltageCurrentCalculator.format(point.currentMilliAmp),
                    dark,
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

Widget _voltageCurrentCharts({
  required VoltageCurrentCalculation calculation,
  required bool dark,
  required VoltageCurrentChartExporter onExport,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('伏安特性图', style: _voltageCurrentResultHeadingStyle(dark)),
      const SizedBox(height: 9),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = MediaQuery.sizeOf(context).width <= 700 ? 1 : 2;
          final gap = 12.0;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / columns;
          final cards = <Widget>[];
          for (var index = 0; index < calculation.blocks.length; index++) {
            final block = calculation.blocks[index];
            final points = voltageCurrentLinearChartPoints(block);
            final title = '${block.resistance} Ω 电阻 · 电流表${block.connection}法';
            cards.add(
              SizedBox(
                width: width,
                child: VoltageCurrentChartCard(
                  title: title,
                  points: points,
                  color: voltageCurrentChartColors[index],
                  dark: dark,
                  onExport: () => onExport(
                    title,
                    points,
                    voltageCurrentChartColorHexes[index],
                  ),
                ),
              ),
            );
          }
          final diodePoints = voltageCurrentDiodeChartPoints(calculation.diode);
          const diodeTitle = '半导体二极管正向伏安特性';
          cards.add(
            SizedBox(
              width: width,
              child: VoltageCurrentChartCard(
                title: diodeTitle,
                points: diodePoints,
                color: voltageCurrentChartColors[4],
                dark: dark,
                onExport: () => onExport(
                  diodeTitle,
                  diodePoints,
                  voltageCurrentChartColorHexes[4],
                ),
              ),
            ),
          );
          return Wrap(spacing: gap, runSpacing: gap, children: cards);
        },
      ),
    ],
  );
}

Widget _voltageCurrentMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight? weight,
  Color? color,
  MathStyle mathStyle = MathStyle.text,
  bool scrollable = true,
}) {
  final math = Math.tex(
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
  );
  if (!scrollable) return math;
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: math);
}

Widget _voltageCurrentMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  double fontSize = 11,
  FontWeight? weight,
  bool rowHeader = false,
  bool header = false,
  bool summary = false,
}) {
  final labelStyle = header
      ? _voltageCurrentHeaderTextStyle(dark)
      : rowHeader
      ? _voltageCurrentRowHeaderTextStyle(dark)
      : summary
      ? _voltageCurrentSummaryLabelStyle(dark)
      : _voltageCurrentFieldLabelStyle(dark);
  final color = header
      ? (dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487))
      : rowHeader
      ? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF3D647D))
      : summary
      ? (dark ? const Color(0xFF9EACC3) : const Color(0xFF527087))
      : (EcjtuColors.platformMuted(
          dark,
          (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
        ));
  final mathSize = header || rowHeader || summary ? 12.0 : fontSize + 1;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(prefix, style: labelStyle),
      const SizedBox(width: 3),
      _voltageCurrentMath(
        formula,
        dark,
        fontSize: mathSize,
        weight: weight,
        color: color,
        scrollable: false,
      ),
    ],
  );
}

Widget _voltageCurrentTableBox({required bool dark, required Widget child}) {
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
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
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: child,
    ),
  );
}

TableCell _voltageCurrentHeaderCell(
  String text,
  bool dark, {
  bool alignLeft = false,
}) {
  return _voltageCurrentTableCell(
    Text(text, style: _voltageCurrentHeaderTextStyle(dark)),
    alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
  );
}

TableCell _voltageCurrentHeaderMathCell(
  String prefix,
  String formula,
  bool dark,
) {
  return _voltageCurrentTableCell(
    _voltageCurrentMixedLabel(
      prefix: prefix,
      formula: formula,
      dark: dark,
      header: true,
      weight: FontWeight.w700,
    ),
  );
}

TableCell _voltageCurrentRowHeaderMathCell(
  String prefix,
  String formula,
  bool dark,
) {
  return _voltageCurrentTableCell(
    _voltageCurrentMixedLabel(
      prefix: prefix,
      formula: formula,
      dark: dark,
      fontSize: 12,
      weight: FontWeight.w700,
      rowHeader: true,
    ),
    alignment: Alignment.centerLeft,
    backgroundColor: dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD),
  );
}

TableCell _voltageCurrentInputCell({
  required String key,
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
}) {
  return _voltageCurrentTableCell(
    _VoltageCurrentTextField(
      key: ValueKey<String>(key),
      value: value,
      label: label,
      dark: dark,
      onChanged: onChanged,
      table: true,
    ),
  );
}

TableCell _voltageCurrentResultCell(String value, bool dark) {
  return _voltageCurrentTableCell(
    Text(value, style: _voltageCurrentTableTextStyle(dark)),
  );
}

TableCell _voltageCurrentTableCell(
  Widget child, {
  Alignment alignment = Alignment.center,
  Color? backgroundColor,
}) {
  return TableCell(
    verticalAlignment: TableCellVerticalAlignment.middle,
    child: Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      color: backgroundColor,
      child: child,
    ),
  );
}

TextStyle _voltageCurrentSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _voltageCurrentFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _voltageCurrentFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _voltageCurrentResultHeadingStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _voltageCurrentResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _voltageCurrentFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _voltageCurrentRowHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF3D647D),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _voltageCurrentSummaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _voltageCurrentHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _voltageCurrentTableTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.2,
);

TextStyle _voltageCurrentSummaryValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.2,
);

TableBorder _voltageCurrentTableBorder(bool dark) => TableBorder(
  top: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
  bottom: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
  left: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
  right: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
  horizontalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
  verticalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    width: .7,
  ),
);

OutlineInputBorder _voltageCurrentInputBorder(Color color) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color),
    );
