// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_franck_hertz_page.dart';

Widget _franckFormulaBlock(bool dark) {
  const formulas = [
    r'\Delta U_1=U_4-U_1,\quad\Delta U_2=U_5-U_2,\quad\Delta U_3=U_6-U_3',
    r'U_E=\frac{\Delta U}{3}',
    r'\bar{U}_E=\frac{1}{3}\sum_{i=1}^{3}U_{E,i}',
    r'u(\bar{U}_E)=\frac{s(U_E)}{\sqrt{3}}',
  ];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF14263A) : const Color(0xFFF1F7FB),
      border: const Border(
        left: BorderSide(color: Color(0xFF6DA8D0), width: 3),
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('计算公式', style: _franckFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _FranckFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _franckSection({
  required String title,
  required bool dark,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
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
            Text(title, style: _franckSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _FranckFormulaLine extends StatelessWidget {
  const _FranckFormulaLine({
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
            child: Text(number, style: _franckFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _franckMath(
              formula,
              dark,
              fontSize: 15,
              display: true,
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

class _FranckPeakInput extends StatelessWidget {
  const _FranckPeakInput({
    required this.state,
    required this.dark,
    required this.onPeakChanged,
    required this.onTheoryChanged,
  });

  final FranckHertzState state;
  final bool dark;
  final void Function(int index, String value) onPeakChanged;
  final ValueChanged<String> onTheoryChanged;

  @override
  Widget build(BuildContext context) {
    final peakFields = [
      for (var index = 0; index < state.peaks.length; index++)
        _FranckParameterSpec(
          prefix: '第 ${index + 1} 个特征电压',
          formula: 'U_${index + 1}\\,/\\,\\mathrm{V}',
          value: state.peaks[index],
          label: '第 ${index + 1} 个特征电压',
          onChanged: (value) => onPeakChanged(index, value),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FranckParameterGrid(dark: dark, fields: peakFields),
        const SizedBox(height: 10),
        _FranckParameterGrid(
          dark: dark,
          fields: [
            _FranckParameterSpec(
              prefix: '理论激发电压',
              formula: r'U_{E,0}\,/\,\mathrm{V}',
              value: state.theory,
              label: '理论激发电压',
              onChanged: onTheoryChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _FranckParameterSpec {
  const _FranckParameterSpec({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
}

class _FranckParameterGrid extends StatelessWidget {
  const _FranckParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_FranckParameterSpec> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth <= 420
            ? 1
            : constraints.maxWidth <= 720
            ? 2
            : 4;
        const gap = 10.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(
                width: width,
                child: _FranckLabeledInput(
                  prefix: field.prefix,
                  formula: field.formula,
                  value: field.value,
                  label: field.label,
                  dark: dark,
                  onChanged: field.onChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FranckLabeledInput extends StatelessWidget {
  const _FranckLabeledInput({
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
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 26),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3,
            children: [
              Text(prefix, style: _franckFieldLabelStyle(dark)),
              _franckMath(
                formula,
                dark,
                fontSize: 11,
                color: _franckFieldLabelColor(dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _FranckTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FranckPointTable extends StatelessWidget {
  const _FranckPointTable({
    required this.state,
    required this.dark,
    required this.onChanged,
    required this.onAddRow,
  });

  final FranckHertzState state;
  final bool dark;
  final void Function(int index, String field, String value) onChanged;
  final VoidCallback onAddRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.isFinite && constraints.maxWidth > 520
                ? constraints.maxWidth
                : 520.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: EcjtuColors.platformSurface(
                    dark,
                    (dark ? const Color(0xFF101D31) : Colors.white),
                  ),
                  border: Border.all(
                    color: EcjtuColors.platformBorder(
                      dark,
                      (dark
                          ? const Color(0xFF31546B)
                          : const Color(0xFFD5E4EF)),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                clipBehavior: Clip.antiAlias,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(86),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  border: _franckTableBorder(dark),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: _franckHeaderColor(dark),
                      ),
                      children: [
                        _franckHeaderCell(const Text('序号'), dark),
                        _franckHeaderCell(
                          _franckHeaderMath(
                            '第二栅极电压',
                            r'U_{G2K}\,/\,\mathrm{V}',
                            dark,
                          ),
                          dark,
                        ),
                        _franckHeaderCell(
                          _franckHeaderMath('板极电流', r'I_A', dark),
                          dark,
                        ),
                      ],
                    ),
                    for (var index = 0; index < state.rows.length; index++)
                      TableRow(
                        children: [
                          _franckTableCell(
                            Text(
                              '${index + 1}',
                              style: _franckRowLabelStyle(dark),
                            ),
                            dark,
                            labelCell: true,
                          ),
                          _franckTableCell(
                            _FranckTextField(
                              key: ValueKey<String>('franck-voltage-$index'),
                              value: state.rows[index].voltage,
                              label: '第二栅极电压第 ${index + 1} 行',
                              dark: dark,
                              compact: true,
                              onChanged: (value) =>
                                  onChanged(index, 'voltage', value),
                            ),
                            dark,
                          ),
                          _franckTableCell(
                            _FranckTextField(
                              key: ValueKey<String>('franck-current-$index'),
                              value: state.rows[index].current,
                              label: '板极电流第 ${index + 1} 行',
                              dark: dark,
                              compact: true,
                              onChanged: (value) =>
                                  onChanged(index, 'current', value),
                            ),
                            dark,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onAddRow,
          child: const Text('增加一行'),
          style: physicsSecondaryButtonStyle(context),
        ),
      ],
    );
  }
}

class _FranckResults extends StatelessWidget {
  const _FranckResults({
    required this.calculation,
    required this.dark,
    required this.onExportChart,
  });

  final FranckHertzCalculation calculation;
  final bool dark;
  final ValueChanged<FranckHertzChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final chart = franckHertzChartSpec(calculation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FranckResultCard(
          title: '逐差法计算',
          dark: dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FranckResultTable(
                headers: [
                  const Text('特征电压'),
                  _franckHeaderMath('电压', r'U\,/\,\mathrm{V}', dark),
                ],
                rows: [
                  for (var index = 0; index < calculation.peaks.length; index++)
                    [
                      _franckMath(r'U_' + (index + 1).toString(), dark),
                      _franckValue(
                        FranckHertzCalculator.format(calculation.peaks[index]),
                        dark,
                      ),
                    ],
                ],
                dark: dark,
                minWidth: 520,
              ),
              const SizedBox(height: 10),
              _FranckResultTable(
                headers: [
                  const Text('逐差项'),
                  _franckHeaderMath('电压差', r'\Delta U\,/\,\mathrm{V}', dark),
                  _franckHeaderMath('激发电压', r'U_E\,/\,\mathrm{V}', dark),
                ],
                rows: [
                  for (var index = 0; index < 3; index++)
                    [
                      _franckMath('U_${index + 4}-U_${index + 1}', dark),
                      _franckValue(
                        FranckHertzCalculator.format(
                          calculation.differences[index],
                        ),
                        dark,
                      ),
                      _franckValue(
                        FranckHertzCalculator.format(
                          calculation.excitations[index],
                        ),
                        dark,
                      ),
                    ],
                ],
                dark: dark,
                minWidth: 520,
              ),
              const SizedBox(height: 9),
              _FranckResultLine(
                prefix: '平均激发电压',
                formula: r'\bar{U}_E\,/\,\mathrm{V}',
                value: FranckHertzCalculator.format(
                  calculation.excitationAverage,
                ),
                dark: dark,
              ),
              _FranckResultLine(
                prefix: '标准差',
                formula: r's\,/\,\mathrm{V}',
                value: FranckHertzCalculator.formatDouble(
                  calculation.standardDeviation,
                ),
                dark: dark,
              ),
              _FranckResultLine(
                prefix: '标准误差',
                formula: r'u(\bar{U}_E)\,/\,\mathrm{V}',
                value: FranckHertzCalculator.formatDouble(
                  calculation.standardError,
                ),
                dark: dark,
              ),
              _FranckResultLine(
                prefix: '理论值',
                formula: r'U_{E,0}\,/\,\mathrm{V}',
                value: FranckHertzCalculator.format(calculation.theory),
                dark: dark,
              ),
              _FranckResultLine(
                prefix: '相对误差',
                formula: r'\varepsilon',
                value: _franckPercent(calculation.relativeError),
                dark: dark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('电流曲线', style: _franckChartGroupTitleStyle(dark)),
        const SizedBox(height: 10),
        FranckHertzChartCard(
          spec: chart,
          dark: dark,
          onExport: () => onExportChart(chart),
        ),
      ],
    );
  }
}

class _FranckResultCard extends StatelessWidget {
  const _FranckResultCard({
    required this.title,
    required this.dark,
    required this.child,
  });

  final String title;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
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
          Text(title, style: _franckResultTitleStyle(dark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FranckResultTable extends StatelessWidget {
  const _FranckResultTable({
    required this.headers,
    required this.rows,
    required this.dark,
    required this.minWidth,
  });

  final List<Widget> headers;
  final List<List<Widget>> rows;
  final bool dark;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: width,
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
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                for (var index = 0; index < headers.length; index++)
                  index: index == 0
                      ? const FixedColumnWidth(86)
                      : const FlexColumnWidth(1),
              },
              border: _franckTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _franckHeaderColor(dark)),
                  children: [
                    for (final header in headers)
                      _franckHeaderCell(header, dark),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      for (var index = 0; index < row.length; index++)
                        _franckTableCell(
                          row[index],
                          dark,
                          labelCell: index == 0,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FranckResultLine extends StatelessWidget {
  const _FranckResultLine({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.dark,
  });

  final String prefix;
  final String formula;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 720;
        final label = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(prefix, style: _franckResultLabelStyle(dark)),
            _franckMath(formula, dark, fontSize: 12),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _franckResultValueStyle(dark),
        );
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
              ),
            ),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 4), valueWidget],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: label),
                    const SizedBox(width: 12),
                    Flexible(child: valueWidget),
                  ],
                ),
        );
      },
    );
  }
}

class _FranckTextField extends StatefulWidget {
  const _FranckTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<_FranckTextField> createState() => _FranckTextFieldState();
}

class _FranckTextFieldState extends State<_FranckTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _FranckTextField oldWidget) {
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
    final height = widget.compact ? 30.0 : 32.0;
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
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
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 7,
              vertical: widget.compact ? 4 : 5,
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

Widget _franckHeaderMath(String text, String formula, bool dark) {
  return _franckMixedLabel(
    prefix: text,
    formula: formula,
    dark: dark,
    textStyle: _franckHeaderTextStyle(dark),
  );
}

Widget _franckMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  TextStyle? textStyle,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(prefix, style: textStyle ?? _franckCellTextStyle(dark)),
      _franckMath(
        formula,
        dark,
        fontSize: textStyle?.fontSize ?? 12,
        weight: textStyle?.fontWeight ?? FontWeight.w400,
        color: textStyle?.color,
      ),
    ],
  );
}

Widget _franckTableCell(Widget child, bool dark, {bool labelCell = false}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: Alignment.center,
    color: labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: labelCell
          ? _franckRowLabelStyle(dark)
          : _franckCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _franckHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: Alignment.center,
    color: _franckHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _franckHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _franckValue(String value, bool dark) {
  return Text(
    value,
    textAlign: TextAlign.center,
    style: _franckCellTextStyle(dark),
  );
}

Widget _franckMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight? weight,
  Color? color,
  bool display = false,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(
        color:
            color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
        fontSize: fontSize,
        fontWeight: weight,
        height: display ? 1.25 : 1.3,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

String _franckPercent(double? value) {
  if (value == null || !value.isFinite) return '—';
  return '${FranckHertzCalculator.formatDouble(value * 100, digits: 4)}%';
}

TableBorder _franckTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _franckHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _franckSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _franckFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _franckFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _franckResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _franckFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

Color _franckFieldLabelColor(bool dark) => EcjtuColors.platformMuted(
  dark,
  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
);

TextStyle _franckHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _franckCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _franckRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _franckResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _franckResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _franckChartGroupTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
